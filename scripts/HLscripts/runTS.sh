#!/bin/bash
cd "$2"
name="$(sqlite3 inputs.db "select name from gaussian where id=$1")"
inp="$(sqlite3 inputs.db "select input from gaussian where id=$1")"
echo -e "$inp\n\n" > ${name}.dat
if [ "$inp" != "salir" ]; then
   if [ "$3" = "g09" ];then
      g09 <${name}.dat &>${name}.log
      t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
      if [ $t -eq 1 ]; then
      #Constructing new input file (cartesian opt)
        echo -e "$inp\n\n" | sed 's/calcfc/cartesian,maxcycle=100,calcfc/;s/calcall/cartesian,maxcycle=100,calcall/' > ${name}.dat
        g09 <${name}.dat &> ${name}.log
      fi
      t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
      if [ $t -eq 1 ]; then
      #Constructing new input file (cartesian nosymm)
        echo -e "$inp\n\n" | sed 's/calcfc,noraman)/cartesian,maxcycle=100,calcfc,noraman) nosymm/;s/calcall,noraman)/cartesian,maxcycle=100,calcall,noraman) nosymm/' > ${name}.dat
        g09 <${name}.dat &> ${name}.log
      fi
   elif [ "$3" = "g16" ];then
      g16 <${name}.dat &>${name}.log
      t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
      if [ $t -eq 1 ]; then
      #Constructing new input file (cartesian opt)
        echo -e "$inp\n\n" | sed 's/calcfc/cartesian,maxcycle=100,calcfc/;s/calcall/cartesian,maxcycle=100,calcall/' > ${name}.dat
        g16 <${name}.dat &> ${name}.log
      fi
      t=$(awk 'BEGIN{t=0};/Error termination via/{t=1};END{print t}' ${name}.log)
      if [ $t -eq 1 ]; then
      #Constructing new input file (cartesian nosymm)
        echo -e "$inp\n\n" | sed 's/calcfc,noraman)/cartesian,maxcycle=100,calcfc,noraman) nosymm/;s/calcall,noraman)/cartesian,maxcycle=100,calcall,noraman) nosymm/' > ${name}.dat
        g16 <${name}.dat &> ${name}.log
      fi
   elif [ "$3" = "qcore" ];then
      entos.py ${name}.dat > ${name}.log 2>&1
   fi
fi
