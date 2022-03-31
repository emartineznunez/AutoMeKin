#!/bin/bash
source utils.sh

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
exe=$(basename $0)
cwd=$PWD

#reading input
read_input
###

if [ ! -d "$bu_ts" ]; then
   echo "Folder $bu_ts does not exist"
   echo "Have you already run irc.sh?"
   exit
fi

rm -rf ${tsdirll}/DIS* ${tsdirll}/REP*
cp ${bu_ts}/* ${tsdirll}
##
irc.sh screening
echo "Exiting $exe"

