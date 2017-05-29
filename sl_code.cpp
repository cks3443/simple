#include "sl.h"
#include "sl_prot.h"

CodeSet code;
int startPc;
int Pc=-1;
int baseReg;
int spReg;
int maxLine;

double returnValue;
bool break_Flg, return_Flg, exit_Flg;
Mymemory Dmem;
Mymemory Gmem;
vector<string> strLITERAL;
vector<double> nbrLITERAL;
bool syntaxChk_mode=false;
extern vector<SymTbl> Gtable;

extern vector<int> intercode;
extern vector<int> Ind;

int code_ptr;

Mystack stk;

void syntaxChk()
{
bool b_Flg=false;
syntaxChk_mode=true;

for (Pc=1; Pc < (int)Ind.size() - 1; Pc++)
        {
        code=firstCode(Pc);
        switch (code.kind)
                {
                case Func: case Option: case Var:
                        break;
                case Else: case End: case Exit:
                        code=nextCode();
                        chk_EofLine();
                        break;
                case If: case Elif: case While:
                        code=nextCode();
                        (void)get_expression(0, EofLine);
                        break;
                case For:
                        code=nextCode();
                        (void)get_memAdrs(code);
                        (void)get_expression('=', 0);
                        (void)get_expression(To, 0);
                        if (code.kind == Step) (void)get_expression(Step, 0);
                        chk_EofLine();
                        break;
                case Fcall:
                        fncCall_syntax(code.symNbr);
                        chk_EofLine();
                        (void)stk.pop();
                        break;
                case Print: case Println:
                        sysFncExec_syntax(code.kind);
                        break;
                case Gvar: case Lvar: case Dvar:
                        (void)get_memAdrs(code);
                        if (code.kind == Assign) (void)get_expression('=', EofLine);
						else if (code.kind == SumAssign) (void)get_expression(SumAssign, EofLine);
						else if (code.kind == MinusAssign) (void)get_expression(MinusAssign, EofLine);
						else if (code.kind == MultiAssign) (void)get_expression(MultiAssign, EofLine);
						else if (code.kind == DiviAssign) (void)get_expression(DiviAssign, EofLine);
                        break;
                case Return:
                        code=nextCode();
                        if (code.kind != '?' && code.kind != EofLine) (void)get_expression();
                        if (code.kind == '?') (void)get_expression('?', 0);
                        chk_EofLine();
                        break;
                case Break:
                        code=nextCode();
                        if (code.kind == '?') (void)get_expression('?', 0);
                        chk_EofLine();
                        break;
                case EofLine:
                        break;
                default:
                        err_exit("This is wrong: ", kind_to_s(code.kind));
                }
        }
syntaxChk_mode=false;
}

void set_startPc(int n)
{
startPc=n;
}

int Get_startPc()
{
    return startPc;
}

void execute()
{
baseReg=0;
spReg=Dmem.size();

int BigFram = 0, SizGTbl = 0;
SizGTbl = Gtable.size();

for (int i=0; i < SizGTbl; i++)
        {
        int Fram = Gtable[i].frame;
        if (BigFram < Fram) BigFram = Fram;
        }

Dmem.resize(spReg + BigFram + 1);

break_Flg=return_Flg=exit_Flg=false;

Pc=startPc;
maxLine=intercode.size()-1;
while (Pc <= maxLine && !exit_Flg)
        {
        statement();
        }
Pc=-1;
}

