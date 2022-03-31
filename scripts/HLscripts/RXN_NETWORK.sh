#!/bin/bash
# ci is a flag to determine the conformational isomers (if ci==1 calculate them).
exe=$(basename $0)
if [ $# -eq 0 ]; then
  ci=1
else
  if [ $1 == "allstates" ];then
     ci=2
  elif [ $1 == "modify" ]; then
     ci=0
  else
     echo "Run the script as:"
     echo "$exe RXNet_opt"
     echo "where RXNet_opt can be:"
     echo "allstates: the RXNet is constructed including all minima (not grouped by conformational isomers)"
     echo "modify: this allows you to modify the conformational isomers after a first run of $exe"
     echo "Without RXNet_opt, $exe will construct the RXNet with each set of conformational isomers forming a single state"
     exit
  fi
fi

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi

echo "Running IRC_ANALYSIS.sh"
IRC_ANALYSIS.sh 
echo "Running SORT.sh"
SORT.sh
echo "Running RXN_NETWORK1.sh"
RXN_NETWORK1.sh $ci
echo "Running IDENTIFYPROD.sh"
IDENTIFYPROD.sh
