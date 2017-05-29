#include "sl.h"
#include "sl_prot.h"

vector<SymTbl> Gtable;
vector<SymTbl> Ltable;
int startLtable;

int enter(SymTbl& tb, SymKind kind)
{
int n, mem_size;
bool isLocal=is_localName(tb.name, kind);
extern int localAdrs;
extern Mymemory Dmem;
extern Mymemory Gmem;

mem_size=tb.aryLen;

if (mem_size==0) mem_size=1;
if (kind != devId && kind != varId && tb.name[0]=='$')
        {
        err_exit("$ is not used except for variable: ", tb.name);
        }
tb.nmKind=kind;

n=-1;

if (kind == fncId) n=searchName(tb.name, 'G');
if (kind == paraId) n=searchName(tb.name, 'L');
if (n != -1) err_exit("The name is in double: ", tb.name);

if (kind == fncId) tb.adrs=get_lineNo();
else
        {
        if (isLocal)
                {
                tb.adrs=localAdrs;
                localAdrs += mem_size;
                }
        else if (tb.name[0] == '$')
                {
                tb.adrs=Gmem.size();
                Gmem.resize(Gmem.size() + mem_size);
                }
        else
                {
                tb.adrs=Dmem.size();
                Dmem.resize(Dmem.size() + mem_size);
                }
        }
if (isLocal)
        {
        n=Ltable.size();
        Ltable.push_back(tb);
        }
else
        {
        n=Gtable.size();
        Gtable.push_back(tb);
        }
return n;
}

void set_startLtable()
{
startLtable=Ltable.size();
}

bool is_localName(const string& name, SymKind kind)
{
if (kind == paraId) return true;
if (kind == varId)
        {
        if (is_localScope() && name[0] != '$') return true;
        else return false;
        }
return false;
}

int searchName(const string& s, int mode)
{
int n; 
switch (mode)
        {
        case 'G':
                for (n=0; n < (int)Gtable.size(); n++)
                        {
                        if (Gtable[n].name == s) return n;
                        }
                break;
        case 'L':
                for (n=startLtable; n < (int)Ltable.size(); n++)
                        {
                        if (Ltable[n].name == s) return n;
                        }
                break;
        case 'F':
                n=searchName(s,'G');
                if (n != -1 && Gtable[n].nmKind==fncId) return n;
                break;
        case 'V':
                if (searchName(s,'F') != -1) err_exit("This name is already in function: ", s);
                if (s[0] == '$')	return searchName(s, 'G');
                if (is_localScope())	return searchName(s, 'L');
                else			return searchName(s, 'G');
        }
return -1;
}

vector<SymTbl>::iterator tableP(const CodeSet& cd)
{
if (cd.kind == Dvar) return Gtable.begin() + cd.symNbr;
if (cd.kind == Lvar) return Ltable.begin() + cd.symNbr;
return Gtable.begin() + cd.symNbr;
}