void statement()
{
CodeSet save;
int top_line, end_line, varAdrs;
double wkVal, endDt, stepDt;

if (Pc > maxLine || exit_Flg) return;

code=save=firstCode(Pc);

top_line=Pc;
end_line=code.jmpAdrs;
if (code.kind == If) end_line=endline_of_If(Pc);

switch (code.kind)
        {
        case If:
                if (get_expression(If, 0))
                        {
                        ++Pc;
                        block();
                        Pc=end_line+1;
                        return;
                        }
                Pc=save.jmpAdrs;
                while (lookCode(Pc) == Elif)
                        {
                        save = firstCode(Pc);
                        code=nextCode();
                        if (get_expression())
                                {
                                ++Pc;
                                block();
                                Pc=end_line+1;
                                return;
                                }
                        Pc=save.jmpAdrs;
                        }
                if (lookCode(Pc) == Else)
                        {
                        ++Pc;
                        block();
                        Pc=end_line+1;
                        return;
                        }
                ++Pc;
                break;
        case While:
                for (;;)
                        {
                        if (!get_expression(While, 0)) break;
                        ++Pc;
                        block();
                        if (break_Flg || return_Flg || exit_Flg)
                                {
                                break_Flg=false;
                                break;
                                }
                        Pc=top_line;
                        code=firstCode(Pc);
                        }
                Pc=end_line+1;
                break;
        case For:
                save=nextCode();
                varAdrs=get_memAdrs(save);
                expression('=',0);
                set_dtTyp(save, DBL_T);
                Dmem.set(varAdrs, stk.pop());
                endDt=get_expression(To, 0);

                endDt = endDt - 1;

                if (code.kind == Step) stepDt=get_expression(Step, 0);
                else stepDt=1.0;

                for (;; Pc=top_line)
                        {
                        if (stepDt >= 0)
                                {
                                if (Dmem.get(varAdrs) > endDt) break;
                                }
                        else
                                {
                                if (Dmem.get(varAdrs) < endDt) break;
                                }
                        ++Pc;
                        block();
                        if (break_Flg || return_Flg || exit_Flg)
                                {
                                break_Flg=false;
                                break;
                                }
                        Dmem.add(varAdrs, stepDt);
                        }
                Pc=end_line + 1;
                break;
        case Fcall:
                fncCall(code.symNbr);
                (void)stk.pop();
                ++Pc;
                break;
        case Func:
                Pc=end_line+1;
                break;
        case Print: case Println:
                sysFncExec(code.kind);
                ++Pc;
                break;
        case Gvar: case Lvar:
                varAdrs=get_memAdrs(code);
                expression('=', 0);
                set_dtTyp(save, DBL_T);
                Dmem.set(varAdrs, stk.pop());
                ++Pc;
                break;
        
        case Dvar:
                varAdrs=get_memAdrs(code);
                expression('=', 0);
                set_dtTyp(save, DBL_T);
                Gmem.set(varAdrs, stk.pop());
                ++Pc;
                break;

        case Return:
                wkVal=returnValue;
                code=nextCode();
                if (code.kind != '?' && code.kind != EofLine) wkVal=get_expression();
                post_if_set(return_Flg);
                if (return_Flg) returnValue=wkVal;
                if (!return_Flg) ++Pc;
                break;
        case Break:
                code=nextCode();
                post_if_set(break_Flg);
                if (!break_Flg) ++Pc;
                break;
        case Exit:
                code=nextCode();
                exit_Flg=true;
                break;
        case Option: case Var: case EofLine:
                ++Pc;
                break;
        default:
                err_exit("This is wrong: ", kind_to_s(code.kind));
        }
}

void block()
{
TknKind k;
while (!break_Flg && ! return_Flg && ! exit_Flg)
        {
        k=lookCode(Pc);
        if (k == Elif || k == Else || k==End) break;
        statement();
        }
}

double get_expression(int kind1, int kind2)
{
expression(kind1, kind2);
return stk.pop();
}

void expression(int kind1, int kind2)
{
if (kind1 != 0) code = chk_nextCode(code, kind1);
expression();
if (kind2 !=0) code=chk_nextCode(code, kind2);
}

void expression()
{
	term(1);
}

void term(int n)
{
	TknKind op;
	if (n == 7)
	{
		factor();
		return;
	}
	term(n+1);
	while (n == opOrder(code.kind))
	{
		op = code.kind;
		code=nextCode();
		term(n+1);
		if (syntaxChk_mode)
		{
			stk.pop();
			stk.pop();
			stk.push(1.);
		}
		else binaryExpr(op);
	}
}

