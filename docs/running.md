---
title: Get everything with a single script
layout: home
nav_order: 3
---

# Get everything with a single script

{: .highlight}  
To obtain all mechanistic and kinetic information for your system, you can just run a single script per each type of calculation: low-level and high-level.  

{: .note }   
In [this section](https://emartineznunez.github.io/AutoMeKin/docs/scripts.html) you have details about the workflows involved in `llcals.sh` and `hlcalcs.sh`   


First, load the module:
```bash
module load amk/2021
```
Then, run the low-level calculations:
```bash
nohup llcalcs.sh molecule.dat ntasks niter runningtasks >llcalcs.log 2>&1 &
```
where:  
<code>molecule</code> is the name of your molecule  
<code>ntasks</code> is the number of tasks per iteration  
<code>niter</code> is the number of iterations  
<code>runningtasks</code> is the number of simultaneous parallel tasks   

Finally, run the high-level calculations:
```bash
nohup hlcalcs.sh molecule.dat runningtasks >hlcalcs.log 2>&1 &
```
