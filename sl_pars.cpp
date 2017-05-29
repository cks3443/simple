#include "sl.h"
#include "sl_prot.h"

#define NO_FIX_ADRS 0

Token token;
SymTbl tmpTb;
int blkNest;
int localAdrs;
int mainTblNbr;
int loopNest;
bool fncDecl_F;
bool explicit_F;
char codebuf[LIN_SIZ + 1], *codebuf_p;

extern int Pc;

vector<int> intercode;
vector<int> Ind;

void init()
{
    initChTyp();

    mainTblNbr=-1;
    blkNest = loopNest = 0;
    fncDecl_F = explicit_F = false;
    codebuf_p = codebuf;
}

void convert_to_internalCode(char* fname)
{
    extern vector<int> intercode;

    init();

    fileOpen(fname);

    while (token=nextLine_tkn(), token.kind != EofProg) {
        if (token.kind == Func) {
            token=nextTkn();
            set_name();
            enter(tmpTb, fncId);
        }
    }

    Ind.push_back(0);

    push_intercode();

    fileOpen(fname);
    token = nextLine_tkn();
    
    while (token.kind != EofProg) {
        convert();
    }
    Pc = 1;
/*
    if (mainTblNbr != -1) {
        //Pc = intercode.size();
        setCode(Fcall, mainTblNbr);
        setCode('(');
        setCode(')');
        push_intercode();
    }
*/
}

void convert()
{
switch (token.kind)
        {
        case Option:
                optionSet();
                break;
        case Var:
                varDecl();
                break;
        case Func:
                fncDecl();
                break;
        case While: case For:
                ++loopNest;
                convert_block_set();
                setCode_End();
                --loopNest;
                break;
        case If:
                convert_block_set();
                while (token.kind == Elif)
                        {
                        convert_block_set();
                        }
                if (token.kind == Else) convert_block_set();
                setCode_End();
                break;
        case Break:
                if (loopNest <= 0) err_exit("This is fault 'break'.");
                setCode(token.kind);
                token=nextTkn();
                convert_rest();
                break;
        case Return:
                if (!fncDecl_F) err_exit("This return is wrong.");
                setCode(token.kind);
                token=nextTkn();
                convert_rest();
                break;
        case Exit:
                setCode(token.kind);
                token=nextTkn();
                convert_rest();
                break;
        case Print: case Println:
                setCode(token.kind);
                token=nextTkn();
                convert_rest();
                break;
        case End:
                err_exit("This is fault 'end'.");
                break;
        default:
                convert_rest();
                break;
        }
}

void convert_block_set()
{
int patch_line;
patch_line = setCode(token.kind, NO_FIX_ADRS);
token=nextTkn();
convert_rest();
convert_block();
backPatch(patch_line, get_lineNo());
}

void convert_block()
{
TknKind k;
++blkNest;
while (k=token.kind, k != Elif && k != Else && k != End && k != EofProg)
        {
        convert();
        }
--blkNest;
}

void convert_rest()
{
int tblNbr;

for (;;)
        {
        if (token.kind == EofLine) break;
        switch (token.kind)
                {
                case If: case Elif: case Else: case For: case While: case Break:
                case Func: case Return: case Exit: case Print: case Println:
                case Option: case Var: case End:
                        err_exit("This is wrong.", token.text);
                        break;
                case Ident:
                        set_name();
                        if ((tblNbr = searchName(tmpTb.name, 'F')) != -1)
                                {
                                if (tmpTb.name == "main") err_exit("main function do not call.");
                                setCode(Fcall, tblNbr);
                                continue;
                                }
                        if ((tblNbr=searchName(tmpTb.name, 'V')) == -1)
                                {
                                if (explicit_F) err_exit("Declation of variable is needed: ", tmpTb.name);
                                tblNbr=enter(tmpTb, varId);
                                }
                        if (is_localName(tmpTb.name, varId))
                                {
                                setCode(Lvar, tblNbr);
                                }
                        else if (tmpTb.name[0] == '$') setCode(Dvar, tblNbr);
                        else setCode(Gvar, tblNbr);
                        continue;
                case IntNum: case DblNum:
                        setCode(token.kind, set_LITERAL(token.dblVal));
                        break;
                case String:
                        setCode(token.kind, set_LITERAL(token.text));
                        break;
                default:
                        setCode(token.kind);
                        break;
                }
        token=nextTkn();
        }
push_intercode();
token=nextLine_tkn();
}

