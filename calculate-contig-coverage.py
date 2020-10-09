#!/usr/bin/env python
#####################################################
## cite from https://github.com/ngs-docs/2017-ci   ##
## cese-metagenomics/blob/master/files/calculate   ##
## -contig-coverage.py                             ##
#####################################################
"""
@author: halexand 
"""
import pandas as pd
import sys
def calc_cov(infile):
        df=pd.read_table(infile, header=None, index_col=0)
        df.columns=['depth', 'numbase', 'lens', 'fraction']
        df['coverage']=(df.depth * df.numbase )/df.lens
        out=df.groupby(level=0).sum().coverage
        out=out.drop('genome')
        out.to_csv(infile+'.coverage.tab', header = False, sep='\t')

if __name__ == "__main__":
        infile=sys.argv[1]
        calc_cov(infile)
