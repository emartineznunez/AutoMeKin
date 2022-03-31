#!/bin/bash
sharedir=${AMK}/share
elements=${sharedir}/elements

file=$1
awk '{if (NR == FNR) {l[NR]=$1;tne=NR}}
{if(NR > FNR && FNR==1) print $0}
{IGNORECASE = 1}
{if(NR > FNR && FNR>1) {
    i=1
    while(i<=tne){
      if( $1 == l[i]) print i,$2,$3,$4  
      i++
      }
  }
}' $elements $file >symm.dat

symm0.exe <symm.dat > tmp_symm
cont=$(awk 'BEGIN{cont=1};/No more calc/{cont=0};END{print cont}' tmp_symm )

if [ $cont -eq 1 ]; then  symm.exe <symm.dat>> tmp_symm ; fi
