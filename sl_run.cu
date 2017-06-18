#include "sl_run.cuh"

__global__
void sl_Exe_global(int nloop, int nBlocks, int nThreads, unsigned int maxProc, int DmemSiz, int IndexSiz, int CodeArrSiz, int spReg,
     RUN_PARM* x_runParm, Stack* x_stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
     int* x_Index, int* x_CodeArr, double* x_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* x_code, double* x_stack)
{
    unsigned int lo_id = blockDim.x * blockIdx.x + threadIdx.x;
    unsigned int thread_id = (unsigned int)nBlocks * (unsigned int)nThreads * (unsigned int)nloop + lo_id;
    
    if (thread_id < maxProc) {
        int* Index = &(x_Index[thread_id * IndexSiz]);
        int* CodeArr = &(x_CodeArr[thread_id * CodeArrSiz]);
        RUN_PARM* d_runParm = &(x_runParm[thread_id]);
        Stack* d_stk = &(x_stk[thread_id]);
        
        double* d_Dmem = &(x_Dmem[thread_id * DmemSiz]);
        
        TokenSet* d_code = &(x_code[2*thread_id]);
        double* d_stack = &(x_stack[MAXSIZE_ * thread_id]);

        d_stk->MAXSIZE = MAXSIZE_;
    	d_stk->top = -1;

        d_runParm->baseReg = 0;
        d_runParm->spReg = spReg;
        d_runParm->Pc = 1;

        d_runParm->ThreadId = thread_id;

        d_runParm->break_Flg=d_runParm->return_Flg=d_runParm->exit_Flg=false;
        d_runParm->maxLine = IndexSiz-2;

        sl_execute(d_runParm, d_stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, d_code, d_stack);
    }
}

