---
title: Everything automated
layout: home
nav_order: 3
---

# Everything automated

{: .highlight}  
To obtain all mechanistic and kinetic information for your system, you can simply run a single script _per_ each type of calculation: low-level and high-level.  

{: .note }   
Details about the workflows involved in `llcals.sh` and `hlcalcs.sh` can be looked up in [this section](https://emartineznunez.github.io/AutoMeKin/docs/scripts.html).  


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
If something goes wrong, you might want to have a look [at this section](https://emartineznunez.github.io/AutoMeKin/docs/scripts.html#abort) describing how to stop the calculations.
