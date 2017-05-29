#ifndef SL_H
#define SL_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <stack>

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <cctype>

using namespace std;

#define LIN_SIZ 255
#define ADDREG 512

enum TknKind {
    Lparen='(',
    Rparen=')',
    Lbracket='[',
    Rbracket=']',
    Plus='+',
    Minus='-',
    Multi='*',
    Divi='/',
    Mod='%',
    Not='!',
    Ifsub='?',
    Assign='=',
    IntDivi='\\',
    Comma=',',
    DblQ='"',
    Func=150,
    Var, If, Elif, Else, For, To, Step, While,
    End, Break, Return, Option, Input, Toint,
    Exit, Equal, NotEq, Less, LessEq, Great, GreatEq, And, Or,
    Ident, IntNum, DblNum, String, Letter, Doll, Digit,
    Gvar, Lvar, Dvar, Fcall, EofProg, EofLine, Others,
    EXP, LOG, PID, Print, Println, SumAssign, MinusAssign, MultiAssign, DiviAssign, END_KeyList = 300
};

struct Token
{
	TknKind kind;
	string text;
	double dblVal;

	Token() { kind=Others; text=""; dblVal=0.; }
	Token(TknKind k) {kind=k; text=""; dblVal=0.; }
	Token(TknKind k, double d) {kind=k; text=""; dblVal=d; }
	Token(TknKind k, const string& s) { kind=k; text=s; dblVal=0.; }
	Token(TknKind k, const string& s, double d) { kind=k; text=s; dblVal=d; }
};

enum SymKind
{
	noId,
	varId,
	fncId,
	paraId,
	devId
};

enum IO {
    In=1, Out
};

enum DtType {NON_T, DBL_T};

struct SymTbl {
    string name;
    SymKind nmKind;
    int dtTyp;
    int aryLen;
    short args;
    int adrs;
    int frame;
    IO io;

    SymTbl(){clear();}
    void clear() {
        name=""; nmKind=noId; dtTyp=NON_T;
        aryLen=0; args=0; adrs=0; frame=0;
    }
};

struct d_SymTbl {
    SymKind nmKind;
    int dtTyp;
    int aryLen;
    short args;
    int adrs;
    int frame;
};

struct CodeSet
{
	TknKind kind;
	const char* text;
	double dblVal;
	int symNbr;
	int jmpAdrs;

	CodeSet() {clear();}
	CodeSet(TknKind k) {clear(); kind=k; }
	CodeSet(TknKind k, double d) { clear(); kind=k; dblVal=d;}
	CodeSet(TknKind k, const char* s) {clear(); kind=k; text=s; }
	CodeSet(TknKind k, int sym, int jmp) { clear(); kind=k; symNbr=sym; jmpAdrs=jmp; }

	void clear()
	{
        kind=Others;
        text="";
        dblVal=0.;
        jmpAdrs=0;
        symNbr=0;
	}
};

struct Tobj
{
	char type;
	double d;
	string s;

	Tobj() {type='-'; d=0.; s=""; }
	Tobj(double dt) { type='d'; d=dt; s=""; }
	Tobj(const string& st) { type='s'; d=0.; s=st; }
	Tobj(const char* st) { type='s'; d=0.; s=st; }
};

class Mymemory 
{
public:
    vector<double> mem;

public:
    void set(int adrs, double dt) { mem[adrs] = dt; }
    void add(int adrs, double dt) { mem[adrs] += dt; }
    double get(int adrs) { return mem[adrs]; }
    int size() {return (int)mem.size(); }
    void resize(unsigned int n) { mem.resize(n); }
};

class Mystack 
{
private:
    int MAXSIZE;
    double stack[30];
    int top;

public:
    Mystack() {
        MAXSIZE=30;
        top=-1;
    }

    ~Mystack() {}

    bool isfull() {
        if (top == MAXSIZE) return true;
        else return false;
    }

    bool empty() {
        if (top == -1) return true;
        else  return false;
    }

    void push(double data)
    {
        if (!isfull()) {
            top = top + 1;
            stack[top]=data;
        }
    }

    double pop()
    {
        double data;

        if (!empty()) {
            data = stack[top];
            top=top-1;
            return data;
        }

        return 0.;
    }
};

#endif
