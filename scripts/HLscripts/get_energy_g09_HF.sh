file=$1
nc=$2
awk '/sp ca/{++fl};/SCF Done/{if(fl=='$nc'-1 && $3 ~ /HF/) e=$5};END{print e}' $file 

