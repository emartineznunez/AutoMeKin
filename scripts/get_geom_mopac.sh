file=$1
awk 'BEGIN{err=1;huge=10e5}
/FINAL HEAT OF FORMATION/{err=0}
/CARTESIAN COORDINATES/{if(err==0){getline;
   for(i=1;i<=huge;i++) {getline;if(NF==0)exit;++n;s[n]=$2;x[n]=$3;y[n]=$4;z[n]=$5 } } }
END{
if(err==1) 
   print "Error"
else
   print n"\n"
   for(i=1;i<=n;i++) print s[i],x[i],y[i],z[i] 
}' $file
