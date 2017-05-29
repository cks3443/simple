
#include "sl_device.cuh"

void sl_run_host(int maxProc)
{
    int IndexSiz, CodeArrSiz, DmemSiz, GmemSiz, nbrSiz;
    int GSiz, LSiz, spReg;

    int *h_Index;
    int *h_CodeArr;
    d_SymTbl *h_GTbl, *h_LTbl;
    double *h_Dmem, *h_Gmem, *h_nbrLITERAL;
    RUN_PARM *h_runParm;

    IndexSiz = (int)Ind.size();
    CodeArrSiz = intercode.size();


    h_Index = new int[IndexSiz];
    h_CodeArr = new int[CodeArrSiz];

    for (int i=0; i < IndexSiz; i++) h_Index[i] = Ind[i];
    for (int i=0; i < CodeArrSiz; i++) h_CodeArr[i] = intercode[i];

    h_runParm = new RUN_PARM[maxProc];

    GSiz = Gtable.size();
    LSiz = Ltable.size();

    h_GTbl = new d_SymTbl[GSiz];
    h_LTbl = new d_SymTbl[LSiz];

    for (int i=0; i<GSiz; i++) {
        h_GTbl[i].nmKind =Gtable[i].nmKind;
        h_GTbl[i].dtTyp	=Gtable[i].dtTyp;
        h_GTbl[i].aryLen =Gtable[i].aryLen;
        h_GTbl[i].args =Gtable[i].args;
        h_GTbl[i].adrs =Gtable[i].adrs;
        h_GTbl[i].frame =Gtable[i].frame;
    }

    for (int i=0; i<LSiz; i++) {
        h_LTbl[i].nmKind =Ltable[i].nmKind;
        h_LTbl[i].dtTyp	=Ltable[i].dtTyp;
        h_LTbl[i].aryLen =Ltable[i].aryLen;
        h_LTbl[i].args =Ltable[i].args;
        h_LTbl[i].adrs =Ltable[i].adrs;
        h_LTbl[i].frame =Ltable[i].frame;
    }

    spReg = Dmem.size();

    int BigFram = 0, SizGTbl = 0;
    SizGTbl = Gtable.size();

    for (int i=0; i < SizGTbl; i++) {
        int Fram = Gtable[i].frame;
        if (BigFram < Fram) BigFram = Fram;
    }

    Dmem.resize(spReg + BigFram + 1);


    DmemSiz = Dmem.size();
    GmemSiz = Gmem.size();
    nbrSiz = nbrLITERAL.size();

    h_Dmem = new double[DmemSiz * maxProc];
    h_Gmem = new double[GmemSiz];
    h_nbrLITERAL = new double[nbrSiz];

    for (int i=0; i< DmemSiz*maxProc; i++) {
		int lo_i = i % DmemSiz;
		h_Dmem[i] = Dmem.get(lo_i);
	}

    for (int i=0; i< GmemSiz; i++) {
		h_Gmem[i] = Gmem.get(i);
	}

    for (int i=0; i< nbrSiz; i++) {
		h_nbrLITERAL[i] = nbrLITERAL[i];
	}

    Stack* h_stk = new Stack[maxProc];

	for (int i=0; i<maxProc; i++) {
	    h_stk[i].MAXSIZE = MAXSIZE_;
	    h_stk[i].top = -1;
	}

    double* h_stack = new double[MAXSIZE_ * maxProc];
    TokenSet* h_code = new TokenSet[2 * maxProc];

	int nProc = omp_get_thread_num();
	if (0 != nProc - 1) nProc -= 1;
	
	omp_set_num_threads( 1 );

	int i_=0;
#pragma omp parallel for private(i_)
	for (i_=0; i_<maxProc; i_++) {

		RUN_PARM* lo_runParm = &(h_runParm[i_]);
		lo_runParm->baseReg = 0;
		lo_runParm->spReg = spReg;
		lo_runParm->break_Flg = lo_runParm->return_Flg = lo_runParm->exit_Flg = false;

	    lo_runParm->maxLine = IndexSiz-2;
	    lo_runParm->Pc = 1;
	    lo_runParm->ThreadId = i_;

		Stack* lo_stk = &(h_stk[i_]);
		lo_stk->MAXSIZE = MAXSIZE_;
		lo_stk->top = -1;

		double* lo_Dmem = &(h_Dmem[DmemSiz * i_]);
		TokenSet* lo_code = &(h_code[2*i_]);

		double* lo_stack = &(h_stack[MAXSIZE_ * i_]);

	    sl_execute(lo_runParm, lo_stk, h_GTbl, h_LTbl, h_Index, h_CodeArr,
					lo_Dmem, h_Gmem, h_nbrLITERAL, lo_code, lo_stack);
	}

	std::cout << "GemeSiz:\t" << GmemSiz << "\n" ;

	for (int i = 0; i < GmemSiz; i++)
	{
		std::cout << i << ":\t" << h_Gmem[i] << '\n';
	}

	delete [] h_Index;
    delete [] h_CodeArr;
    delete [] h_GTbl;
	delete [] h_LTbl;
    delete [] h_Dmem;
	delete [] h_Gmem;
	delete [] h_nbrLITERAL;
    delete [] h_runParm;
}

