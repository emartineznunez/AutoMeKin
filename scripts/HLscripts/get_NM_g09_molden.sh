#!/bin/bash
sharedir=${AMK}/share
elements2=${sharedir}/elements2

echo "[Molden Format]" > $2.molden
echo "[FREQ]"         >> $2.molden
##echo the freqs here
get_freq_g09.sh $1 | awk '{printf "%6.1f\n",$1}' >> $2.molden
echo "       " >> $2.molden
echo "[FR-COORD]" >> $2.molden


awk 'BEGIN{huge=10000;ifreq=0;atobohr=1.889726}
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
   getline;getline;getline;getline
   j=1
   while(j<=natom) {
     getline
     iatom=$1
     for(inf=3;inf<=NF;++inf) {i=int(inf/3);k=inf-3*i-2;nfreq=3*ifreq-3+i;nm[3*iatom+k,nfreq]=$inf}
     j++
     }
}
END{
n=1
while(n<=natom){
 print l[nl[n]],atobohr*x[n],atobohr*y[n],atobohr*z[n]  >>  "'$2'.molden"
 ++n
 }
print "" >> "'$2'.molden"
print "[FR-NORM-COORD]" >> "'$2'.molden"
i=1
while(i<=nfreq){
 print "Vibration "i >> "'$2.molden'"
   j=1
   while (j<=natom) {
   print nm[3*j-2,i]*atobohr,nm[3*j-1,i]*atobohr,nm[3*j,i]*atobohr >> "'$2'.molden"
   ++j
   }
 ++i
 }
}' $elements2 $1 




