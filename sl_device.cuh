#ifndef SL_DEVICE_CUH
#define SL_DEVICE_CUH

#include <omp.h>
#include <stdlib.h>

#include "sl.h"
#include "sl_prot.h"
#include "sl_run.cuh"
#include "hdf5.h"

#include "R.h"
#include "Rdefines.h"
#include "Rinternals.h"

extern vector<int> intercode;
extern vector<int> Ind;

extern vector<SymTbl> Gtable;
extern vector<SymTbl> Ltable;
extern Mymemory Dmem;
extern Mymemory Gmem;
extern vector<double> nbrLITERAL;

void sl_run_device(int devId, int maxProc, int nBlocks, int nThreads, double* host_List);

int InputDvar(char* name_, int aryLen_, double* Lists, IO io_);

void device_sl_exe(char fn[], int devId, int maxProc, double* host_List);

void device_sl_syntax_check(char fn[]);

void sl_run_host(int maxProc);

void host_sl_exe(char fn[], int maxProc);

void H5Write(const char* FILE, double* data, int NX);

void H5Read(const char* FILE, double* data, int rows);

void InputDvarNoH5(char* name_, int aryLen_, IO io_);

void InputDvarYesH5(char* name_, int aryLen_, IO io_);

void sl_run_device_H5(int devId, int maxProc, int nBlocks, int nThreads);

void sl_Print_h5(string& nm);

void sl_run_host_H5(int maxProc);

void d_sl_exe(char fn[], int devId, int maxProc);

void h_sl_exe(char fn[], int maxProc);

void Rinterface(char* msg);

extern "C" {
    SEXP sl2R(SEXP msg) ;
}

#endif