void sl_run_host_H5(int maxProc)
{
    int IndexSiz, CodeArrSiz, DmemSiz, GmemSiz, nbrSiz;
    int GSiz, LSiz, spReg;

    int *h_Index;
    int *h_CodeArr;
    d_SymTbl *h_GTbl, *h_LTbl;
    double *h_Dmem, *h_Gmem, *h_nbrLITERAL;
    RUN_PARM *h_runParm;

    IndexSiz = (int)Ind.size();
    CodeArrSiz = intercode.size();


    h_Index = new int[IndexSiz];
    h_CodeArr = new int[CodeArrSiz];

    for (int i=0; i < IndexSiz; i++) h_Index[i] = Ind[i];
    for (int i=0; i < CodeArrSiz; i++) h_CodeArr[i] = intercode[i];

    h_runParm = new RUN_PARM[maxProc];

    GSiz = Gtable.size();
    LSiz = Ltable.size();

    h_GTbl = new d_SymTbl[GSiz];
    h_LTbl = new d_SymTbl[LSiz];

    for (int i=0; i<GSiz; i++) {
        h_GTbl[i].nmKind =Gtable[i].nmKind;
        h_GTbl[i].dtTyp	=Gtable[i].dtTyp;
        h_GTbl[i].aryLen =Gtable[i].aryLen;
        h_GTbl[i].args =Gtable[i].args;
        h_GTbl[i].adrs =Gtable[i].adrs;
        h_GTbl[i].frame =Gtable[i].frame;
    }

    for (int i=0; i<LSiz; i++) {
        h_LTbl[i].nmKind =Ltable[i].nmKind;
        h_LTbl[i].dtTyp	=Ltable[i].dtTyp;
        h_LTbl[i].aryLen =Ltable[i].aryLen;
        h_LTbl[i].args =Ltable[i].args;
        h_LTbl[i].adrs =Ltable[i].adrs;
        h_LTbl[i].frame =Ltable[i].frame;
    }

    spReg = Dmem.size();

    int BigFram = 0, SizGTbl = 0;
    SizGTbl = Gtable.size();

    for (int i=0; i < SizGTbl; i++) {
        int Fram = Gtable[i].frame;
        if (BigFram < Fram) BigFram = Fram;
    }

    Dmem.resize(spReg + BigFram + 1);


    DmemSiz = Dmem.size();
    GmemSiz = Gmem.size();
    nbrSiz = nbrLITERAL.size();

    h_Dmem = new double[DmemSiz * maxProc];
    h_Gmem = new double[GmemSiz];
    h_nbrLITERAL = new double[nbrSiz];

    for (int i=0; i< DmemSiz*maxProc; i++) {
		int lo_i = i % DmemSiz;
		h_Dmem[i] = Dmem.get(lo_i);
	}

    for (int i=0; i< GmemSiz; i++) {
		h_Gmem[i] = Gmem.get(i);
	}

    for (int i=0; i< nbrSiz; i++) {
		h_nbrLITERAL[i] = nbrLITERAL[i];
	}

    Stack* h_stk = new Stack[maxProc];

	for (int i=0; i<maxProc; i++) {
	    h_stk[i].MAXSIZE = MAXSIZE_;
	    h_stk[i].top = -1;
	}

    double* h_stack = new double[MAXSIZE_ * maxProc];
    TokenSet* h_code = new TokenSet[2 * maxProc];

	int nProc = omp_get_thread_num();
	if (0 != nProc - 1) nProc -= 1;
	
	omp_set_num_threads( nProc );

	int i_=0;
#pragma omp parallel for private(i_)
	for (i_=0; i_<maxProc; i_++) {

		RUN_PARM* lo_runParm = &(h_runParm[i_]);
		lo_runParm->baseReg = 0;
		lo_runParm->spReg = spReg;
		lo_runParm->break_Flg = lo_runParm->return_Flg = lo_runParm->exit_Flg = false;

	    lo_runParm->maxLine = IndexSiz-2;
	    lo_runParm->Pc = 1;
	    lo_runParm->ThreadId = i_;

		Stack* lo_stk = &(h_stk[i_]);
		lo_stk->MAXSIZE = MAXSIZE_;
		lo_stk->top = -1;

		double* lo_Dmem = &(h_Dmem[DmemSiz * i_]);
		TokenSet* lo_code = &(h_code[2*i_]);

		double* lo_stack = &(h_stack[MAXSIZE_ * i_]);

	    sl_execute(lo_runParm, lo_stk, h_GTbl, h_LTbl, h_Index, h_CodeArr,
					lo_Dmem, h_Gmem, h_nbrLITERAL, lo_code, lo_stack);
	}

	for (int i=0; i < GSiz; i++) {
		if ( Gtable[i].name[0] == '$' && Gtable[i].io == Out ) {
			int aryLen = Gtable[i].aryLen;
			int adrs = Gtable[i].adrs;

			double* dList = new double[aryLen];

			for (int i2=0; i2 < aryLen; i2++) {
				dList[i2] = h_Gmem[adrs + i2];
			}
			string str = Gtable[i].name;
            str.erase(0,1);
			H5Write( str.c_str(), dList, aryLen);

			delete [] dList;
		}
	}

	delete [] h_Index;
    delete [] h_CodeArr;
    delete [] h_GTbl;
	delete [] h_LTbl;
    delete [] h_Dmem;
	delete [] h_Gmem;
	delete [] h_nbrLITERAL;
    delete [] h_runParm;
}

void host_sl_exe(char fn[], int maxProc)
{
    convert_to_internalCode(fn);
    syntaxChk();

	sl_run_host(maxProc);

    intercode.resize(0);
	Ind.resize(0);
	Gtable.resize(0);
	Ltable.resize(0);
	nbrLITERAL.resize(0);
	Dmem.mem.resize(0);
}

void h_sl_exe(char fn[], int maxProc)
{
    convert_to_internalCode(fn);
    syntaxChk();

	sl_run_host_H5(maxProc);
/*
    intercode.resize(0);
	Ind.resize(0);
	Gtable.resize(0);
	Ltable.resize(0);
	nbrLITERAL.resize(0);
	Dmem.mem.resize(0);
*/
}
