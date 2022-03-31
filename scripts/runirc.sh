#!/bin/bash
name="$(sqlite3 $2/inputs.db "select name from mopac where id=$1")"
if [ "$3" != "qcore" ]; then
   mopac ${2}/TSs/${name}_thermo.mop 2>/dev/null
   mopac ${2}/IRC/${name}_ircf.mop   2>/dev/null
   mopac ${2}/IRC/${name}_ircr.mop   2>/dev/null
else
   entos.py ${2}/TSs/${name}_thermo.dat > ${2}/TSs/${name}_thermo.out
   DVV.py ${2}/IRC/${name} > ${2}/IRC/${name}_ircf.out
   cp ${2}/IRC/${name}_ircf.out ${2}/IRC/${name}_ircr.out
fi
