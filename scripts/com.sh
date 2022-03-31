#!/bin/bash
source utils.sh
sharedir=${AMK}/share
elements2=${sharedir}/elements2
#On exit remove tmp files

awk 'NR==FNR{m[$1]=$2}
NR>FNR{
at[FNR]=$1;x[FNR]=$2;y[FNR]=$3;z[FNR]=$4;natom=FNR
xcom+=m[$1]*$2
ycom+=m[$1]*$3
zcom+=m[$1]*$4
mtot+=m[$1]
}
END{
for(i=1;i<=natom;i++) printf "%s %12.6f %12.6f %12.6f\n",at[i],x[i]-xcom/mtot,y[i]-ycom/mtot,z[i]-zcom/mtot
}' $elements2 tmp_geom
