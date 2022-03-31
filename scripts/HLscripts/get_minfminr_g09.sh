#!/bin/bash
sharedir=${AMK}/share
source utils.sh
#On exit remove tmp files
tmp_files=(tmp*)
trap 'err_report $LINENO' ERR
trap cleanup2 EXIT INT

exe=$(basename $0)
cwd=$PWD
inputfile=amk.dat
##reading HL stuff
read_input
##get_geom of last irc point
i=$1
get_geom_irc


calc=min_irc
if [ "$program_hl" = "g16" ]; then
   g09_input
else
   ${program_hl}_input
fi