void optionSet()
{
setCode(Option);
setCode_rest();
token=nextTkn();

if (token.kind == String && token.text == "var") explicit_F=true;
else err_exit("This option is fault.");

token=nextTkn();
setCode_EofLine();
}

void varDecl()
{
setCode(Var);
setCode_rest();

for (;;)
        {
        token=nextTkn();
        var_namechk(token);
        set_name();
        set_aryLen();
        
        if (tmpTb.name[0] == '$') enter(tmpTb, devId);
        else enter(tmpTb, varId);

        if (token.kind != ',') break;
        }
setCode_EofLine();
}

void var_namechk(const Token& tk)
{
if (tk.kind != Ident) err_exit(err_msg(tk.text, "Identifier"));
if (is_localScope() && tk.text[0] == '$') err_exit("Declation of '$' is not used in function: ", tk.text);
if (searchName(tk.text, 'V') != -1) err_exit("This Ident is double: ", tk.text);
}

void set_name()
{
if (token.kind != Ident) err_exit("Identifier is needed: ", token.text);
tmpTb.clear();
tmpTb.name=token.text;
token=nextTkn();
}

void set_aryLen()
{
tmpTb.aryLen=0;
if (token.kind != '[') return;

token=nextTkn();
if (token.kind != IntNum) err_exit("The length of array have to be plus: ", token.text);
tmpTb.aryLen=(int)token.dblVal;
token=chk_nextTkn(nextTkn(), ']');
if (token.kind == '[') err_exit("Multi array is not assigned.");
}

void fncDecl()
{
extern vector<SymTbl> Gtable;
int tblNbr, patch_line, fncTblNbr;

if (blkNest >0) err_exit("The location of function is wrong.");
fncDecl_F=true;
localAdrs=0;
set_startLtable();
patch_line=setCode(Func, NO_FIX_ADRS);
token=nextTkn();
fncTblNbr=searchName(token.text, 'F');
Gtable[fncTblNbr].dtTyp=DBL_T;

token=nextTkn();
token=chk_nextTkn(token, '(');

setCode('(');

if (token.kind != ')')
        {
        for (;; token=nextTkn())
                {
                set_name();
                tblNbr=enter(tmpTb, paraId);
                setCode(Lvar, tblNbr);
                ++Gtable[fncTblNbr].args;
        
                if (token.kind != ',') break;

                setCode(',');
                }
        }
token=chk_nextTkn(token, ')');
setCode(')');
setCode_EofLine();
convert_block();

backPatch(patch_line, get_lineNo());
setCode_End();
Gtable[fncTblNbr].frame=localAdrs;

if (Gtable[fncTblNbr].name == "main")
        {
        mainTblNbr=fncTblNbr;
        if (Gtable[mainTblNbr].args != 0) err_exit("main func do not assign.");
        }
fncDecl_F=false;
}

void backPatch(int line, int n)
{
    extern vector<int> intercode;
    extern vector<int> Ind;

    int Posi = Ind[line];
    intercode[Posi + 1] = n;
}

void setCode(int cd)
{
    intercode.push_back(cd);
}

int setCode(int cd, int nbr)
{
    extern vector<int> intercode;
    intercode.push_back(cd);
    intercode.push_back(nbr);
    return get_lineNo();
}

void setCode_rest()
{
extern char* token_p;
strcpy(codebuf_p, token_p);
codebuf_p += strlen(token_p) +1;
}

void setCode_End()
{
if (token.kind != End) err_exit(err_msg(token.text, "end"));
setCode(End);
token = nextTkn();
setCode_EofLine();
}

void setCode_EofLine()
{
if (token.kind != EofLine) err_exit("This is wrong: ", token.text);
push_intercode();
token=nextLine_tkn();
}

void push_intercode()
{
    intercode.push_back(EofLine);
    Ind.push_back(intercode.size());
}

bool is_localScope()
{
return fncDecl_F;
}
             
