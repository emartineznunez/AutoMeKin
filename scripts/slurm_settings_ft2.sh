#!/bin/bash
slurm_files=(irc.sh llcalcs.sh min.sh amk_parallel.sh HLscripts/BARRLESSRXN1.sh HLscripts/hlcalcs.sh HLscripts/IRC.sh HLscripts/MIN.sh HLscripts/PRODs.sh HLscripts/TS.sh)
for i in ${slurm_files[@]}
do
   sed -i 's@_remove_this_in_ft_@@' $i 
done
