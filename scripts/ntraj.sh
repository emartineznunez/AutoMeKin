huge=10000
tot=0
for i in $(seq 1 $huge)
do
   file=batch$i/amk.log
   if [ -f $file ]; then
      nt=$(awk 'BEGIN{nt=0};/Trajectory/{nt=$3};END{print nt}' $file)
      ((tot=tot+nt))
      printf "Batch%3s --->%4s trajs finished. Total number of trajs= %4s\n" "$i" "$nt" "$tot"
   fi
done

