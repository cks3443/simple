#include "sl_device.cuh"

extern vector<string> strLITERAL;
extern vector<double> nbrLITERAL;

double* d_gmem = NULL;

void sl_run_device(int devId, int maxProc, int nBlocks, int nThreads, double* host_List)
{
	cudaError_t error = cudaSetDevice(devId);

	if (error != cudaSuccess)
	{
		 printf("cudaSetDevice returned error code %d, line(%d)\n", error, __LINE__);
		 exit(EXIT_FAILURE);
	}


     // get number of SMs on this GPU
     error = cudaGetDevice(&devId);

     if (error != cudaSuccess)
     {
         printf("cudaGetDevice returned error code %d, line(%d)\n", error, __LINE__);
         exit(EXIT_FAILURE);
     }

    int IndexSiz, CodeArrSiz, DmemSiz, GmemSiz, nbrSiz;
    int GSiz, LSiz, spReg;

    int *h_Index, *d_Index;
    int *h_CodeArr, *d_CodeArr;
    d_SymTbl *h_GTbl, *h_LTbl, *d_GTbl, *d_LTbl;
    double *h_Dmem, *h_Gmem, *h_nbrLITERAL, *d_Dmem, *d_Gmem, *d_nbrLITERAL;

    RUN_PARM *d_runParm;

	Stack* d_stk;
	double* d_stack;
	TokenSet* d_code;

    IndexSiz = (int)Ind.size();
    CodeArrSiz = (int)intercode.size();

    h_Index = new int[IndexSiz];
    h_CodeArr = new int[CodeArrSiz];

    for (int i=0; i< IndexSiz; i++) h_Index[i]=Ind[i];

    for (int i=0; i< CodeArrSiz; i++) {
        h_CodeArr[i] = intercode[i];
    }

    if (cudaSuccess != cudaMalloc((void **) &d_Index, sizeof(int)*IndexSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_Index, h_Index, sizeof(int)*IndexSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_CodeArr, sizeof(int)*CodeArrSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_CodeArr, h_CodeArr, sizeof(int)*CodeArrSiz, cudaMemcpyHostToDevice);

    spReg = Dmem.size();

    int BigFram = 0, SizGTbl = 0;
    SizGTbl = Gtable.size();

    for (int i=0; i < SizGTbl; i++) {
        int Fram = Gtable[i].frame;
        if (BigFram < Fram) BigFram = Fram;
    }

    Dmem.resize(spReg + BigFram);

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

    if (cudaSuccess != cudaMalloc((void **) &d_GTbl, sizeof(d_SymTbl)*GSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_GTbl, h_GTbl, sizeof(d_SymTbl)*GSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_LTbl, sizeof(d_SymTbl)*LSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_LTbl, h_LTbl, sizeof(d_SymTbl)*LSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_runParm, sizeof(RUN_PARM)*maxProc))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }

    DmemSiz = Dmem.size();
    GmemSiz = Gmem.size();
    nbrSiz = nbrLITERAL.size();

    h_Dmem = new double[DmemSiz * maxProc];
    h_Gmem = new double[GmemSiz];
    h_nbrLITERAL = new double[nbrSiz+10];

    for (int i=0; i< DmemSiz * maxProc; i++) {
		int lo_i = i % DmemSiz;
		h_Dmem[i] = Dmem.get(lo_i);
	}

    for (int i=0; i< GmemSiz; i++) h_Gmem[i] = Gmem.get(i);
    for (int i=0; i< nbrSiz; i++)  h_nbrLITERAL[i] = nbrLITERAL[i];

    if (cudaSuccess != cudaMalloc(&d_Dmem, sizeof(double)*DmemSiz * maxProc))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_Dmem, h_Dmem, sizeof(double)*DmemSiz * maxProc, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc(&d_Gmem, sizeof(double)*GmemSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_Gmem, h_Gmem, sizeof(double)*GmemSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc(&d_nbrLITERAL, sizeof(double)*nbrSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_nbrLITERAL, h_nbrLITERAL, sizeof(double)*nbrSiz, cudaMemcpyHostToDevice);

	if (cudaSuccess != cudaMalloc((void **) &d_stk, sizeof(Stack) * maxProc))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
	if (cudaSuccess != cudaMalloc((void **) &d_stack, sizeof(double) * MAXSIZE_ * maxProc))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
	if (cudaSuccess != cudaMalloc((void **) &d_code, sizeof(TokenSet) * 2 * maxProc))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }


	int maxLoop = maxProc / (nThreads * nBlocks);

	for (int nloop = 0; nloop < maxLoop + 1; nloop ++)
	{
    	sl_Exe_global<<<nBlocks, nThreads>>>(nloop, nBlocks, nThreads, maxProc, DmemSiz, IndexSiz, spReg,
								d_runParm, d_stk, d_GTbl, d_LTbl, d_Index, d_CodeArr, d_Dmem,
								d_Gmem, d_nbrLITERAL, d_code, d_stack);
	}

    cudaMemcpy(h_Dmem, d_Dmem, sizeof(double)*DmemSiz * maxProc, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_Gmem, d_Gmem, sizeof(double)*GmemSiz, cudaMemcpyDeviceToHost);

		for (int i=0; i<GmemSiz; i++)
		{
				host_List[i] = h_Gmem[i];
		}

	delete [] h_Index;
	cudaFree(d_Index);
	delete [] h_CodeArr;
	cudaFree(d_CodeArr);
	delete [] h_GTbl;
	delete [] h_LTbl;
	cudaFree(d_GTbl);
	cudaFree(d_LTbl);
	delete [] h_Dmem;
	delete [] h_Gmem;
	delete [] h_nbrLITERAL;
	cudaFree(d_Dmem);
	cudaFree(d_Gmem);
	cudaFree(d_nbrLITERAL);

	cudaFree(d_runParm);

	cudaFree(d_stk);
	cudaFree(d_stack);
	cudaFree(d_code);
}

