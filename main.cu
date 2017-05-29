#include "sl_device.cuh"

#include <iostream>
#include <string>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv)
{
    if (argc <= 1) {
        std::cout << "no option" << std::endl;
        return 0;
    }
    
    bool input = false;
    
    for (int i=1; i < argc; i++) {
        if (!strcmp(argv[i] , "-v") || !strcmp(argv[i] , "-version")) {
            std::cout << "version:\t0.0.1" << std::endl;
            std::cout << "Author:\t\tCCG CORP" << std::endl;
            std::cout << "Email:\t\tcks3443@gmail.com" << std::endl;
        }
        else if (!strcmp(argv[i] ,"-i") || !strcmp(argv[i] , ",")) {
            
            if (!input || !strcmp(argv[i] , ",")) {
                ++i;
                bool isfile = false;
                std::string fn, fn2;
                int arylen = 0;
                IO io = Out;
                fn = argv[i];
                fn2 = fn + ".h5";
                if (access((char*) fn2.c_str(), 0) == 0) isfile = true;
                
                ++i;
                if ( isdigit(argv[i][0]) ) {
                    arylen = atoi(argv[i]);
                } else {
                    std::cout << "aryeln is wrong" << std::endl;
                    return 0;
                }

                if (isfile) {
                    InputDvarYesH5((char *)fn.c_str(), arylen, io);
                }
                else {
                    InputDvarNoH5((char *)fn.c_str(), arylen, io);
                }

                input = true;
            } else {
                std::cout << "no -d or -h" << std::endl;
            }
        }
        else if (!strcmp(argv[i] ,"-d")) {
            if (!input) {
                std::cout << "no -i" << std::endl;
                return 0;
            }
            ++i;
            std::string fn = argv[i];

            int maxProc=0, devId=0;
            
            ++i; 
            if ( isdigit(argv[i][0]) ) {
                devId = atoi(argv[i]);
            } else {
                std::cout << "devId is wrong" << std::endl;
                return 0;
            }
            
            ++i; 
            if ( isdigit(argv[i][0]) ) {
                maxProc = atoi(argv[i]);
            } else {
                std::cout << "maxProc is wrong" << std::endl;
                return 0;
            }
            
            if (access((char *)fn.c_str(), 0) != 0) {
                std::cout << "no " << fn.c_str() << " file" << std::endl;
                return 0;
            }
            
            d_sl_exe((char *)fn.c_str(), devId, maxProc);
            
            //input = false;
        }
        else if (!strcmp(argv[i] ,"-h")) {
            if (!input) {
                std::cout << "no -i" << std::endl;
                return 0;
            }
            ++i;
            std::string fn = argv[i];

            int maxProc = 0;
            
            ++i; 
            if ( isdigit(argv[i][0]) ) {
                maxProc = atoi(argv[i]);
            } else {
                std::cout << "maxProc is wrong" << std::endl;
                return 0;
            }
            
            if (access((char *)fn.c_str(), 0) != 0) {
                std::cout << "no " << fn.c_str() << " file" << std::endl;
                return 0;
            }
            
            h_sl_exe((char *)fn.c_str(), maxProc);
            //input = false;
        }
    }
    
    intercode.clear();
    Ind.clear();
    Gtable.clear();
    Ltable.clear();
    nbrLITERAL.clear();
    Gmem.mem.clear();
    Dmem.mem.clear();
	
    return 0;
}
