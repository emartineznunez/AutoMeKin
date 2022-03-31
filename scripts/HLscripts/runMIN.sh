#!/bin/bash

cd $2
#minf
name="$(sqlite3 inputs.db "select name from gaussian where id=$1")"
if [ "$3" = "g09" ]; then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" >${name}.dat
   g09 <${name}.dat &>${name}.log
   t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
   if [ $t -eq 1 ]; then
      echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" | sed 's/calcall,noraman/cartesian,maxcycle=100,calcall,noraman/g' >${name}.dat
      g09 <${name}.dat &> ${name}.log
   fi
   rm ${name}.dat
elif [ "$3" = "g16" ]; then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" >${name}.dat
   g16 <${name}.dat &>${name}.log
   t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
   if [ $t -eq 1 ]; then
      echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" | sed 's/calcall,noraman/cartesian,maxcycle=100,calcall,noraman/g' >${name}.dat
      g16 <${name}.dat &> ${name}.log
   fi
   rm ${name}.dat
elif [ "$3" = "qcore" ]; then
   entos.py ${name}.dat > ${name}.log 2>&1
fi