void sl_run_device_H5(int devId, int maxProc, int nBlocks, int nThreads)
{
	//cudaSetDevice(devId);

    int IndexSiz, CodeArrSiz, DmemSiz, GmemSiz, nbrSiz;
    int GSiz, LSiz, spReg;

    int *h_Index, *d_Index;
    int *h_CodeArr, *d_CodeArr;
    d_SymTbl *h_GTbl, *h_LTbl, *d_GTbl, *d_LTbl;
    double *h_Dmem, *h_Gmem, *h_nbrLITERAL, *d_Dmem, *d_Gmem, *d_nbrLITERAL;

    RUN_PARM *d_runParm;

	Stack* d_stk;
	double* d_stack;
	TokenSet* d_code;

    IndexSiz = (int)Ind.size();
    CodeArrSiz = (int)intercode.size();

    h_Index = new int[IndexSiz];
    h_CodeArr = new int[CodeArrSiz];

    for (int i=0; i< IndexSiz; i++) h_Index[i]=Ind[i];

    for (int i=0; i< CodeArrSiz; i++) {
        h_CodeArr[i] = intercode[i];
    }

    //std::cout<<IndexSiz<<std::endl;
    //std::cout << cudaMalloc( &d_Index, sizeof(int)*IndexSiz) << std::endl;
    
    if (cudaSuccess != cudaMalloc((void **) &d_Index, sizeof(int)*IndexSiz))
    {
        std::cout << "Memory Over 1" << std::endl;
        return ;
    }

    cudaMemcpy(d_Index, h_Index, sizeof(int)*IndexSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_CodeArr, sizeof(int)*CodeArrSiz))
    {
        std::cout << "Memory Over 2" << std::endl;
        return;
    }
    cudaMemcpy(d_CodeArr, h_CodeArr, sizeof(int)*CodeArrSiz, cudaMemcpyHostToDevice);

    spReg = Dmem.size();

    int BigFram = 0, SizGTbl = 0;
    SizGTbl = Gtable.size();

    for (int i=0; i < SizGTbl; i++) {
        int Fram = Gtable[i].frame;
        if (BigFram < Fram) BigFram = Fram;
    }

    Dmem.resize(spReg + BigFram);

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

    if (cudaSuccess != cudaMalloc((void **) &d_GTbl, sizeof(d_SymTbl)*GSiz))
    {
        std::cout << "Memory Over 3" << std::endl;
        return;
    }
    cudaMemcpy(d_GTbl, h_GTbl, sizeof(d_SymTbl)*GSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_LTbl, sizeof(d_SymTbl)*LSiz))
    {
        std::cout << "Memory Over 4" << std::endl;
        return;
    }
    cudaMemcpy(d_LTbl, h_LTbl, sizeof(d_SymTbl)*LSiz, cudaMemcpyHostToDevice);

    if (cudaSuccess != cudaMalloc((void **) &d_runParm, sizeof(RUN_PARM)*maxProc))
    {
        std::cout << "Memory Over 5" << std::endl;
        return;
    }

    DmemSiz = Dmem.size();
    GmemSiz = Gmem.size();
    nbrSiz = nbrLITERAL.size();

    h_Dmem = new double[DmemSiz * maxProc];
    //h_Gmem = new double[GmemSiz];
    h_nbrLITERAL = new double[nbrSiz+10];

    for (int i=0; i< DmemSiz * maxProc; i++) {
		int lo_i = i % DmemSiz;
		h_Dmem[i] = Dmem.get(lo_i);
	}

    //for (int i=0; i< GmemSiz; i++) h_Gmem[i] = Gmem.get(i);
    for (int i=0; i< nbrSiz; i++)  h_nbrLITERAL[i] = nbrLITERAL[i];

    if (cudaSuccess != cudaMalloc(&d_Dmem, sizeof(double)*DmemSiz * maxProc))
    {
        std::cout << "Memory Over 6" << std::endl;
        return;
    }
    cudaMemcpy(d_Dmem, h_Dmem, sizeof(double)*DmemSiz * maxProc, cudaMemcpyHostToDevice);
