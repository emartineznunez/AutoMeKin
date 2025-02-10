---
title: Automated workflows
layout: home
nav_order: 3
---

# Automated workflows

{: .highlight}  
To obtain all mechanistic and kinetic information for your system, you can simply run a single script _per_ each type of calculation: low-level and high-level.  

First, load the module:
```bash
module load amk/2021
```
Then, the `llcalcs.sh` script can be employed to run the low-level workflow:
```bash
nohup llcalcs.sh molecule.dat ntasks niter runningtasks >llcalcs.log 2>&1 &
```
where:  
<code>molecule</code> is the name of your molecule  
<code>ntasks</code> is the number of tasks per iteration  
<code>niter</code> is the number of iterations  
<code>runningtasks</code> is the number of simultaneous parallel tasks   

Finally, all high-level calculations can be accomplished using `hlcalcs.sh`:
```bash
nohup hlcalcs.sh molecule.dat runningtasks >hlcalcs.log 2>&1 &
```

The `llcalcsh.sh` and `hlcalcs.sh` scripts can also be run using a Slurm job scheduler and the following scripts are examples:
```bash
#!/bin/bash
ntasks=20
niter=2
filename=FA
module load amk/2021
sbatch --output=llcalcs.log --error=llcalcs.err -n $ntasks --mem-per-cpu=2G -t 00:10:00 llcalcs.sh ${filename}.dat $ntasks $niter
```

```bash
#!/bin/bash
ntasks=8
ncores=4
filename=FA
module load amk/2021
module load g16
sbatch --output=hlcalcs.log --error=hlcalcs.err -n $ntasks -c $ncores --mem-per-cpu=2G -t 00:30:00 hlcalcs.sh ${filename}.dat
```


{: .note }   
Details about the workflows involved in `llcals.sh` and `hlcalcs.sh` can be looked up in [this section](https://emartineznunez.github.io/AutoMeKin/docs/scripts.html).  

If something goes wrong, you might want to have a look [at this section](https://emartineznunez.github.io/AutoMeKin/docs/scripts.html#abort) describing how to stop the calculations.
