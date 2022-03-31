nlines=$(wc -l $1 | awk '{print $1}')
echo $2
awk 'NR==1{print $1"\n"'$nlines'/($1 + 2)}
NF==1{n=$1;getline;for(i=1;i<=n;i++) {getline;print $1,$2,$3,$4} }' $1 
