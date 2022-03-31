name=$1
dir=$2
th=$3
awk '{
if ($1== "Atom=") {
   ++j
   an[j]=$2
   n[j]=$3
   lc=0
 }
 else {
   ++lc
   deg[an[j],lc]=$1
 }
}
END{
#print "Degree of each vertex"
#print "Number of different verteces=",j
print j
i=1
while(i<=j){
  printf "%3.0f %3.0f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f\n",an[i],n[i],deg[an[i],1],deg[an[i],2],
  deg[an[i],3],deg[an[i],4],
  deg[an[i],5],deg[an[i],6],
  deg[an[i],7],deg[an[i],8],
  deg[an[i],9],deg[an[i],10],
  deg[an[i],11],deg[an[i],12],
  deg[an[i],13],deg[an[i],14],
  deg[an[i],15],deg[an[i],16],
  deg[an[i],17],deg[an[i],18],
  deg[an[i],19],deg[an[i],20]
  ++i
  }
}' deg_form.out >> ${dir}/${name}"_data"
awk '/Sprint coordinates ordered/{
#print "Number of Sprint coordinates=",NF-3
print NF-3
for (i=4; i<=NF; i++) {printf "%6.3f ",$i}; print ""
} 
/Results for the Laplacian/{
getline
nconn=0
for(i=6;i<=NF;i++) if($i<='$th') {++nconn;printf "%s ",$i > "tmp_ELs" }
print nconn
}' sprint.out >> ${dir}/${name}"_data"



