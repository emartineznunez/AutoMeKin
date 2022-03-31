dir=$1
pre=$2
sed 's/_/ _ /g;s/'$pre'/'$pre' /g;s/-/ /g' $dir/$pre"list_screened" | awk '/data/{p[1]=$2;cnt=1;++cnt;p[cnt]=$4;getline
n=$1
i=1
while(i<=n) {
 getline
 ++cnt
 p[cnt]=$1
 m=$2
 j=1
 while(j<=m) {
   ++cnt
   p[cnt]=$(2+j)
   j++
   }
 i++
 }
getline
sc=$1
 getline
 k=1
 while(k<=sc){
   ++cnt
   p[cnt]=$k
   k++
   }
getline
getline
k=1
while(k<=sc){
  ++cnt
  p[cnt]=$k
  k++
  }
printf "%6.3f %20s ",p[1],p[2];for (i=3; i<=cnt; i++) {printf "%6.3f ",p[i]}; print ""
}' > $dir/$pre"list_screened.red" 
