#!/bin/bash
source utils.sh

if [ -f amk.dat ];then
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
cwd=$PWD
exe="tsll_view.sh"

#reading input
read_input
###

###view tslist file
if [ -f ${tslistll} ]; then
   printf "  ts #     File name     w_imag      Energy     w1     w2     w3     w4 traj #   Folder\n"
   printf "  ----  ---------------  ------      ------   ----   ----   ----   ---- ------   ------\n"
   awk '{printf "%6s%17s %6.0fi %11s %6.0f %6.0f %6.0f %6.0f   %4s %8s\n",$2,$3,$4,$5,$6,$7,$8,$9,$11,$13}' ${tsdirll}/tslist
else
   echo "Sorry, no TSs found so far"
fi
###

