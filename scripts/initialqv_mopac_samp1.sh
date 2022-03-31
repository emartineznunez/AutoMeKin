file=$1
seed=$2
energy=$3
nlms=$4
lstnm=$5
awk 'BEGIN{print '$seed'}
/Empirical Formula/{natom=$(NF-1)}
/ORIENTATION OF MOLECULE IN FORCE CALCULATION/{
print natom
getline
getline
getline
i=1
while(i<=natom){
 getline
 x[i]=$3;y[i]=$4;z[i]=$5
 if(i>1) {
   dx=x[i]-x[i-1]
   dy=y[i]-y[i-1]
   dz=z[i]-z[i-1]
   mod=sqrt(dx*dx+dy*dy+dz*dz)
   ddx[i]=dx/mod;ddy[i]=dy/mod;ddz[i]=dz/mod
 }
 if(i>2) {
   prod=ddx[i]*ddx[i-1]+ddy[i]*ddy[i-1]+ddz[i]*ddz[i-1] 
   sp[i]=sqrt( prod*prod )
   sump+=sp[i]
   diff=natom-2-sump
 }
 print $2,x[i],y[i],z[i]
 i++ 
}

if(natom==2 || diff <0.001 ) 
  nlin=1
else
  nlin=0
print nlin
print '$energy'
print '$nlms'
if('$nlms'>0) print '$lstnm'
ntimes=int((3*natom-6)/8+1)
}
/NORMAL COORDINATE ANALYSIS/{
itimes=1
while(itimes<=ntimes){
  i=1
  while(i<=7){
    getline
    ++i
    }
  print $0
  nfreq=NF
  getline
  i=1
  while(i<=3*natom){
   getline
   if(NF==(nfreq+1) ) print $0
   if(NF>(nfreq+1) ) print $3,$4,$5,$6,$7,$8,$9,$10,$11
   ++i
   }
 ++itimes
 }
}' $file
