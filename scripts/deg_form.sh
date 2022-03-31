#!/bin/bash
sharedir=${AMK}/share

elements=${sharedir}/elements

awk '{if( NR == FNR)  {l[NR]=$1;tne=NR }}
{if(NR>FNR) {
IGNORECASE = 1
i=1
while(i<=tne){
  if( $1 == l[i]) {++n[i];d[i,n[i]]=$2}
  i++
  }
 }
}
END{
i=1
while(i<=105){
  if(n[i]>0) {
     for (j=1; j<=100; j++) a[j]=0
     for (j=1; j<=n[i]; j++) a[j]=d[i,j]
     print "Atom= ",i,n[i] 
     if(n[i]==1) print d[i,1]
     nn = asort(a,b)
     for (ii=1; ii<=nn; ii++){
     if(n[i]>1 && b[ii]>0) print b[ii]
     }
  }
  i++
  }
}' $elements deg.out
