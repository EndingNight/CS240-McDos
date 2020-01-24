#!/usr/bin/python3

import sys
import re

opcode_table = {'add':['m', 1,'3/4', '18'],
                'addf':['m', 1, '3/4', '58'],
                'addr':['r', 2, '2', '90'],
                'and':['m', 1,'3/4', '40'],
                'clear':['r', 1, '2', 'B4'],
                'comp':['m',1,'3/4', '28'],
                'compf':['m',1,'3/4', '88'],
                'compr':['r',2,'2','A0'],
                'div':['m',1,'3/4','24'],
                'divf':['m',1,'3/4','64'],
                'divr':['r',1,'2','9C'],
                'fix':[None,0,'1','C4'],
                'float':[None,0,'1','C0'],
                'hio':[None,0,'1','F4'],
                'j':['m',1,'3/4','3C'],
                'jeq':['m',1,'3/4','30'],
                'jgt':['m',1,'3/4','34'],
                'jlt':['m',1,'3/4','38'],
                'jsub':['m',1,'3/4','48'],
                'lda':['m',1,'3/4','00'],
                'ldb':['m',1,'3/4','68'],
                'ldch':['m',1,'3/4','50'],
                'ldf':['m',1,'3/4','70'],
                'ldl':['m',1,'3/4','08'],
                'lds':['m',1,'3/4','6C'],
                'ldt':['m',1,'3/4','74'],
                'ldx':['m',1,'3/4','04'],
                'lps':['m',1,'3/4','D0'],
                'mul':['m',1,'3/4','20'],
                'mulf':['m',1,'3/4','60'],
                'mulr':['r',2,'2','98'],
                'norm':[None,0,'1','C8'],
                'or':['m',1,'3/4','44'],
                'rd':['m',1,'3/4','D8'],
                'rmo':['r',2,'2','AC'],
                'rsub':[None,0,'3/4','4C'],
                'shiftl':['r/n',2,'2','A4'],
                'shiftr':['r/n',2,'2','A8'],
                'sio':[None,0,'1','F0'],
                'ssk':['m',1,'3/4','EC'],
                'sta':['m',1,'3/4','0C'],
                'stb':['m',1,'3/4','78'],
                'stch':['m',1,'3/4','54'],
                'stf':['m',1,'3/4', '80'],
                'sti':['m',1,'3/4','D4'],
                'stl':['m',1,'3/4','14'],
                'sts':['m',1,'3/4','7C'],
                'stsw':['m',1,'3/4','E8'],
                'stt':['m',1,'3/4','84'],
                'stx':['m',1,'3/4','10'],
                'sub':['m',1,'3/4','1C'],
                'subf':['m',1,'3/4','5C'],
                'subr':['r',2,'2','94'],
                'svc':['n',1,'2','B0'],
                'td':['m',1,'3/4','E0'],
                'tio':[None,0, '1', 'F8'],
                'tix':['m',1, '3/4', '2C'],
                'tixr':['r',1, '2', 'B8'],
                'wd':['m',1, '3/4', 'DC']}

#### NOTES #####

# to convert from hex, do int('hex_num', 16)
# to convert to hex, do hex(int_num)



###############

class Line:
    ''' A class for each line read from the input source code '''

    #constructor
    def __init__(self, orig, label=None,mnemonic=None,comment=None):
        self.orig = orig
        self.label = label
        self.mnemonic = mnemonic
        self.comment = comment

    def __str__(self):
        return self.orig


def parse_asm(line):
    orig = line
    

def main():
    ''' The main function '''
    print(sys.argv[1])
    f = open(sys.argv[1])
    for line in f:
        print(line)
        break


if __name__ == "__main__":
    main()