void factor()
{
    TknKind kd=code.kind;

    if (syntaxChk_mode) {
        
        switch (kd) {
        
		case Not: case Minus: case Plus: case IntDivi: case Mod:
            code=nextCode();
            factor();
            stk.pop();
            stk.push(1.0);
            break;
            
        case Lparen:
            expression('(', ')');
            break;
            
        case IntNum: case DblNum:
            stk.push(1.0);
            code=nextCode();
            break;
               
       case Gvar: case Lvar: case Dvar:
            (void)get_memAdrs(code);
            stk.push(1.0);
            break;
            
        case Toint: case Input:
            sysFncExec_syntax(kd);
            break;
        
        case EXP: case LOG: case PID:
            sysFncExec_syntax(kd);
            break;

        case Fcall:
            fncCall_syntax(code.symNbr);
            break;
        case EofLine:
            err_exit("This equation is wrong.");
        default:
            err_exit("Equation is wrong: ", kind_to_s(code));
        }
    return;
    }

    switch (kd) {
    
    case Not: case Minus: case Plus:
    
        code=nextCode();
        factor();
        if (kd==Not) stk.push(!stk.pop());
        if (kd==Minus) stk.push(-stk.pop());
        break;
        
    case Lparen:
        expression('(', ')');
        break;
    case IntNum: case DblNum:
        stk.push(code.dblVal);
        code=nextCode();
        break;

    case Gvar: case Lvar:
        chk_dtTyp(code);
        stk.push(Dmem.get(get_memAdrs(code)));
        break;

    case Dvar:
        chk_dtTyp(code);
        stk.push(Gmem.get(get_memAdrs(code)));
        break;

    case Toint: case Input:
        sysFncExec(kd);
        break;
    
    case EXP: case LOG: case PID:
        sysFncExec(kd);
        break;
    
    case Fcall:
        fncCall(code.symNbr);
        break;
    }
}

int opOrder(TknKind kd)
{
switch (kd)
        {
        case Multi: case Divi: case Mod: case IntDivi:
                return 6;
        case Plus: case Minus:
                return 5;
        case Less: case LessEq: case Great: case GreatEq:
                return 4;
        case Equal: case NotEq:
                return 3;
        case And:
                return 2;
        case Or:
                return 1;
        default:
                return 0;
        }
}

void binaryExpr(TknKind op)
{
  double d = 0, d2 = stk.pop(), d1 = stk.pop();

  if ((op==Divi || op==Mod || op==IntDivi) && d2==0)
    err_exit("This is divided with Zero.");

  switch (op) {
  case Plus:    d = d1 + d2;  break;
  case Minus:   d = d1 - d2;  break;
  case Multi:   d = d1 * d2;  break;
  case Divi:    d = d1 / d2;  break;
  case Mod:     d = (int)d1 % (int)d2; break;
  case IntDivi: d = (int)d1 / (int)d2; break;
  case Less:    d = d1 <  d2; break;
  case LessEq:  d = d1 <= d2; break;
  case Great:   d = d1 >  d2; break;
  case GreatEq: d = d1 >= d2; break;
  case Equal:   d = d1 == d2; break;
  case NotEq:   d = d1 != d2; break;
  case And:     d = d1 && d2; break;
  case Or:      d = d1 || d2; break;
  }
  stk.push(d);
}

void post_if_set(bool& flg)
{
if (code.kind == EofLine)
        {
        flg=true;
        return;
        }
if (get_expression('?', 0)) flg=true;
}

