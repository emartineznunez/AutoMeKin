file=$1
awk '/ATOM   CHEMICAL/{
  getline
  getline
  i=1
  while(i<=100000){
    getline
    if(NF==0) exit
    print $2,$3,$5,$7
    i++
    }
}' $file
