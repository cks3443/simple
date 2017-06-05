#include "sl_device.cuh"

#include <iostream>
#include <string>
#include <stdio.h>
#include <unistd.h>
#include <cctype>
#include <cstring>

using namespace std;

int main(int argc, char** argv)
{
    if (argc == 1) {

        while (true) {
            string cmd;
            
            cout << ": ";
            getline(cin, cmd);

            vector<string> cmd_v;

            char *ptr = strtok((char *)cmd.c_str(), " ");

            while (ptr != NULL)
            {
                string str = ptr;
                cmd_v.push_back(str);
                ptr = strtok(NULL, " ");
            }

            string stop = "-q";
            string inp = "-i";
            string r_device = "-d";
            string r_host = "-h";
            string print = "-p";

            if (cmd_v[0] == stop) break;
            else if (cmd_v[0] == inp) {
                int i = 0;
                ++i;
                bool isfile = false;
                char* stop;
                std::string fn, fn2;
                unsigned int arylen = 0;
                IO io = Out;
                fn = cmd_v[i];
                fn2 = fn + ".h5";
                if (access((char*) fn2.c_str(), 0) == 0) isfile = true;
                
                ++i;
                
                arylen = (unsigned int)strtod(cmd_v[i].c_str(), &stop);

                if (isfile) {
                    InputDvarYesH5((char *)fn.c_str(), arylen, io);
                }
                else {
                    InputDvarNoH5((char *)fn.c_str(), arylen, io);
                }
            }
            else if (cmd_v[0] == r_device) {

                int i=0;
                ++i;
                std::string fn = cmd_v[i];

                unsigned int maxProc=0, devId=0;
                char* stop;
                
                ++i; 
                devId = (unsigned int)strtod(cmd_v[i].c_str(), &stop);
                
                ++i; 
                maxProc = (unsigned int)strtod(cmd_v[i].c_str(), &stop);
                
                if (access((char *)fn.c_str(), 0) != 0) {
                    std::cout << "no " << fn.c_str() << " file" << std::endl;
                    return 0;
                }
                
                d_sl_exe((char *)fn.c_str(), devId, maxProc);
            }
            else if (cmd_v[0] == r_host) {

                int i=0;
                ++i;
                std::string fn = cmd_v[i];

                unsigned int maxProc=0;
                char* stop;
                
                ++i; 
                maxProc = (unsigned int)strtod(cmd_v[i].c_str(), &stop);
                
                if (access((char *)fn.c_str(), 0) != 0) {
                    std::cout << "no " << fn.c_str() << " file" << std::endl;
                    return 0;
                }
                
                h_sl_exe((char *)fn.c_str(), maxProc);
            }
            else if (cmd_v[0] == print) {
                int i = 0;
                ++i;
                string nm = cmd_v[i];
                sl_Print_h5(nm);
            }
        }
        //end while
    }
    else {
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
                    char* stop;
                    std::string fn, fn2;
                    unsigned int arylen = 0;
                    IO io = Out;
                    fn = argv[i];
                    fn2 = fn + ".h5";
                    if (access((char*) fn2.c_str(), 0) == 0) isfile = true;
                    
                    ++i;
                    if ( isdigit(argv[i][0]) ) {
                        arylen = (unsigned int)strtod(argv[i], &stop);
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

                unsigned int maxProc=0, devId=0;
                char* stop;
                
                ++i; 
                if ( isdigit(argv[i][0]) ) {
                    devId = (unsigned int)strtod(argv[i], &stop);
                } else {
                    std::cout << "devId is wrong" << std::endl;
                    return 0;
                }
                
                ++i; 
                if ( isdigit(argv[i][0]) ) {
                    maxProc = (unsigned int)strtod(argv[i], &stop);
                } else {
                    std::cout << "maxProc is wrong" << std::endl;
                    return 0;
                }
                
                if (access((char *)fn.c_str(), 0) != 0) {
                    std::cout << "no " << fn.c_str() << " file" << std::endl;
                    return 0;
                }
                
                d_sl_exe((char *)fn.c_str(), devId, maxProc);
                
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
