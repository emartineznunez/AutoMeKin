#!/bin/bash
cd "$2"/IRC
name="$(sqlite3 inputs.db "select name from gaussian where id=$1")"
if [ "$3" = "g09" ];then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" > ${name}.dat
   g09 <${name}.dat &>${name}.log
   rm ${name}.dat
elif [ "$3" = "g16" ];then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" > ${name}.dat
   g16 <${name}.dat &>${name}.log
   rm ${name}.dat
elif [ "$3" = "qcore" ];then
   DVV_hl.py ${name} &> irc_${name}.log
fi
