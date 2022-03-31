file=$1
tight=$3
##MOPAC
if [ $2 -eq 1 ]; then
   awk 'BEGIN{zero=0}
   /Empirical Formula/{natom=$7;natmone=natom-1}
   /FINAL HEAT OF FORMATION =/{e=$6;f=-4}
   /MASS-WEIGHTED COORDINATE ANALYSIS/{
   getline; getline; getline; getline; getline; getline; getline;
   imagf=$1
   f=sqrt(imagf*imagf)
   for(i=2;i<=5;i++) fr[i-1]=$i
   if ('$tight' == 1) { 
      if(fr[1]<0) 
         f=-1
      else if(fr[1]+fr[2]<10) 
         f=-2 }
   if(imagf>0) f=-3
   }
   END{
   if(f==0) f=zero
   if(e==0) {e=zero;f=-4}
   print f,e,fr[1],fr[2],fr[3],fr[4]}' $file
##GAUSSIAN
elif [ $2 -eq 2 ]; then
   awk 'BEGIN{zero=0}
   NR==1{ e=$1}
   NR>1{++i;freq[i]=$1}
   END{imagf=freq[1]
   f=sqrt(imagf*imagf)
   if ('$tight' == 1) { 
      if(freq[2]<0) 
         f=-1
      else if(freq[2]+freq[3]<10) 
         f=-2 }
   if(imagf>0) f=-3
   if(f==0) f=zero
   if(e==0) {e=zero;f=-4}
   print f,e,freq[2],freq[3],freq[4],freq[5]}' tmp_gauss
##QCORE
elif [ $2 -eq 0 ] || [ $2 -eq -1 ]; then
   awk 'BEGIN{zero=0}
   /Energy=/{e=$2;f=-4}
   /Freq/{getline; imagf=$1
   f=sqrt(imagf*imagf)
   for(i=1;i<=4;i++) {getline;fr[i]=$1}
   if ('$tight' == 1) { 
      if(fr[1]<0) 
         f=-1
      else if(fr[1]+fr[2]<10) 
         f=-2 }
   if(imagf>0) f=-3
   }
   END{
   if(f==0) f=zero
   if(e==0) {e=zero;f=-4}
   print f,e,fr[1],fr[2],fr[3],fr[4]}' $file
fi

