#!/bin/bash
awk '{
if(NR>2 && NF==4) print $1
} ' $1 | sort > tmp 
natom="$(wc -l tmp | awk '{print $1}')"
echo $natom >tmp_for
cat tmp >>tmp_for
awk 'BEGIN{i=1
while(i<=1000){
  nsym[i]=1
  i++
  }
}
{if(NR==1) natom=$1}
{if(NR>1){
  fl=1
  j=1
  while(j<=totsy){
    if($1 == sym[j]) {++nsym[j];fl=0;break}
    j++
    }
  if(fl==1) {++totsy;sym[totsy]=$1}
  }
}
END{
print "natom=",natom
i=1
while(i<=totsy){
  if(nsym[i]>1) nn[i]=sym[i]nsym[i]
  if(nsym[i]==1) nn[i]=sym[i]
  printf "%s",nn[i]
  i++
  }
print ""
}' tmp_for

