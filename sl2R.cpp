#include <sl_device.cuh>
//#include <Rinternals.h>

extern "C" SEXP sl2R(SEXP msg) {
    const char* msg_c = CHAR(asChar(msg));
    Rinterface((char*)msg_c);
    return (R_NilValue);
}

