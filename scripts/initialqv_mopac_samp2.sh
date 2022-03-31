file=$1
energy=$2
nlms=$3
lstnm=$4
thmass=$5
awk '/Empirical Formula/{natom=$(NF-1)}
/                             CARTESIAN COORDINATES/{
print natom
getline
i=1
while(i<=natom){
 getline
 print $2,$3,$4,$5
 i++ 
}
print '$energy'
print '$nlms'
if('$nlms'>0) print '$lstnm'
print '$thmass'
}' $file
