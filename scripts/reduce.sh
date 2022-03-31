dir=$1
pre=$2
sed 's/_/ _ /g;s/'$pre'/'$pre' /g' $dir/$pre"list_screened" | awk '/data/{p[1]=$2;getline;p[2]=$1;cnt=2;getline; 
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
++cnt
p[cnt]=$1
for (i=1; i<=cnt; i++) {printf "%8.5f ",p[i]}; print ""
}' > $dir/$pre"list_screened.red" 
