#include "sl_device.cuh"
#include <Rinternals.h>

extern "C" {
    SEXP RUN(SEXP msg) {
        const char* msg_c = CHAR(asChar(msg));
        Rinterface((char*)msg_c);
        return (R_NilValue);
    }

    SEXP CREATE(SEXP NM, SEXP Rvec) {
        
        const char* nm = CHAR(asChar(NM));
        int NList = length(Rvec);
        double *dList = REAL(Rvec);

        create_((char*)nm, NList, dList);
        return (R_NilValue);
    }

    
    SEXP UPDATE(SEXP NM, SEXP Rvec) {
        
        const char* nm = CHAR(asChar(NM));
        int NList = length(Rvec);
        double *dList = REAL(Rvec);
        
        update_((char*)nm, NList, dList);
        return (R_NilValue);
    }

    SEXP GET(SEXP NM) {
        
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
