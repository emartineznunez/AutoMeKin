#!/bin/bash
name="$(sqlite3 $2/IRC/inputs.db "select name from mopac where id=$1")"
if [ "$3" != "qcore" ]; then
   mopac ${2}/IRC/minf_${name}.mop 2>/dev/null
   mopac ${2}/IRC/minr_${name}.mop 2>/dev/null
else
   entos.py ${2}/IRC/${name}_forward_last_opt.dat > ${2}/IRC/${name}_forward_last_opt.out
   entos.py ${2}/IRC/${name}_reverse_last_opt.dat > ${2}/IRC/${name}_reverse_last_opt.out

   entos.py ${2}/IRC/minf_${name}.dat > ${2}/IRC/minf_${name}.out
   cat ${2}/IRC/${name}_forward_last_opt.xyz >> ${2}/IRC/minf_${name}.out 
   echo "== QCORE DONE ==" >> ${2}/IRC/minf_${name}.out

   entos.py ${2}/IRC/minr_${name}.dat > ${2}/IRC/minr_${name}.out
   cat ${2}/IRC/${name}_reverse_last_opt.xyz >> ${2}/IRC/minr_${name}.out 
   echo "== QCORE DONE ==" >> ${2}/IRC/minr_${name}.out
fi

