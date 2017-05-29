#ifndef SL_RUN_CUH
#define SL_RUN_CUH

#include "sl.h"
#include "sl_prot.h"
#include <cuda_runtime.h>

#define MAXSIZE_ 15

typedef struct {
    int nKind;
    TknKind kind;
    double dblVal;
    int symNbr;
    int jmpAdrs;

} TokenSet ;

typedef struct {
    int MAXSIZE;
    int top;
}Stack;

typedef struct {
    int Siz;
    int sizArr;
}sl_Intercode;

typedef struct {
	int nThread;
    int ThreadId;
    int Pc, baseReg, spReg, maxLine;
    int code_ptr;
    double returnValue;
    bool break_Flg, return_Flg, exit_Flg;

}RUN_PARM;

typedef struct{
    int nBlock, nThread;
    int nloop;
    unsigned int maxProc, lo_id, thread_id;
    int DSiz, GSiz;
}DevOpt;

__global__
void sl_Exe_global(int nloop, int nBlocks, int nThreads, int maxProc, int DmemSiz, int IndexSiz, int spReg,
     RUN_PARM* x_runParm, Stack* x_stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
     int* Index, int* CodeArr, double* x_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* x_code, double* x_stack);

__device__ __host__
void sl_execute(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_statement(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_firstCode(TokenSet* code, RUN_PARM* runParm, int line, int* Index, int* CodeArr, double* nbrLITERAL);

__device__ __host__
void sl_nextCode(TokenSet* Ts, RUN_PARM* runParm, double* nbrLITERAL, int* Index, int* CodeArr);

__device__ __host__
int sl_endline_of_If(RUN_PARM* runParm, TokenSet* cd, int line, int* Index, int* CodeArr, double* nbrLITERAL);

__device__ __host__
double sl_get_expression(RUN_PARM* runParm, Stack* stk, int kind1, int kind2, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_expression(RUN_PARM* runParm, Stack* stk, int kind1, int kind2, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_chk_nextCode(RUN_PARM* runParm, TokenSet* cd, int kind2, double* nbrLITERAL,
                            int* Index, int* CodeArr);

__device__ __host__
void sl_expression(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
            int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_term(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
            int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack,
            int n);

__device__ __host__
void sl_factor(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
                int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
void sl_chk_dtTyp(const TokenSet* cd, d_SymTbl* GTbl, d_SymTbl* LTbl);

__device__ __host__
int sl_get_memAdrs(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
        int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
int sl_get_topAdrs(RUN_PARM* runParm, const TokenSet* cd, int symNbr, d_SymTbl* GTbl, d_SymTbl* LTbl);

__device__ __host__
void sl_set_dtTyp(RUN_PARM* runParm, Stack* stk, TokenSet* cd, DtType typ, d_SymTbl* GTbl, d_SymTbl* LTbl,
                    double* d_Dmem, double* d_Gmem);

__device__ __host__
void sl_block(RUN_PARM* runParm, Stack* stk, d_SymTbl* GTbl, d_SymTbl* LTbl,
        int* Index, int* CodeArr, double* d_Dmem, double* d_Gmem, double* nbrLITERAL, TokenSet* code, double* stack);

__device__ __host__
TknKind sl_lookCode( int line, int* Index, int* CodeArr);

__device__ __host__
void sl_binaryExpr(Stack* stk, TknKind op, double* stack);

__device__ __host__
void sl_binaryN(Stack* stk, int op, double* stack);

__device__ __host__
int sl_opOrder(int nK);

__device__ __host__
void sl_set_mem(double* mem, int adrs, double dt);

__device__ __host__
void sl_add_mem(double* mem, int adrs, double dt);

__device__ __host__
double sl_get_mem(double* mem, int adrs);

__device__ __host__
void token_clear(TokenSet* Ts);

__device__ __host__
void token_set(TokenSet* Ts);

__device__ __host__
void token_set(TokenSet* Ts, TknKind k);

__device__ __host__
void token_set(TokenSet* Ts, TknKind k, double d);

__device__ __host__
void token_set(TokenSet* Ts, TknKind k, int sym, int jmp);

__device__ __host__
bool stack_isfull(Stack* St);

__device__ __host__
bool stack_empty(Stack* St);

__device__ __host__
void stack_push(Stack* St, double data, double* stack);

__device__ __host__
double stack_pop(Stack* St, double* stack);

#endif
