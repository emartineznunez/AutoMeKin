#!/bin/bash
sharedir=${AMK}/share
elements=${sharedir}/elements

awk 'BEGIN{huge=1000000}
{if( NR == FNR) l[NR]=$1}
/orientation:/{ getline
getline
getline
getline
i=1
while(i<=huge){
  getline
  if(NF==1) break
  if(NF==6 && $4=="NaN") break
  if(NF==6 && $4~/Inf/) break
  if(NF==6) n[i]=$2
  if(NF==6) x[i]=$4
  if(NF==6) y[i]=$5
  if(NF==6) z[i]=$6
  natom=i
  i++
  }
}
END{
i=1
while(i<=natom){
  print l[n[i]],x[i],y[i],z[i]
  i++
  }
print ""
}' $elements $1

