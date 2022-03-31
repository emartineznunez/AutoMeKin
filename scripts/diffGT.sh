file=$1
dir=$2
pre=$3
avgerr=$4
bigerr=$5
awk '{
its[NR]=int($1)
nn=NF-2
for (i=2; i<=NF-1; i++) {a[its[NR],i-1]=$i}
if(NR>1) {
  i=1
  while(i<=NR-1) {
    err=0
    bigerr=0
    for (ii=1; ii<=nn; ii++) {
       ref=a[its[i],ii]
       val=a[its[NR],ii]
       if(ref==0.000)  {ref=10;val=val+10}

       dif=val-ref
       dum2=dif*dif
       diff=sqrt(dum2)

       relerr=diff/sqrt(ref*ref)*100

       err+=dum2
       if(relerr>bigerr) bigerr=relerr
       }
#      print its[i],its[NR],err/nn,bigerr > "All_differences"
    if( (err/nn) <'$avgerr' && bigerr <'$bigerr') {
      print its[i],its[NR],err/nn,bigerr
      print its[NR] > "black_list.dat"
      }
    i++
    }
  }
}' $file > $dir/$pre"list_screened.lowdiffs"
if [ -f "black_list.dat" ]; then
   awk '{n[NR]=$1
   i=1
   nrmone=NR-1
   lp=1
   while(i<=nrmone){
     if(n[i]==n[NR]) lp=0
     i++ 
     }
   if(lp==1) print n[NR]
   }' black_list.dat >black_list.out
   cat black_list.out > $dir/$pre"list_repeated"
   cat black_list.out $file | awk '{
   if(NF==1) { 
    a[NR]=$1
    nt=NR}
   else {
     i=1
     p=1
     while(i<=nt) {
       if(int($1)==a[i]) p=0
       ++i
       }
     if(p==1) print $0
     }
   }'  > $dir/$pre"list_screened.log"
else
#  echo "No repetitions"
  cp $file $dir/$pre"list_screened.log"
fi
