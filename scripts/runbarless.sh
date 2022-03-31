#!/bin/bash
## This script is invoked as:
##doparallel "runGP.sh {1} $molecule $cwd $nojf $nchan" "$(seq $noj1 $nojf)"
##The first job is the tors scan
batchn=$1
batch=batch$batchn
#Make batch directory
if [ -d ${batch} ]; then  rm -r ${batch} ; fi
mkdir ${batch}
#copy neccesary files.
cp amk.dat $2.xyz ${batch}
echo "tsdirll $3/tsdirLL_$2"  >> ${batch}/amk.dat
cd ${batch} && LocateTs.py amk.dat $((batchn-1)) 0 $4 > amk.log
