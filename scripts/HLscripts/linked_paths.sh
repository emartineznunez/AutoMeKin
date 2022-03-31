#!/bin/bash
echo $2 > tmp_0
nlm_old=1
for i in $(seq 1 10)
do
   awk '{if(NF==1) {m[NR]=$1;k=NR}}
   {if($10=="MIN" && $5<'$3'){n=k
     for(i=1;i<=n;i++){
       if( $8==m[i] ) {ok=1;for(j=1;j<=n;j++) if($11==m[j]) ok=0; if(ok==1) {++k;m[k]=$11}}
       if($11==m[i] ) {ok=1;for(j=1;j<=n;j++) if($8==m[j]) ok=0; if(ok==1) {++k;m[k]=$8}}
       }
     }
   }
   END{n=k;for(i=1;i<=n;i++) print m[i]}' tmp_$((i-1)) $1 > tmp_$i
   nlm_new=$(wc -l tmp_$i | awk '{print $1}')
   if [ $nlm_new -eq $nlm_old ]; then
      break
   else
      nlm_old=$nlm_new
   fi
done
cat tmp_$i $1 |  awk '{if(NF==1) {m[NR]=$1;n=NR}}
NF>1{++nol; if(nol<=2) print $0
  if(nol>2){
    for(i=1;i<=n;i++){
      if($8==m[i] && $5<'$3') {print $0;break}
      if($10=="MIN" && $11==m[i] && $5<'$3') {print $0;break}
      }
  }
}'
