#include "sl_device.cuh"
#include <Rinternals.h>

extern double* d_gmem;

extern "C" {
    SEXP sl_run(SEXP msg) {
        const char* msg_c = CHAR(asChar(msg));
        Rinterface((char*)msg_c);
        return (R_NilValue);
    }
    
    SEXP sl_device(SEXP d_id, SEXP maxProc) {
        int _id = asInteger(d_id);
        unsigned int _max = (unsigned int)(asReal(maxProc));
        //printf("_id:\t %d", _id);
        //printf("_max:\t %d", _max);
        d_sl_exe(_id, _max);
        return (R_NilValue);
    }
    
    SEXP sl_host(SEXP maxProc) {
        //int _id = asInteger(d_id);
        unsigned int _max = (unsigned int)(asReal(maxProc));
        h_sl_exe(_max);
        return (R_NilValue);
    }
    
    SEXP cpyMemHostToDevice() {
        cpymemHostToDevice();
        return (R_NilValue);
    }
    
    SEXP cpyMemDeviceToHost() {
        cpymemDeviceToHost();
        return (R_NilValue);
    }
    
    SEXP sl_lc(SEXP msg) {
        const char* msg_c = CHAR(asChar(msg));
        loadcode((char*)msg_c);
        return (R_NilValue);
    }
    
    SEXP sl_end() {
        end_();
        return (R_NilValue);
    }

    SEXP sl_create(SEXP NM, SEXP Rvec) {
        
        const char* nm = CHAR(asChar(NM));
        int NList = length(Rvec);
        double *dList = REAL(Rvec);

        create_((char*)nm, NList, dList);
        return (R_NilValue);
    }

    
    SEXP sl_update(SEXP NM, SEXP Rvec) {
        
        const char* nm = CHAR(asChar(NM));
        int NList = length(Rvec);
        double *dList = REAL(Rvec);
        
        update_((char*)nm, NList, dList);
        return (R_NilValue);
    }

    SEXP sl_get(SEXP NM) {
        
        const char* nm = CHAR(asChar(NM));
        int NList = get_length((char*)nm);
        SEXP Rvec;
        PROTECT(Rvec = allocVector(REALSXP, NList));
        double *dList = REAL(Rvec);
        
        get_((char*) nm, dList);
        UNPROTECT(1);

        return Rvec;
    }
}
