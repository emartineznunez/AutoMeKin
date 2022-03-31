if [ "$#" -eq 0 ]; then
   echo ""
   echo "Please provide the complete path to your sif file. Example:"
   echo ""
   echo "$(basename $0) $HOME/automekin2020_872.sif" 
   echo ""
   exit 1
fi
siffile=$1
if [ $(singularity instance list | awk 'END{print NR-1}') -ge 1 ];then
   in=$(singularity instance list | awk '{n=$1};END{print n}' | sed 's/automekin//' | awk '{print $1+1}')
else
   in=1
fi
if G09DIR=$(dirname $(which g09 2> /dev/null) 2> /dev/null)
then
   if [ -d $GAUSS_SCRDIR ]
   then
      SINGULARITYENV_GAUSS_SCRDIR=/scratch SINGULARITYENV_PREPEND_PATH=/opt/g09 singularity instance start --bind $G09DIR:/opt/g09 --bind $GAUSS_SCRDIR:/scratch $siffile automekin$in
   else
      SINGULARITYENV_PREPEND_PATH=/opt/g09 singularity instance start --bind $G09DIR:/opt/g09 $siffile automekin$in
   fi
else
   echo "Gaussian 09 not available, only low-level calculations available"
   singularity instance start $siffile automekin$in
fi
singularity run instance://automekin$in