void fncCall_syntax(int fncNbr)
{
int argCt=0;

code=nextCode();
code=chk_nextCode(code, '(');
if (code.kind != ')')
        {
        for (;; code=nextCode())
                {
                (void)get_expression();
                ++argCt;
                if (code.kind != ',') break;
                }
        }
code = chk_nextCode(code, ')');
if (argCt != Gtable[fncNbr].args)
        {
        err_exit(Gtable[fncNbr].name, "The nbr of para is wrong in this function");
        }
stk.push(1.0);
}

void fncCall(int fncNbr)
{
int n, argCt=0;
vector<double> vc;

nextCode();
code=nextCode();

if (code.kind != ')')
        {
        for (;; code=nextCode())
                {
                expression();
                ++argCt;
                if (code.kind != ',') break;
                }
        }
code=nextCode();
for (n=0; n<argCt; n++) vc.push_back(stk.pop());
for (n=0; n<argCt; n++) stk.push(vc[n]);
fncExec(fncNbr);
}

void fncExec(int fncNbr)
{
int save_Pc=Pc;
int save_baseReg=baseReg;
int save_spReg=spReg;
int save_code_ptr = code_ptr;
CodeSet save_code=code;

Pc=Gtable[fncNbr].adrs;

returnValue=1.0;
code=firstCode(Pc);
nextCode();
code=nextCode();

if (code.kind != ')')
        {
        for (;; code=nextCode())
                {
                set_dtTyp(code, DBL_T);
                Dmem.set(get_memAdrs(code), stk.pop());
                if (code.kind != ',') break;
                }
        }
code = nextCode();
++Pc;
block();
return_Flg=false;

stk.push(returnValue);
Pc = save_Pc;
baseReg = save_baseReg;
spReg   = save_spReg;
code_ptr= save_code_ptr;
code    = save_code;
}

void sysFncExec_syntax(TknKind kd)
{
switch (kd)
        {
        case Toint:
                code=nextCode();
                (void)get_expression('(',')');
                stk.push(1.0);
                break;
        
        case EXP: case LOG:
                code=nextCode();
                (void)get_expression('(',')');
                stk.push(1.0);
                break;
        
        case PID:
                code=nextCode();
                stk.push(1.0);
                break;
        
        
        case Input:
                code=nextCode();
                code=chk_nextCode(code, '(');
                code=chk_nextCode(code, ')');
                stk.push(1.0);
                break;
        case Print: case Println:
                do 
                {
                code=nextCode();
                if (code.kind == String) code=nextCode();
                else (void)get_expression();
                } while (code.kind == ',');
                chk_EofLine();
                break;
        }
}

void sysFncExec(TknKind kd)
{
double d;
string s;

switch (kd)
        {
        case Toint:
                code=nextCode();
                stk.push((int)get_expression('(',')'));
                break;
        
        case EXP:
                code=nextCode();
                stk.push(exp(get_expression('(',')')));
                break;
        
        case LOG:
                code=nextCode();
                stk.push(log(get_expression('(',')')));
                break;
        
        case PID:
                code=nextCode();
                stk.push(1000.);
                break;
        
        case Input:
                nextCode();
                nextCode();
                code=nextCode();
                getline(cin, s);
                stk.push(atof(s.c_str()));
                break;
        case Print: case Println:
                do
                {
                code=nextCode();
                if (code.kind == String) {cout << code.text; code=nextCode();}
                else
                        {
                        d=get_expression(); 
                        if (!exit_Flg) cout << d;
                        }
                } while (code.kind == ',');
                if (kd == Println) cout << endl;
                break;
        }
}

int get_memAdrs(const CodeSet& cd)
{
int adr=0, index, len;
double d;

adr=get_topAdrs(cd);
len=tableP(cd)->aryLen;
code=nextCode();
if (len==0) return adr;

d=get_expression('[',']');
if ((int)d != d) err_exit("Please assign array length with int.");
if (syntaxChk_mode) return adr;

index=(int)d;
if (index < 0 || len <= index)
        {
        err_exit(index, " is over aryLen(0-", len-1, ")");
        }

return adr+index;
}