/*
    if (cudaSuccess != cudaMalloc(&d_Gmem, sizeof(double)*GmemSiz))
    {
        std::cout << "Memory Over 7" << std::endl;
        return;
    }
    cudaMemcpy(d_Gmem, h_Gmem, sizeof(double)*GmemSiz, cudaMemcpyHostToDevice);
*/
    if (cudaSuccess != cudaMalloc(&d_nbrLITERAL, sizeof(double)*nbrSiz))
    {
        std::cout << "Memory Over 8" << std::endl;
        return;
    }
    cudaMemcpy(d_nbrLITERAL, h_nbrLITERAL, sizeof(double)*nbrSiz, cudaMemcpyHostToDevice);

	if (cudaSuccess != cudaMalloc((void **) &d_stk, sizeof(Stack) * maxProc))
    {
        std::cout << "Memory Over 9" << std::endl;
        return;
    }
	if (cudaSuccess != cudaMalloc((void **) &d_stack, sizeof(double) * MAXSIZE_ * maxProc))
    {
        std::cout << "Memory Over 10" << std::endl;
        return;
    }
	if (cudaSuccess != cudaMalloc((void **) &d_code, sizeof(TokenSet) * 2 * maxProc))
    {
        std::cout << "Memory Over 11" << std::endl;
        return;
    }


	int maxLoop = maxProc / (nThreads * nBlocks);

	for (int nloop = 0; nloop < maxLoop + 1; nloop ++)
	{
    	sl_Exe_global<<<nBlocks, nThreads>>>(nloop, nBlocks, nThreads, maxProc, DmemSiz, IndexSiz, spReg,
								d_runParm, d_stk, d_GTbl, d_LTbl, d_Index, d_CodeArr, d_Dmem,
								d_gmem, d_nbrLITERAL, d_code, d_stack);
	}

    //cudaMemcpy(h_Dmem, d_Dmem, sizeof(double)*DmemSiz * maxProc, cudaMemcpyDeviceToHost);
    //cudaMemcpy(h_Gmem, d_Gmem, sizeof(double)*GmemSiz, cudaMemcpyDeviceToHost);
