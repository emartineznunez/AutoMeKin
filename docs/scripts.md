---
title: Using the scripts
layout: home
parent: Tutorial
nav_order: 3
---

# Using the scripts

## Production runs

For production runs use the scripts [as indicated here](https://emartineznunez.github.io/AutoMeKin/docs/running.html).

## Step-by-step low-level calculations

This section explains how to run one iteration of our workflow. This might be useful for getting acquainted
with the program and didactic purposes, but the recommended option for production runs is to use the
iterative llcalcs.sh and hlcalcs.sh scripts explained above.

To run AutoMeKin in a single processor use `amk.sh` script with the name of the input file as argument:
```
amk.sh FA.dat > amk.log &
```
The ouput file `amk.log` provides information about the calculations. In addition, a directory called
`tsdirLL_FA` is created, which contains information that may be useful for checking purposes. We notice
that the program creates a symbolic link to the `FA.dat` file, named amk.dat, which is used internally by
several amk scripts. At any time, you can check the transition states that have been found using:
```
tsll_view.sh
```
The output of this script will be something like this:
```
ts # File name w_imag  Energy  w1  w2   w3   w4 traj #  Folder
--------------------------------------------------------------
2    ts2_batch4 1588i -35.7105 206 438  461  727     1  wrkdir
3    ts3_batch2  458i -78.1007 573 846 1034 1195     3  wrkdir
4    ts4_batch6 2010i -17.6124 327 473  523 1078     1  wrkdir
```
where the first column is the label of each TS, the second is the filename of the optimized TS structure
(located in the tsdirLL_FA directory), the third is the imaginary frequency (in cm−^1 ), the fourth one is the
absolute energy of the TS (in kcal/mol for MOPAC2016 and Hartrees for qcore and gaussian) and the next
four numbers are the four lowest vibrational frequencies (in cm−^1 ). Finally, the last two columns are the
trajectory number and the name of the folder where the structure was obtained.

**CAVEAT:** since the dynamics employ random number seeds, the above results may differ for this type of
calculations although using a sufficiently large number of trajectories (see below), the important TSs should
appear in all runs.


As already mentioned, the output files of the optimized TSs are stored in tsdirLL_FA. You can use a
visualization program (e.g., molden) to analyze your results. Try, for instance:

molden tsdirLL_FA/ts1_FA.molden

You can also watch the animation of trajectories, which are stored in the coordir folder inside wrkdir:

molden coordir/FA_dyn1.xyz

We notice that the coordir folder is temporary. It is removed during the execution of a subsequent script.

If you have access to several processors and want to run the dynamics in parallel, you can use the script
amk_parallel.sh, which is executed interactively (a Zenity progress bar will appear on the screen). For
instance, to submit 50 trajectories split in 5 different tasks (10 trajectories each) you should use:

amk_parallel.sh FA.dat 5

This will create temporary directories batch1, batch2, batch3, batch4 and batch5 that will be
removed when the IRCs are calculated. Each of these folders includes a coordir directory, which contains
the individual trajectories. The TSs found in each individual task will be copied in the same folder,
tsdirLL_FA, and, as indicated above, using the tsll_view.sh script you can monitor the progress of the
calculations. Notice that the total number of trajectories is given by value[ntraj] multiplied by the
number of tasks. We recommend running the amk_parallel.sh script interactively only for checking
purposes, and particularly to carry out the screening. To run many trajectories for production, we
recommend using the llcalcs.sh script, which is described below.

If the Slurm Workload Manager is installed on your computer, you can submit the jobs to Slurm using:

sbatch [ _options_ ] amk_parallel.sh FA.dat ntasks

where ntasks is the number of tasks. If no options are specified, sbatch employs the following default
values:

#SBATCH --output=amk_parallel-%j.log
#SBATCH --time=04:00:
#SBATCH -c 1 --mem-per-cpu=
#SBATCH -n 8
These values can be changed when you submit the job with _options_.

**CAVEAT:** if you use Slurm Workload Manage for the amk_parallel.sh script, you will have to wait until
all tasks are completed before going on.


The amk package includes the irc.sh script, which performs intrinsic reaction coordinate calculations for
all the located TSs. This script also allows one to perform an initial screening of the TS structures before
running the IRC calculations:

irc.sh screening

This will do the screening and stop. The process involves the use of tools from Spectral Graph Theory and
utilizes value[MAPEmax] _,_ value[BAPEmax] and value[eigLmax]. The redundant and fragmented
structures are printed on screen as well as in the file screening.log which is located in tsdirLL_FA.
MOPAC2016 ouput files are also gathered in tsdirLL_FA, and use filenames initiated by “REPEAT” and
“DISCNT”, which refer to repeated and disconnected (i.e., fragmented) structures, respectively. Please
check these structures and, if needed, change the above parameters. Should you change some of the above
parameters (value[MAPEmax] _,_ value[BAPEmax] _,_ value[eigLmax]), you need to redo the screening
with the new parameters:

redo_screening.sh

You can repeat the above process until you are happy with the screening.

Once you are confident with the threshold values, you can submit many trajectories to carry out a thorough
exploration of the potential energy surface. Subsequently, you can proceed with the IRC calculations.

_Obtaining the IRCs_ :

(sbatch [ _options_ ]) irc.sh

_Optimizing the minima_ :

(sbatch [ _options_ ]) min.sh

_Building the reaction network_ :

rxn_network.sh

Once you have created the reaction network, you can grow your TS list by running more trajectories (with
amk_parallel.sh or amk.sh). Now the trajectories will start from the newly generated minima as well as
from the main structure, specified in the name.xyz file. It is important to notice that, in general, trajectories
run in separate batches (i.e., performed in several tasks) may be initialized from different minima and will
have different energies. In this regard, the efficiency of the code may increase if the calculations are
submitted using a large number for the ntasks parameter.

Convergence in the total number of TSs can be checked doing:


track_view.sh

When you are happy with the obtained TSs or you achieve convergence, you can proceed with the next
steps.

_Rnning the kinetics at the conditions of interest_ :

kmc.sh

_Gathering all relevant information in folder_ FINAL_LL_FA:

final.sh

This folder will gather all the relevant information data, which are described below.

### e) Step-by-step high-level calculations

Although the recommended option for running the high-level calculations is to use hlcalcs.sh, it is
possible to perform the calculations step by step, as described next:

From your wrkdir (FA in the example), run the following scripts:

_Optimizing the TSs_

(sbatch [ _options_ ]) TS.sh FA.dat

In this case, the default values for a job submitted to Slurm are:

#SBATCH --time=04:00:
#SBATCH -n 4
#SBATCH --output=TS-%j.log
#SBATCH --ntasks-per-node=
#SBATCH -c 12
_Building the high-level reaction network, optimizing the minima and running the kinetics_ :

(sbatch [ _options_ ]) IRC.sh
(sbatch [ _options_ ]) MIN.sh
RXN_NETWORK.sh
KMC.sh
Remember that the use of Slurm involves checking that every script has finished before proceeding with the
next one.

_Optimizing the product fragments_ :

(sbatch [ _options_ ]) PRODs.sh

**CAVEAT** : The previous step is mandatory before proceeding gather all information in the final folder.


_Gathering all relevant information in folder_ FINAL_HL_FA:

FINAL.sh

Notice that the high-level calculations also generate the directory tsdirHL_FA, whose structure is similar
to tsdirLL_FA. Finally, remember that you can use the kinetics.sh to calculate rate coefficients and
product branching rations for an energy or temperature different from that specified in the kinetics section.

### f) Aborting the calculations

If, for any reason, you want to kill the iterative calculations, execute the following script from the wrkdir:

abort.sh

This script kills the processes whose PID are specified in these hidden files: .parallel.pid and
.script.pid. We notice that, if G09/G16 jobs are killed, the read-write files (Gau-#####) generated in
the Gaussian scratch directory are not removed. The user should do it manually.

### g) Directory tree structure of wrkdir

The figure below shows the main folders that are generated in wrkdir. Folders batchXX (where XX = 1 -
tasks) are generated with amk_parallel.sh. This script is also invoked by llcalcs.sh, and when that
happens these folders are temporary (they are removed at the end of the tasks). Directory coordir is only
generated in those directories where amk.sh is executed. The amk_parallel-logs directory contains a
series of files that give information on CPU time consumption for the different calculation steps when they
were executed with GNU Parallel. Directories tsdirLL_name and tsdir_HL_name are generated at
runtime and are employed to generate the final files and directories. For that reason, they should not be
removed. Finally, the most important files are gathered in a final directory (FINALDIR) which is named after
the system’s name: FINAL_level_name (with level being LL for low-level or HL for high level; see figure
below).

### wrkdir

```
tsdirHL_name FINAL_HL_name coordir amk_parallel-logs batchXX FINAL_LL_name tsdirLL_name
```
```
normal_modes normal_modes
```
```
amk.sh amk_parallel.sh
```
