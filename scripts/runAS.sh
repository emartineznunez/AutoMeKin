#!/bin/bash
if [ "$3" = "mopac" ]; then
   mopac ${2}/assoc${1}.mop 2>/dev/null
elif [ "$3" = "qcore" ]; then
   entos.py ${2}/assoc${1}.qcore > ${2}/assoc${1}.out 2>&1 
   if [ -f ${2}/assoc${1}_opt.xyz ]; then
      cat ${2}/assoc${1}_opt.xyz >> ${2}/assoc${1}.out 
   else
      echo Error >> ${2}/assoc${1}.out 
   fi
fi


