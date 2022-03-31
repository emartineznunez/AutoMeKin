f=$1
e=$2
f1=$3
f2=$4
f3=$5
f4=$6
file=$7
prog=$8
awk 'BEGIN{ok=-1;el='$e';ff[-1]=10;ff[0]=10;ff[1]=20;ff[2]=10;det[-1]=0.0001;det[0]=0.0001;det[1]=0.2;det[2]=0.0001}
{
nfeq=0
df=$4-'$f'
de=$5-el
df2=$7-'$f2'
df3=$8-'$f3'
df4=$9-'$f4'
df=sqrt(df*df)
de=sqrt(de*de)
df2=sqrt(df2*df2)
df3=sqrt(df3*df3)
df4=sqrt(df4*df4)
if(df <ff['$prog']) ++nfeq
if(df2<ff['$prog']) ++nfeq
if(df3<ff['$prog']) ++nfeq
if(df4<ff['$prog']) ++nfeq
if(de<=det['$prog'] && nfeq==4 ) {ok=$2}
}
END{
print ok
}' $file
