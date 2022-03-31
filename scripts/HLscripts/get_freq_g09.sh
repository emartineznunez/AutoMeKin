awk '/Frequencies/{++j;for(i=3;i<=NF;i++) {l=i-2;k=(j-1)*3+l;freq[k]=$i}}
END{nfreq=k
k=1
while(k<=nfreq) {
  if(sqrt(freq[k]*freq[k])<1) freq[k]=1
  printf "%5.0f\n",freq[k]
  k++
  }
}' $1

