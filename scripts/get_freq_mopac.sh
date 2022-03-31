file=$1
awk '/Empirical Formula/{natom=$(NF-1)}
/ORIENTATION OF MOLECULE IN FORCE CALCULATION/{
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
 i++ 
}

if(natom==2 || diff <0.001 ) 
  nlin=1
else
  nlin=0
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
#  for(inf=1;inf<=NF;++inf) print sqrt($inf*$inf)
  for(inf=1;inf<=NF;++inf) print $inf
  nfreq=NF
  getline
  i=1
  while(i<=3*natom){
   getline
   ++i
   }
 ++itimes
 }
}' $file
