awk 'BEGIN{maxl=20};{if($1=="PROD") {
   n=$2;$1="";$2="";p[n]="PR"n":"$0;if(length(p[n])>maxl) maxl=length(p[n])} }
NR>FNR{a=maxl-5;b=maxl;c=maxl+15
   if($1!="PROD") {
   if($3=="MIN" && $6=="MIN") 
      printf "%5.0f %10.1f %*s %4.0f <---> %*s %4.0f  %10s\n",$1,$2,a,$3,$4,a,$6,$7,$8
   else if($3=="MIN" && $6=="PROD" )
      printf "%5.0f %10.1f %*s %4.0f ----> %*s  %10s\n",$1,$2,a,$3,$4,b,p[$7],$8
   else if($3=="PROD" && $6=="PROD" )
      printf "%5.0f %10.1f %*s <---> %*s  %10s\n",$1,$2,b,p[$4],b,p[$7],$8
   else if($1=="TS") {
      printf " TS # %14s %*s\n",$3,c,"Reaction path information"
      printf " ====   ============ %*s\n",c,"========================="}
    } 
}' $1 $1
