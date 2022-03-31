#!/bin/bash
#Script to view the sqlite3 databases
exe=$(basename $0)
if [ $# -ne 4 ] || [ $1 == "-h" ]; then
   echo "Please provide four arguments:"
   echo "+++++++++++++++++++++++++++++++"
   echo "$exe FINALDIR property table label"
   echo ""
   echo "FINALDIR-->(folder containing FINAL results)"
   echo "property-->(natom,energy,zpe,g,geom,freq,formula(only for prod),all)"
   echo "table   -->(ts, min or prod)"
   echo "label   -->(the numbers shown in RXNet)"
   echo ""
   echo "Example to select the geometry of the first ts calculated at low level(LL):"
   echo ""
   echo "select.sh FINAL_LL_FA geom ts 1"
   echo ""
   exit 1
fi 
FINALDIR=$1
if [ ! -d "$FINALDIR" ]; then 
   echo "$FINALDIR does not exist" 
   exit 1
fi
#LL or HL calc??
#ct=$(echo $PWD | awk 'BEGIN{ct=-1};/FINAL_LL/{ct=0};/FINAL_HL/{ct=1};END{print ct}' )
ct=$(echo $FINALDIR | awk 'BEGIN{ct=-1};/FINAL_LL/{ct=0};/FINAL_HL/{ct=1};END{print ct}' )
if [ $ct -eq 0 ]; then
   units="kcal/mol"
elif [ $ct -eq 1 ]; then
   units="Eh"
elif [ $ct -eq -1 ]; then
   echo "Specify a valid name for FINALDIR"
   exit
fi

property=$2
##If the user puts the extension remove it
table0=$(echo $3 | sed 's@.db@@g')
table=${FINALDIR}/$table0
##
label=$4
if [ $table0 == "min" ]; then
   id="MIN"$label
   col=name
elif [ $table0 == "ts" ]; then
   id="TS"$label
   col=name
elif [ $table0 == "prod" ]; then
   id=$label
   col=id
fi 
if [ $property == "all" ]; then
   if [ $table0 == "min" ] || [ $table0 == "ts" ]; then
      #This is for ts and min
      sqlite3 ${table}.db "select * from $table0 where $col='$id'" | sed 's@|@ change\n@g' | awk 'BEGIN{col[1]="id=";col[2]="natom=";col[3]="name=";col[5]="energy (in '$units')=";col[6]="ZPE (in kcal/mol)=";col[7]="G (in '$units')=";col[8]="geom"};
{if($2=="change"){
      ++i;if(i!=4) print col[i],$1
      if(i==7) print "Geometry"}
      else if($5=="change") {
        print $1,$2,$3,$4
        print "Vibrational frequencies (in cm-1)"}
      else
        print $0}'
   elif [ $table0 == "prod" ]; then
      #This is for prod
      sqlite3 ${table}.db "select * from $table0 where $col='$id'" | sed 's@|@ change\n@g' | awk 'BEGIN{col[1]="id=";col[2]="natom=";col[3]="name=";col[4]="energy (in '$units')=";col[5]="ZPE (in kcal/mol)=";col[6]="G (in '$units')=";col[7]="formula"};
{if($2=="change"){
      ++i;if(i<7)print col[i],$1
      if(i==7){print $1; print col[i]}
      if(i==6) print "Geometry"}
      else if($5=="change") {
        print $1,$2,$3,$4
        print "Vibrational frequencies (in cm-1)"}
      else
        print $0}' | sed 's@_min@ @;s@PR@PROD@' | awk '{
      if($1=="name=")
        print $1,$2
      else
        print $0}'
   fi
else
   res="$(sqlite3 ${table}.db "select $property from $table0 where $col='$id'")"
   if [ $table0 == "prod" ] && [ $property == "name" ]; then
      echo "$res" | sed 's@_min@ @;s@PR@PROD@' | awk '{print $1}'
   else
      if [ $property == "zpe" ]; then
         echo "$res" kcal/mol
      elif [ $property == "energy" ] || [ $property == 'g' ]; then
         echo "$res" $units 
      else
         echo "$res"
      fi
   fi
fi