/*
	for (int i=0; i < GmemSiz; i++)
    {
        Gmem.set(i, h_Gmem[i]);
        //std::cout<<Gmem.get(i)<<endl;
	}
*/
	delete [] h_Index;
	cudaFree(d_Index);
	delete [] h_CodeArr;
	cudaFree(d_CodeArr);
	delete [] h_GTbl;
	delete [] h_LTbl;
	cudaFree(d_GTbl);
	cudaFree(d_LTbl);
	delete [] h_Dmem;
//	delete [] h_Gmem;
	delete [] h_nbrLITERAL;
	cudaFree(d_Dmem);
//	cudaFree(d_Gmem);
	cudaFree(d_nbrLITERAL);

	cudaFree(d_runParm);

	cudaFree(d_stk);
	cudaFree(d_stack);
	cudaFree(d_code);
}

void sl_Print_h5(string& nm)
{
    int GSiz = Gtable.size();
    //std::string nm = name_;
    bool isin = false;

	for (int i=0; i < GSiz; i++)
    {
        string nm_g = Gtable[i].name;
        nm_g.erase(0,1);

		if ( nm_g == nm ) {
            isin = true;
			int aryLen = Gtable[i].aryLen;
			int adrs = Gtable[i].adrs;

			double* dList = new double[aryLen];

			for (int i2=0; i2 < aryLen; i2++) {
				dList[i2] = Gmem.get(adrs + i2);
			}
			H5Write( nm.c_str(), dList, aryLen);

			delete [] dList;
            break;
		}
	}

    if (isin == false) cout << "no file" << endl;
}


int InputDvar(char* name_, int aryLen_, double* Lists, IO io_)
{
	SymTbl sym;

	if (name_[0] == '$') {
		sym.name = name_;
	}
	else {
		string pre = "$";
		string p_nm = pre + name_;
		sym.name = p_nm;
	}
	sym.nmKind = devId;
	sym.dtTyp = DBL_T;
	sym.aryLen = aryLen_;
	sym.adrs = Gmem.size();
	sym.io = io_;

	Gtable.push_back(sym);

	int index = Gmem.mem.size();

	for (int i=0; i < aryLen_; i++) {
		Gmem.mem.push_back(Lists[i]);
	}

	return index;
}


void device_sl_exe(char fn[], int devId, int maxProc, double* host_List)
{
    cudaSetDevice(devId);
    convert_to_internalCode(fn);
    syntaxChk();

    int  nBlocks, nThreads;
    nBlocks = 65535 ;
    
    cudaDeviceSetLimit(cudaLimitStackSize, 60*1024);
	cudaDeviceProp devProp;
	cudaGetDeviceProperties(&devProp, devId);

	nThreads = (int)(devProp.maxThreadsPerBlock / 2);

	sl_run_device(devId, maxProc, nBlocks, nThreads, host_List);
	
    intercode.resize(0);
	Ind.resize(0);
	Gtable.resize(0);
	Ltable.resize(0);
	nbrLITERAL.resize(0);
	Dmem.mem.resize(0);
}

void device_sl_syntax_check(char fn[])
{
	convert_to_internalCode(fn);
	syntaxChk();
}

