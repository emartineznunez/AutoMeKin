file=$1
nc=$2
awk '/sp ca/{++fl};/MP2/{if(fl=='$nc'-1 && NF==6) e=$NF};END{print e}' $file | sed 's/D/ /g' | awk '{printf "%14.9f\n",$1*10^$2} '
