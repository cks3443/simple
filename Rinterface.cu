#include "sl_device.cuh"

#include <iostream>
#include <string>
#include <stdio.h>
#include <unistd.h>
#include <cctype>
#include <cstring>

using namespace std;

void Rinterface(char* msg)
{

    //string cmd = msg;
    
    vector<string> cmd_v;

    //char *ptr = strtok((char *)cmd.c_str(), " ");
    char *ptr = strtok(msg, " ");

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

    if (cmd_v[0] == stop) {
        intercode.resize(0);
        Ind.resize(0);
        Gtable.resize(0);
        Ltable.resize(0);
        nbrLITERAL.resize(0);
        Gmem.mem.resize(0);
        Dmem.mem.resize(0);
        //break;
    }
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
            return ;
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
            return ;
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