void H5Write(const char* FILE, double* data, int NX)
{
	char* DATASETNAME = "data";
	int RANK = 1;

	hid_t       file, dataset;
    hid_t       datatype, dataspace;
    hsize_t     dimsf[RANK];
    herr_t      status;
    int         rows;
    int         i;


    rows = NX;

	string str1 = FILE;
	string str2 = str1 + ".h5";

    file = H5Fcreate(str2.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    dimsf[0] = NX;

    dataspace = H5Screate_simple(RANK, dimsf, NULL);

    datatype = H5Tcopy(H5T_NATIVE_DOUBLE);
    status = H5Tset_order(datatype, H5T_ORDER_LE);

    dataset = H5Dcreate(file, DATASETNAME, datatype, dataspace,
			H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    status = H5Dwrite(dataset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL,
		      H5P_DEFAULT, data);

    H5Sclose(dataspace);
    H5Tclose(datatype);
    H5Dclose(dataset);
    H5Fclose(file);
}

void H5Read(const char* FILE, double* data, int rows)
{
	char* DATASETNAME = "data";

    hid_t       file, dataset;
    hid_t       datatype, dataspace;
    H5T_class_t class_h5;
    H5T_order_t order;
    size_t      size;
    hsize_t     dims_out[1];
    herr_t      status;
    int          i, status_n, rank;

	string str = FILE;
	string str2 = str + ".h5";

    file = H5Fopen(str2.c_str(), H5F_ACC_RDONLY, H5P_DEFAULT);
    dataset = H5Dopen1(file, DATASETNAME);

    datatype  = H5Dget_type(dataset);
    class_h5     = H5Tget_class(datatype);
    if (class_h5 == H5T_INTEGER) printf("Data set has INTEGER type \n");
    order     = H5Tget_order(datatype);
    //if (order == H5T_ORDER_LE) printf("Little endian order \n");

    size  = H5Tget_size(datatype);

    dataspace = H5Dget_space(dataset);    // dataspace handle
    rank      = H5Sget_simple_extent_ndims(dataspace);
    status_n  = H5Sget_simple_extent_dims(dataspace, dims_out, NULL);

    rows = dims_out[0];

    status = H5Dread(dataset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);

    // Close/release resources
    H5Tclose(datatype);
    H5Dclose(dataset);
    H5Sclose(dataspace);
    H5Fclose(file);
}

void InputDvarNoH5(char* name_, int aryLen_, IO io_)
{
	SymTbl sym;

	if (name_[0] == '$') {
		sym.name = name_;
	}
	else {
		string pre = "$";
		string p_nm = pre + name_;
		sym.name = p_nm;
	}
	sym.nmKind = devId;
	sym.dtTyp = DBL_T;
	sym.aryLen = aryLen_;
	sym.adrs = Gmem.size();
	sym.io = io_;

	Gtable.push_back(sym);

	double* dList = new double[aryLen_];

	for (int i=0; i < aryLen_; i++) {
		dList[i] = 0.;
		Gmem.mem.push_back(dList[i]);
	}
	string fn = sym.name;
	H5Write(name_, dList, aryLen_);

	delete [] dList;
}

void InputDvarYesH5(char* name_, int aryLen_, IO io_)
{
	SymTbl sym;
    string nm;

	if (name_[0] == '$') {
		nm = name_;
	}
	else {
		string pre = "$";
		string p_nm = pre + name_;
		nm = p_nm;
	}

    bool isin = false;

    int sizG = Gtable.size();
    for (int i=0; i < sizG; i++) {
        if (Gtable[i].name == nm) {

            isin = true;
            if (Gtable[i].aryLen == aryLen_) {
                double* dList = new double[aryLen_];
                string fn = Gtable[i].name ;
                H5Read(name_, dList, aryLen_);

                int adrs = Gtable[i].adrs;
                
                for (int i=0; i < aryLen_; i++) {
                    Gmem.mem[adrs + i] = dList[i];
                }

                delete [] dList;
            } 
            else {
                std::cout << "Not match array size" << std::endl;
            }

            
            break;
        }
    }

    if (isin == false) {

        sym.name = nm;
        sym.nmKind = devId;
        sym.dtTyp = DBL_T;
        sym.aryLen = aryLen_;
        sym.adrs = Gmem.size();
        sym.io = io_;

        Gtable.push_back(sym);

        double* dList = new double[aryLen_];
        string fn = sym.name ;
        H5Read(name_, dList, aryLen_);

        double add_step = 0.;
        for (int i=0; i < aryLen_; i++) {
            Gmem.mem.push_back(dList[i]);
        }

        delete [] dList;
    }
}

void loadcode(char fn[])
{
    /*if (access(fn), 0) != 0) {
        std::cout << "no " << fn << " file" << std::endl;
        return 0;
    }*/
    convert_to_internalCode(fn);
    syntaxChk();
}

void d_sl_exe(int devId, int maxProc)
{
    cudaSetDevice(devId);
    //convert_to_internalCode(fn);
    //syntaxChk();

    int  nBlocks, nThreads;
    nBlocks = 65535 ;

    cudaDeviceSetLimit(cudaLimitStackSize, 60*1024);
    cudaDeviceProp devProp;
    cudaGetDeviceProperties(&devProp, devId);

    nThreads = (int)(devProp.maxThreadsPerBlock / 2);

    sl_run_device_H5(devId, maxProc, nBlocks, nThreads);
}

void create_(char* name_, int NList, double *dList)
{
	SymTbl sym;
    string nm;

	if (name_[0] == '$') {
		nm = name_;
	}
	else {
		string pre = "$";
		string p_nm = pre + name_;
		nm = p_nm;
	}

    sym.name = nm;
    sym.nmKind = devId;
    sym.dtTyp = DBL_T;
    sym.aryLen = NList;
    sym.adrs = Gmem.size();
    sym.io = Out;

    Gtable.push_back(sym);

    for (int i=0; i < NList; i++) {
        Gmem.mem.push_back(dList[i]);
    }
}

void update_(char* name_, int NList, double *dList)
{
    if (d_gmem != NULL) {
        cpymemDeviceToHost();
        cudaFree(d_gmem);
    }

    SymTbl sym;
    string nm;

    if (name_[0] == '$') {
        nm = name_;
    }
    else {
        string pre = "$";
        string p_nm = pre + name_;
        nm = p_nm;
    }

    int sizG = Gtable.size();
    for (int i=0; i < sizG; i++) {
        if (Gtable[i].name == nm) {

            if (Gtable[i].aryLen == NList) {

                int adrs = Gtable[i].adrs;

                for (int i=0; i < NList; i++) {
                    Gmem.mem[adrs + i] = dList[i];
                }

            }
            else {
                std::cout << "Not match array size" << std::endl;
            }

            break;
        }
    }

    cpymemHostToDevice();

}

int get_length(char* name_)
{
    SymTbl sym;
    string nm;

    if (name_[0] == '$') {
        nm = name_;
    }
    else {
        string pre = "$";
        string p_nm = pre + name_;
        nm = p_nm;
    }

    int size = 0;

    int sizG = Gtable.size();
    for (int i=0; i < sizG; i++) {
        if (Gtable[i].name == nm) {

            size = Gtable[i].aryLen;

            break;
        }
    }
    return size;
}

void get_(char* name_, double *dList)
{
//    cpymemDeviceToHost();

    SymTbl sym;
    string nm;

    if (name_[0] == '$') {
        nm = name_;
    }
    else {
        string pre = "$";
        string p_nm = pre + name_;
        nm = p_nm;
    }

    int sizG = Gtable.size();
    for (int i=0; i < sizG; i++) {

        if (Gtable[i].name == nm) {
            int adrs = Gtable[i].adrs;
            int NList = Gtable[i].aryLen;

            for (int i=0; i < NList; i++) {
                dList[i] = Gmem.mem[adrs + i];
            }

            break;
        }
    }
}

void cpymemHostToDevice()
{
    int gSiz = Gmem.mem.size();

    double* h_Gmem = new double[gSiz];

    for (int i=0; i< gSiz; i++) h_Gmem[i] = Gmem.get(i);

    if (cudaSuccess != cudaMalloc(&d_gmem, sizeof(double)*gSiz))
    {
        std::cout << "Memory Over" << std::endl;
        return;
    }
    cudaMemcpy(d_gmem, h_Gmem, sizeof(double)*gSiz, cudaMemcpyHostToDevice);

    delete [] h_Gmem;
}

void cpymemDeviceToHost()
{
    int gSiz = Gmem.mem.size();

    double* h_Gmem = new double[gSiz];

    cudaMemcpy(h_Gmem, d_gmem, sizeof(double)*gSiz, cudaMemcpyDeviceToHost);

    for (int i=0; i < gSiz; i++) Gmem.set(i, h_Gmem[i]);

    delete [] h_Gmem;
}

void end_()
{
    cudaFree(d_gmem);

    intercode.clear();
    Ind.clear();
    Gtable.clear();
    Ltable.clear();
    nbrLITERAL.clear();
    strLITERAL.clear();
    Gmem.mem.clear();
    Dmem.mem.clear();
}