int get_topAdrs(const CodeSet& cd)
{
switch (cd.kind)
        {
        case Gvar: return tableP(cd)->adrs;
        case Dvar: return tableP(cd)->adrs;
        case Lvar: return tableP(cd)->adrs+baseReg;
        default: err_exit("The name fo variable is needed: ", kind_to_s(cd));
        }
return 0;
}

int endline_of_If(int line)
{
CodeSet cd;
int save=code_ptr;
cd = firstCode(line);
for (;;)
        {
        line=cd.jmpAdrs;
        cd=firstCode(line);
        if (cd.kind == Elif || cd.kind == Else) continue;
        if (cd.kind == End) break;
        }
code_ptr=save;
return line;
}

void chk_EofLine()
{
if (code.kind != EofLine) err_exit("This is wrong: ", kind_to_s(code));
}

TknKind lookCode(int line)
{
    extern vector<int> intercode;
    extern vector<int> Ind;

    int Posi = Ind[line];

    return (TknKind)intercode[Posi];
}

CodeSet chk_nextCode(const CodeSet& cd, int kind2)
{
	if (cd.kind != kind2)
	{
		if (kind2 == EofLine) err_exit("This is wrong: ", kind_to_s(cd));
		if (cd.kind == EofLine) err_exit(kind_to_s(kind2), "is needed.");
		err_exit(kind_to_s(kind2) + " is needed before " + kind_to_s(cd));
	}
	return nextCode();
}

CodeSet firstCode(int line)
{
    code_ptr = Ind[line];
    return nextCode();
}

CodeSet nextCode()
{
TknKind kd;
short int jmpAdrs, tblNbr;

//if ((char)intercode[code_ptr] == '\0') return CodeSet(EofLine);

if (intercode[code_ptr] == EofLine) return CodeSet(EofLine);

kd = (TknKind)intercode[code_ptr++];

switch (kd)
        {
        case Func:
        case While: case For: case If: case Elif: case Else:
                jmpAdrs= intercode[code_ptr++];
                return CodeSet(kd, -1, jmpAdrs);

        case String:
                tblNbr = intercode[code_ptr++];
                return CodeSet(kd, strLITERAL[tblNbr].c_str());

        case IntNum: case DblNum:
                tblNbr = intercode[code_ptr++];
                return CodeSet(kd, nbrLITERAL[tblNbr]);

        case Fcall: case Gvar: case Lvar: case Dvar:
                tblNbr = intercode[code_ptr++];
                return CodeSet(kd, tblNbr, -1);

        default:
                return CodeSet(kd);
        }
}

void chk_dtTyp(const CodeSet& cd)
{
if (tableP(cd)->dtTyp == NON_T)
        {
        err_exit("This var is not initialized: ", kind_to_s(cd));
        }
}

void set_dtTyp(const CodeSet& cd, char typ)
{
int memAdrs = get_topAdrs(cd);

vector<SymTbl>::iterator p = tableP(cd);

if (p->dtTyp != NON_T) return;

p->dtTyp=typ;

if (cd.kind == Dvar)
        {
        if (p->aryLen != 0)
                {
                for (int n=0; n < p->aryLen; n++)
                        {
                        Gmem.set(memAdrs+n, 0);
                        }
                }
        }
else 
        {
        if (p->aryLen != 0)
                {
                for (int n=0; n < p->aryLen; n++)
                        {
                        Dmem.set(memAdrs+n, 0);
                        }
                }
        }
}

int set_LITERAL(double d)
{
for (int n=0; n<(int)nbrLITERAL.size(); n++)
        {
        if (nbrLITERAL[n] == d) return n;
        }
nbrLITERAL.push_back(d);
return nbrLITERAL.size() -1;
}

int set_LITERAL(const string& s)
{
for (int n=0; n<(int)strLITERAL.size(); n++)
        {
        if (strLITERAL[n] == s) return n;
        }
strLITERAL.push_back(s);
return strLITERAL.size() -1;
}