__device__ __host__
void sl_execute(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    while (runParm->Pc <= runParm->maxLine && ! runParm->exit_Flg) {
        sl_statement(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
    }
}

__device__ __host__
void sl_statement(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    TokenSet* save = &(code[1]);
    int top_line, end_line, varAdrs;
    double wkVal, endDt, stepDt;

    if (runParm->Pc > runParm->maxLine || runParm->exit_Flg) return;

    sl_firstCode(code, runParm, runParm->Pc, Index, CodeArr, nbrLITERAL);

    top_line = runParm->Pc;
    end_line = code->jmpAdrs;

    if (code->kind == If) end_line = sl_endline_of_If(runParm, save, runParm->Pc, Index, CodeArr, nbrLITERAL);

    code[1]=code[0];

    if (code->kind == If) {
        if (sl_get_expression(runParm, stk, While, EofLine, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack)) {
            ++runParm->Pc;
			sl_block(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
            runParm->Pc = end_line + 1;
            return ;
        }
        runParm->Pc = save->jmpAdrs;
        while (sl_lookCode(runParm->Pc, Index, CodeArr) == Elif)
        {
			sl_firstCode(save, runParm, runParm->Pc, Index, CodeArr, nbrLITERAL);
		    sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
            sl_expression(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
            
            if (stack_pop(stk, stack)) {
                ++runParm->Pc;
                sl_block(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
                runParm->Pc = end_line + 1;
                return ;
            }
            runParm->Pc = save->jmpAdrs;
        }

        if (sl_lookCode(runParm->Pc, Index, CodeArr) == Else) {
            ++runParm->Pc;
            sl_block(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
            runParm->Pc = end_line + 1;
            return ;
        }
        ++runParm->Pc;
	}
	else if (code->kind == While) {

		for (;;) {
			if (!sl_get_expression(runParm, stk, While, EofLine, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack) ) break;
			++runParm->Pc;
			sl_block(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);

			if (runParm->break_Flg || runParm->return_Flg || runParm->exit_Flg) {
				runParm->break_Flg = false;
				break;
			}
			runParm->Pc = top_line;
			sl_firstCode(code, runParm, runParm->Pc, Index, CodeArr, nbrLITERAL);
		}
		runParm->Pc = end_line + 1;
	}
	else if (code->kind == For) {
		sl_nextCode(save, runParm, nbrLITERAL, Index, CodeArr);
		varAdrs = sl_get_memAdrs(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, save, stack);

		sl_expression(runParm, stk, '=', 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		sl_set_dtTyp(runParm, stk, save, DBL_T, GTbl, LTbl, d_Dmem, d_Gmem);

		sl_set_mem(d_Dmem, varAdrs, stack_pop(stk, stack));

		endDt = sl_get_expression(runParm, stk, To, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);

		if (code->kind == Step) {
			stepDt = sl_get_expression(runParm, stk, Step, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		}
		else {
			stepDt = 1.;
		}

		for (;; runParm->Pc = top_line)
		{                            
			if (stepDt >= 0) {                                
				if (d_Dmem[varAdrs] > endDt) break;            
			}
			else {                                        
				if (d_Dmem[varAdrs] < endDt) break;
			}                                                 
			++runParm->Pc;
			sl_block(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);

			if (runParm->break_Flg || runParm->return_Flg || runParm->exit_Flg) {
				runParm->break_Flg = false;
				break;                       
			}
			d_Dmem[varAdrs] += stepDt;
		}                                                 
		runParm->Pc = end_line + 1; 
    }
    else if (code->kind == Break) {
    	runParm->break_Flg = true;
    }
    else if (code->kind == Gvar || code->kind == Lvar || code->kind == Dvar) {
		varAdrs = sl_get_memAdrs(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		
		int Op = 0;
		if (code->kind == SumAssign) Op = 1;
		else if (code->kind == MinusAssign) Op = 2;
		else if (code->kind == MultiAssign) Op = 3;
		else if (code->kind == DiviAssign) Op = 4;

		if (Op == 0) sl_expression(runParm, stk, '=', 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		else if (Op == 1) sl_expression(runParm, stk, SumAssign, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		else if (Op == 2) sl_expression(runParm, stk, MinusAssign, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		else if (Op == 3) sl_expression(runParm, stk, MultiAssign, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		else if (Op == 4) sl_expression(runParm, stk, DiviAssign, 0, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);

		double Val;
		if (stk->top != -1) {
			Val = stack[stk->top];
			stk->top -= 1;
		}
		else Val = -12133131;


		sl_set_dtTyp(runParm, stk, save, DBL_T, GTbl, LTbl, d_Dmem, d_Gmem);

		if (Op == 0) {
			if (save->kind == Dvar) sl_set_mem(d_Gmem, varAdrs, Val);
			else if (save->kind == Gvar) sl_set_mem(d_Dmem, varAdrs, Val);
			else sl_set_mem(d_Dmem, varAdrs, Val);
		}
		else if (Op == 1) {
			if (save->kind == Dvar) sl_add_mem(d_Gmem, varAdrs, Val);
			else if (save->kind == Gvar) sl_add_mem(d_Dmem, varAdrs, Val);
			else sl_add_mem(d_Dmem, varAdrs, Val);
		}
		else if (Op == 2) {
			if (save->kind == Dvar) d_Gmem[varAdrs] -= Val;
			else if (save->kind == Gvar) d_Dmem[varAdrs] -= Val;
			else d_Dmem[varAdrs] -= Val;
		}
		else if (Op == 3) {
			if (save->kind == Dvar) d_Gmem[varAdrs] *= Val;
			else if (save->kind == Gvar) d_Dmem[varAdrs] *= Val;
			else d_Dmem[varAdrs] *= Val;
		}
		else if (Op == 4) {
			if (save->kind == Dvar) d_Gmem[varAdrs] /= Val;
			else if (save->kind == Gvar) d_Dmem[varAdrs] /= Val;
			else d_Dmem[varAdrs] /= Val;
		}

        ++ runParm->Pc;
    }
    else if (code->kind == Option || code->kind == Var || code->kind == EofLine) {
    	++ runParm->Pc;
    }
}

__device__ __host__
void sl_firstCode(TokenSet* code, RUN_PARM* runParm, int line,
                    int* Index, int* CodeArr, double* nbrLITERAL)
{
    runParm->code_ptr = Index[line];

    TknKind k = (TknKind)CodeArr[runParm->code_ptr];

    if (k==If || k == For || k == Elif || k == Else || k == End || k == While) {
    	runParm->code_ptr++;
    	int jmpAdrs = CodeArr[runParm->code_ptr++];
        token_set(code, k, -1, jmpAdrs);
    }
    else sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
}

__device__ __host__
void sl_nextCode(TokenSet* Ts, RUN_PARM* runParm, double* nbrLITERAL, int* Index, int* CodeArr)
{
    TknKind kd;
    int jmpAdrs, tblNbr, nK;

    if ((TknKind)CodeArr[runParm->code_ptr] == EofLine) {
        token_set(Ts, EofLine);
    }

    nK = CodeArr[runParm->code_ptr];
    kd = (TknKind)CodeArr[runParm->code_ptr++];

    switch(kd) 
	{
    case IntNum: case DblNum:
        tblNbr = CodeArr[runParm->code_ptr++];
        Ts->kind = kd;
        Ts->nKind = nK;
        Ts->dblVal = nbrLITERAL[tblNbr];
        break;

    case Gvar: case Lvar: case Dvar:
        tblNbr = CodeArr[runParm->code_ptr++];
        Ts->kind=kd;
        Ts->nKind = nK;
        Ts->symNbr = tblNbr;
        Ts->dblVal = -1;
        break;

    default:
    	Ts->kind = kd;
        Ts->nKind = nK;
        break;
    }

}

__device__ __host__
int sl_endline_of_If(RUN_PARM* runParm, TokenSet* cd, int line, int* Index, int* CodeArr, double* nbrLITERAL)
{
    int jmpline;
    int save_code_ptr = runParm->code_ptr;
    int save_Pc = runParm-> Pc;

    sl_firstCode(cd, runParm, line, Index, CodeArr, nbrLITERAL);

    for (;;) {
        jmpline = cd->jmpAdrs;
        sl_firstCode(cd, runParm, jmpline, Index, CodeArr, nbrLITERAL);
        if (cd->kind == Elif || cd->kind == Else) continue;
        if (cd->kind == End) break;
    }
	runParm->code_ptr = save_code_ptr;
	runParm->Pc = save_Pc;

    return jmpline;
}

__device__ __host__
double sl_get_expression(RUN_PARM* runParm, Stack* stk, int kind1, int kind2, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    sl_expression(runParm, stk, kind1, kind2, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
    return stack_pop(stk, stack);
}


__device__ __host__
void sl_expression(RUN_PARM* runParm, Stack* stk, int kind1, int kind2, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    if (kind1 != 0) sl_chk_nextCode(runParm, code, kind1, nbrLITERAL, Index, CodeArr);
    sl_expression(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
    if (kind2 !=0) sl_chk_nextCode(runParm, code, kind2, nbrLITERAL, Index, CodeArr);
}


__device__ __host__
void sl_chk_nextCode(RUN_PARM* runParm, TokenSet* code, int kind2, double* nbrLITERAL,
                            int* Index, int* CodeArr)
{
    sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
}


__device__ __host__
void sl_expression(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
            int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    TknKind op;
    int nK;
    sl_term(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack, 1);

    while(true) {
        if (code->nKind != 43 && code->nKind != 45) break;

        nK = code->nKind;
        sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
        sl_term(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack, 1);
        sl_binaryExpr(stk, op, stack);
    }
}

__device__ __host__
void sl_term(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
            int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack,
            int n)
{
    TknKind op;

    sl_factor(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
        
    int nK = code->nKind;
    while (nK == 47 || nK == 42 || nK == 92 ||
        nK == 37 || nK == 166 || nK == 167 ||
        nK == 168 || nK == 169 || nK == 170 ||
        nK == 171 || nK == 172 || nK == 173)
    {
        sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
        sl_factor(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem,nbrLITERAL, code, stack);
        sl_binaryN(stk, nK, stack);
        nK = code->nKind;
    }
/*
    int nK = code->nKind;

	if (n == 7) {
        sl_factor(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
        return;
    }
	
    sl_term(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack, n+1);
    
	while (n == sl_opOrder(code->nKind))
	{
        nK = code->nKind;
		sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
        sl_term(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack, n+1);
		sl_binaryN(stk, nK, stack);
    }
*/
}

__device__ __host__
void sl_factor(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
	TknKind kd, k;
	kd = k = code->kind;

	int adr=0, index, len, symNbr, Adrs=0, symNbr_2, adr_2;
	double d=0.;

    switch (kd) {
		
	case EXP:
		sl_expression(runParm, stk, Lparen, Rparen, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
        stack_push(stk, exp(stack_pop(stk, stack)), stack);
        break;

	case LOG:
		sl_expression(runParm, stk, Lparen, Rparen, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
        stack_push(stk, log(stack_pop(stk, stack)), stack);
        break;

	case PID:
		stk->top += 1;
		stack[stk->top] = (double)runParm->ThreadId;
		sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
		break;
	
	case Not: case Minus: case Plus:
		sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
		sl_factor(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		if (kd == Not) stack_push(stk, !(stack_pop(stk, stack)), stack);
		if (kd == Minus) stack_push(stk, -(stack_pop(stk, stack)), stack);
		break;

	case Lparen:
		sl_expression(runParm, stk, Lparen, Rparen, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
		break;

    case IntNum: case DblNum:
        stack_push(stk, code->dblVal, stack);
        sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
        break;

    case Gvar: case Lvar: case Dvar:

    	sl_chk_dtTyp(code, GTbl, LTbl);

		symNbr = code->symNbr;

		d_SymTbl* sym;

		if (code->kind == Dvar) sym = &(GTbl[symNbr]);
		else if (code->kind == Lvar) sym = &(LTbl[symNbr]);
		else sym = &(GTbl[symNbr]);

		adr = sl_get_topAdrs(runParm, code, symNbr, GTbl, LTbl);
		len = sym->aryLen;

		if (Lbracket == (TknKind) CodeArr[runParm->code_ptr]) {
			sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
			sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);

			if (code->kind == Lvar || code->kind == Gvar) {
				int symNbr_2 = code->symNbr;
				int adr_2 = sl_get_topAdrs(runParm, code, symNbr_2, GTbl, LTbl);
				d = sl_get_mem(d_Dmem, adr_2);
			}
			else if (code->kind == IntNum || code->kind == DblNum) {
				d = code->dblVal;
			}
			else if (code->kind == PID) {
				d = (double)runParm->ThreadId;
			}

			sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
		}

		index = (int)d;

		if (len==0)	Adrs = adr;
		else		Adrs = adr+index;

        if (kd == Gvar) stack_push(stk, sl_get_mem(d_Dmem, Adrs), stack);
        else if (kd == Lvar) stack_push(stk, sl_get_mem(d_Dmem, Adrs), stack);
        else if (kd == Dvar) stack_push(stk, sl_get_mem(d_Gmem, Adrs), stack);

        sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);

        break;
    }

}


__device__ __host__
void sl_chk_dtTyp(const TokenSet* cd, d_SymTbl* GTbl, d_SymTbl* LTbl)
{
    int symNbr = cd->symNbr;

    if (cd->kind == Dvar) {
        if (GTbl[symNbr].dtTyp == NON_T) {
        	return;
        }
    }
    else if (cd->kind == Lvar) {
        if (LTbl[symNbr].dtTyp == NON_T) {
        	return;
        }
    }
	else if (cd->kind == Gvar)
	{
		if (GTbl[symNbr].dtTyp == NON_T)
		{
			return;
		}
	}
}


__device__ __host__
int sl_get_memAdrs(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
        int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    int adr=0, index, len, symNbr;
    symNbr = code->symNbr;
    double d=0.;

    d_SymTbl* sym;


    if (code->kind == Dvar) sym = &(GTbl[symNbr]);
    else if (code->kind == Lvar) sym = &(LTbl[symNbr]);
    else sym = &(GTbl[symNbr]);

    adr = sl_get_topAdrs(runParm, code, symNbr, GTbl, LTbl);
    len = sym->aryLen;
    sl_nextCode(code, runParm, nbrLITERAL, Index, CodeArr);
    if (len==0) return adr;

    d = sl_get_expression(runParm, stk, '[',']', GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);

    index = (int)d;

    return adr+index;
}


__device__ __host__
int sl_get_topAdrs(RUN_PARM* runParm, const TokenSet* cd, int symNbr, d_SymTbl* GTbl, d_SymTbl* LTbl)
{
    switch(cd->kind) {
    case Gvar: case Dvar:
        return GTbl[symNbr].adrs;
    case Lvar:
        return LTbl[symNbr].adrs + runParm->baseReg;
    }
}


__device__ __host__
void sl_set_dtTyp(RUN_PARM* runParm, Stack* stk, TokenSet* cd, DtType typ, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    double* d_Dmem, double* d_Gmem)
{
    int memAdrs = sl_get_topAdrs(runParm, cd, cd->symNbr, GTbl, LTbl);

    d_SymTbl* sym;


    if (cd->kind == Dvar) sym = &(GTbl[cd->symNbr]);
    else if (cd->kind == Lvar) sym = &(LTbl[cd->symNbr]);
    else sym = &(GTbl[cd->symNbr]);

    if (sym->dtTyp != NON_T) return;

    sym->dtTyp = typ;
}


__device__ __host__
void sl_block(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
        int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack)
{
    TknKind k;
    while (! runParm->break_Flg && ! runParm->return_Flg && ! runParm->exit_Flg) {
        k = sl_lookCode(runParm->Pc, Index, CodeArr);
        if (k == Elif || k == Else || k == End) break;
        sl_statement(runParm, stk, GTbl, LTbl, Index, CodeArr, d_Dmem, d_Gmem, nbrLITERAL, code, stack);
    }
}


__device__ __host__
TknKind sl_lookCode( int line, int* Index, int* CodeArr)
{
	int Posi = Index[line];
    return (TknKind)CodeArr[Posi];
}

__device__ __host__
void sl_binaryExpr(Stack* stk, TknKind op, double* stack)
{
	double d2 = stack_pop(stk, stack), d1 = stack_pop(stk, stack);

	if ((op==Divi || op==Mod || op==IntDivi) && d2==0) {
		return;
	}

	switch (op) {
	case Plus:    stack_push(stk, d1 + d2, stack);  break;
	case Minus:   stack_push(stk, d1 - d2, stack);  break;
	case Multi:   stack_push(stk, d1 * d2, stack);  break;
	case Divi:    stack_push(stk, d1 / d2, stack);  break;
	case Mod:     stack_push(stk, (int)d1 % (int)d2, stack); break;
	case IntDivi: stack_push(stk, (int)d1 / (int)d2, stack); break;
	case Less:    stack_push(stk, d1 <  d2, stack); break;
	case LessEq:    stack_push(stk, d1 <=  d2, stack); break;
	case Great:    stack_push(stk, d1 >  d2, stack); break;
	case GreatEq:    stack_push(stk, d1 >=  d2, stack); break;
	case Equal:    stack_push(stk, d1 == d2, stack); break;
	case NotEq:    stack_push(stk, d1 != d2, stack); break;
	case And:    stack_push(stk, d1 && d2, stack); break;
	case Or:    stack_push(stk, d1 || d2, stack); break;

	}
}

__device__ __host__
void sl_binaryN(Stack* stk, int op, double* stack)
{
	double d2 = stack_pop(stk, stack), d1 = stack_pop(stk, stack);

	if ((op== 47 || op==37 || op==92) && d2==0) {
		return;
	}

	if (op == 43)    stack_push(stk, d1 + d2, stack);
	else if (op ==45) stack_push(stk, d1 - d2, stack);
	else if (op ==42) stack_push(stk, d1 * d2, stack);
	else if (op ==47) stack_push(stk, d1 / d2, stack);
	else if (op ==37) stack_push(stk, (int)d1 % (int)d2, stack);
	else if (op ==92) stack_push(stk, (int)d1 / (int)d2, stack);
	else if (op ==168) stack_push(stk, d1 <  d2, stack);
	else if (op ==169) stack_push(stk, d1 <=  d2, stack);
	else if (op ==170) stack_push(stk, d1 >  d2, stack);
	else if (op ==171) stack_push(stk, d1 >=  d2, stack);
	else if (op ==166) stack_push(stk, d1 == d2, stack);
	else if (op ==167) stack_push(stk, d1 !=  d2, stack);
	else if (op ==172) stack_push(stk, d1 && d2, stack);
	else if (op ==173) stack_push(stk, d1 ||  d2, stack);
}

__device__ __host__
int sl_opOrder(int nK)
{
    switch (nK) {
    case 42: case 47: case 37:
    case 92:                    return 6;
    case 43:  case 45:          return 5;
    case 168:  case 169:
    case 170: case 171:        return 4;
    case 166: case 167:          return 3;
    case 172:                        return 2;
    case 173:                         return 1;
    default:                         return 0;
    }
}

__device__ __host__
void sl_set_mem(double* mem, int adrs, double dt)
{
    mem[adrs] = dt;
}

__device__ __host__
void sl_add_mem(double* mem, int adrs, double dt)
{
   mem[adrs] += dt;
}

__device__ __host__
double sl_get_mem(double* mem, int adrs)
{
    return mem[adrs];
}

__device__ __host__
void token_clear(TokenSet* Ts)
{
    Ts->kind=Others;
    Ts->dblVal=0.;
    Ts->symNbr=0;
    Ts->jmpAdrs=0;
}

__device__ __host__
void token_set(TokenSet* Ts)
{
    token_clear(Ts);
}

__device__ __host__
void token_set(TokenSet* Ts, TknKind k)
{
    token_clear(Ts);
    Ts->kind=k;
}


__device__ __host__
void token_set(TokenSet* Ts, TknKind k, double d)
{
    token_clear(Ts);
    Ts->kind=k;
    Ts->dblVal=d;
}


__device__ __host__
void token_set(TokenSet* Ts, TknKind k, int sym, int jmp)
{
    token_clear(Ts);
    Ts->kind=k;
    Ts->symNbr=sym;
    Ts->jmpAdrs=jmp;
}


__device__ __host__
bool stack_isfull(Stack* St)
{
    if (St->top == St->MAXSIZE) return true;
    else return false;
}

__device__ __host__
bool stack_empty(Stack* St)
{
    if (St->top == -1) return true;
    else  return false;
}

__device__ __host__
void stack_push(Stack* St, double data, double* stack)
{
    if (!stack_isfull(St)) {
        St->top = St->top + 1;
        stack[St->top]=data;
    }
}

__device__ __host__
double stack_pop(Stack* St, double* stack)
{
    double data;

    if (St->top != -1) {
        data = stack[St->top];
        St->top -= 1;
        return data;
    }
}
