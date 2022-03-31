#!/bin/bash
sharedir=${AMK}/share

elements2=${sharedir}/elements2

#Script to get the displaced structure in cartesian coordinates corresponding to the imaginary freqency in the direction indicated by sign (1 or -1)
# it is employed in MINandPROD_1.sh to generate guess input files for the minima when the IRC has only one step
file=$1
sign=$2
awk 'BEGIN{huge=10000}
{if( NR == FNR) {l[NR]=$1;m[NR]=$2}}
/Coordinates/{getline
getline
i=1
natom=0
while(i<=huge){
  getline
  if(NF==6)  ++natom
  if(NF==6)  nl[natom]=$2
  if(NF==6)  x[natom]=$4
  if(NF==6)  y[natom]=$5
  if(NF==6)  z[natom]=$6
  if(NF==1)  break
  ++i
  }
}
/Frequencies/{++ifreq;
if(ifreq==1) {
   getline;getline;getline;getline
   j=1
   while(j<=natom) {
     getline
     print $3,$4,$5
     j++
     }
   }
}
END{
n=1
while(n<=natom){
 print l[nl[n]],x[n],y[n],z[n]
 ++n
 }
}' $elements2 $file | awk '{if(NF==3) { 
  ++i
  dx[i]='$sign'*$1
  dy[i]='$sign'*$2
  dz[i]='$sign'*$3
  }
}
{
natom=i
if(NF==4){++j
  printf "%3s %15.8f %15.8f %15.8f\n",$1,$2+dx[j],$3+dy[j],$4+dz[j]
  }
}
END{
print ""
}'  




