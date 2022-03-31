#!/bin/bash

file=$1
nA=$3
natom=$(awk 'BEGIN{n=0};{if(NF==4) ++n};END{print n}' $file )
echo $natom > mingeom_$file
echo '' >> mingeom_$file
awk '{if(NF==4) print $0 }' $file >> mingeom_$file 
echo "1" $natom > sprint.dat
createMat.py mingeom_$file 1 $nA
cat ConnMat >> sprint.dat
cat ConnMat >> sprint.dat
sprint2.exe <sprint.dat >sprint.out

paste <(awk 'NF==4{print $1}' mingeom_$file) <(deg.sh) >deg.out

deg_form.sh > deg_form.out
##
echo "This is a just to see if there is more than one fragment" > tmp_data
#
format.sh tmp $PWD $2 

rm -f mingeom_$file

awk '{ndis=$1};END{print ndis}' tmp_data 
