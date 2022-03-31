#!/bin/bash
sharedir=${AMK}/share
elements=${sharedir}/elements

awk 'BEGIN{huge=1000000}
{if( NR == FNR) l[NR]=$1}
/orientation:/{ getline
if($1~"---") {
   getline
   getline
   getline
   i=1
   while(i<=huge){
     getline
     if(NF==1) break
     n[i]=$2
     x[i]=$4
     y[i]=$5
     z[i]=$6
     natom=i
     i++
     }
   }
}
END{
i=1
while(i<=natom){
  print l[n[i]],x[i],y[i],z[i]
  i++
  }
}' $elements $1

