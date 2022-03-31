#!/bin/bash
source utils.sh

sharedir=${AMK}/share
cwd=$PWD
inputfile='amk.dat'

awk '{print $0}' $1 > tmp_file
awk 'BEGIN{print "Labels"};NF==4{print $1}' $1 > labels
file=tmp_file
##
read_input
##
elements=${sharedir}/elements

createMat.py $file 1 $nA

echo "1 $natom" | cat - ConnMat | cat - ConnMat | sprint2.exe > tmp_spo

nfrag="$(awk '/Results for the Laplacian/{getline; nconn=0
   for(i=6;i<=8;i++) if($i<='${nfrag_th}') {++nconn} ; print nconn}' tmp_spo)"

echo "$nfrag" >tmp_nf

##############   
awk '/Natom/{natom=$2};/Adjacency matrix/{getline
i=1
while(i<=natom){
  for(j=1;j<=natom;j++) {
   if(i==j) 
     el=1
   else
     el=$j
   printf "%s ",el }
  printf "\n"
  getline
  i++
  }
}' tmp_spo >tmp_ddf

for i in $(seq 1 10)
do
   ((j=i-1))
   output="$(awk '{for(i=1;i<=NF;i++) {v[NR,i]=$i;if($i>0) {++l[NR];ik[NR,l[NR]]=i}}}
   END{
   j=1
   code=0
   idum=0
   while(j<=NF){
     k=1
     while(k<=l[j]){
       for(i=1;i<=NF;i++) v[j,i]=v[j,i]+v[ik[j,k],i]
       k++
       }
     i=1
     while(i<=NF){
       if(i>j) ++idum
       iexp=NF*(NF-1)-idum
       if(v[j,i]>1) v[j,i]=1
       code+=v[j,i]^iexp
       i++
       }
     for(i=1;i<=NF;i++) {printf "%2.0f ",v[j,i]};print ""
     j++
     }
   print code > "tmp_code"'$i'
   }' tmp_ddf)"
   code[$i]=$(awk '{print $1 }' tmp_code$i)
   if [ -f tmp_code$j ]; then
      if [ ${code[$i]} -eq  ${code[$j]} ] ;then
        break
      fi
   fi
   echo "$output"> tmp_ddf
done

awk '{for(i=1;i<=NF;i++) {if($i>0) printf "%3.0f ",i};print ""
}' tmp_ddf | awk '{for(i=1;i<=NF;i++) {noanr[NR]=NF;v[NR,i]=$i}} 
END{
print "number of fragments=",'$nfrag'
i=1
while(i<=NR){
  j=1
  p=1
  while(j<=i-1){
    if(v[i,1]==v[j,1]) p=0
    j++
    }  
  if(p==1) ++nn
  if(p==1 && nn<'$nfrag') {print "Number of atoms of this fragment=",noanr[i]
  for(j=1;j<=noanr[i];j++) {printf "%3.0f ",v[i,j]};print "" }
  i++
  }
}' >tmp_fp
##############   

awk '/Natom/{natom=$2;print natom}
/Adja/{getline
while(i<=natom){
  if(NF==natom) print $0
  getline
  i++
  }
}' tmp_spo >tmp_01
   
cat tmp_01 labels tmp_fp >tmp_02

awk '{if(NR == FNR) {z[NR]=NR;l[NR]=$1;n[NR]=NR/10+1;tne=NR}}
{if(NR>FNR && FNR==1) natom=$1}
{if(NR>FNR && NF==natom)  {
  ++i
  for(j=1;j<=natom;j++)  a[i,j]=$j
  }
}
/of atoms/{
++nf
nat=$7
noa[nf]=nat
getline
for(j=1;j<=nat;j++) {at[nf,j]=$j}
}
/Labels/{
i=1
while(i<=natom) {
   getline
   IGNORECASE = 1
   j=1
   while(j<=tne){
     if($1 == l[j]) z[i]=j 
     j++  
     } 
     print i,$1,z[i],n[z[i]]
   i++
   }
}
END{
for(inf=1;inf<=nf;inf++){
for(j=1;j<=noa[inf];j++){
  kk=1 
  while(kk<=natom) {
     sum+=n[z[at[inf,j]]]*a[at[inf,j],kk]*n[z[kk]]
     kk++
     }
  }
}
  print "Code=",sum*'$nfrag'
} ' $elements tmp_02 >>tmp_fp

awk 'BEGIN{nrfh=1d20}
/number of fragments/{nfrag=$4}
/Number of atoms of this fragment/{++i;natom[i]=$7;getline
for(j=1;j<=NF;j++) at[i,j]=$j
nrfh=NR
}
{
if(NR>nrfh) {
k=1
while(k<=1000){
   pr=1
   if($1== "Code=") break
   l=1
   while(l<=nfrag-1){
     m=1
     while(m<=natom[l]){
       if($1 == at[l,m]) pr=0
       m++
       }
     l++
     }
   if(pr==1) {++natom[nfrag];at[nfrag,natom[nfrag]]=$1}
   k++
   getline
   }
 }
}
END{
i=1
while(i<=nfrag){
  j=1
  while(j<=natom[i]){
    print at[i,j] > "tmp_Frag"i
    j++
    }
  i++
  }
}' tmp_fp
rm -f tmp_frag
for i in $(seq 1 $nfrag)
do
   wc -l tmp_Frag$i | awk '{print $1}' > tmp_frag$i.xyz
   echo "" >> tmp_frag$i.xyz
   cat tmp_Frag$i > tmp
   echo "break" >>tmp
   cat $file >> tmp 
   awk '/break/{fl=1}
   {if(fl==0) {++n;at[n]=$1}}
   {if(fl==1 && NF==4) {
     ++nat
     j=1
     while(j<=n){
       if(nat==at[j]) print $0
       j++
       }
     }
   }' tmp >> tmp_frag$i.xyz
   chemical_formula.sh tmp_frag$i.xyz >tmp_frag$i.log
   cat tmp_frag$i.log >>tmp_frag
done

awk '/natom=/{natom=$2;getline;print natom,$1}' tmp_frag | sort -n | awk '{f[NR]=$2} 
END{
i=1
while(i<=NR){
  if(i<NR) printf "%s + ",f[i]
  if(i==NR) printf "%s",f[i]
  i++
  }
print ""
}' 

rm -f ConnMat labels ScalMat fort.*
