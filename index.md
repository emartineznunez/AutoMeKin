---
title: 🚀Quick start & Installion
layout: home
nav_order: 1
---

# 🚀Quick Start 


If you're eager to experience it firsthand, you can try this Notebook:    


[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin.ipynb)

# Installation of AutoMeKin
**AutoMeKin** offers three different installation and deployment methods: 
1. [Build with `micromamba` $\scriptstyle($recommended option$\scriptstyle)$](#mm)
2. [Build from source](#build)
3. [Singularity container](#singularity)
4. [Auto installer](#autoinstaller)

## 1. Build with `micromamba` <a name="mm"></a>
This is the recommended option. 

First, clone the repository:

```
git clone https://github.com/emartineznunez/AutoMeKin.git
```

Go to the AutoMeKin directory:

```
cd AutoMeKin
```

To build `AutoMeKin` and its dependencies (including `amk_tools`, `qcore` and `molden`) using `micromamba`, just type (it needs `curl` installed in your system):

```
bash Build_micromamba.sh
```

and follow the instructions to activate the environment.

Before using `qcore` for the first time, remember to agree to the Software License Agreement and to set your token by running:

```
entos --license
```




## 2. Build from source <a name="build"></a>

The most recent version is avaialable at GitHub and can be installed as indicated in this section.

You can build, system-wide and including dependencies, following the steps indicated in these scripts: 
- [CentOS-based script](https://raw.githubusercontent.com/emartineznunez/AutoMeKin/main/Build_Centos.sh)
- [Ubuntu-based script](https://raw.githubusercontent.com/emartineznunez/AutoMeKin/main/Build_Ubuntu.sh)


To install everything manually, follow the next steps.

### Installing dependencies 

{: .highlight }    
The following **packages** are required beforehand:   
[GNU Autoconf](https://www.gnu.org/software/autoconf/), [GNU Bash](https://www.gnu.org/software/bash/), [GNU bc](https://www.gnu.org/software/bc/), [environment-modules](https://github.com/cea-hpc/modules), [GNU Awk, gawk](https://www.gnu.org/software/gawk/), [GNU C Compiler, gcc](https://gcc.gnu.org/), [GNU Fortran Compiler, gfortran](https://gcc.gnu.org/wiki/GFortran), [GNU Parallel](https://www.gnu.org/software/bash/manual/html_node/GNU-Parallel.html), [SQLite\>= 3](https://www.sqlite.org/index.html)
The installation of [molden](https://www.theochem.ru.nl/molden/linux.html) is highly recommended to analyze the results.

Additionally,

{: .highlight }    
The following **Python3 libraries** are
needed:  
[ASE>= 3.21.1](https://wiki.fysik.dtu.dk/ase/install.html), [Matplotlib>= 3.3.4](https://matplotlib.org/stable/users/installing/index.html), [NetworkX>= 2.5](https://networkx.org/documentation/stable/install.html), [NumPy>= 1.19.5](https://numpy.org/install/), [SciPy>= 1.5.4](https://scipy.org/install/)  


### Installting other electronic structure packages

While mopac comes with the distribution, [gaussian](https://gaussian.com/) and/or [Entos Qcore](https://software.entos.ai/qcore/documentation/) should be installed by the user.

{: .highlight }   
Entos Qcore, which is free for academia, can be easily installed following these steps:

1. Install [miniconda](https://docs.conda.io/projects/miniconda/en/latest/)
2. Add the following line to `$HOME/.condarc`{: .language-bash .highlight}, creating the file if not present:
```bash
auto_activate_base: false
```
which avoids activation of base environment.   
3. Install qcore version 0.8.14 in the conda environment qcore-0.8.14-env:
```bash
conda create -n qcore-0.8.14-env -c entos -c conda-forge qcore==0.8.14 'tbb<2021'
```
4. Activate the newly created environment:
```bash
conda activate qcore-0.8.14-env
```
5. After installation, each user will be asked to read the Software License Agreement to generate a unique token:
```bash
qcore --academic-license
```

### Installing AutoMeKin

Once the above packages are installed, you can now install AutoMeKin
following these steps:
```bash
git clone https://github.com/emartineznunez/AutoMeKin.git
```
```bash
cd AutoMeKin
```
```bash
autoreconf -i
```
```bash
./configure --prefix=path_to_program
```
Where you can specify where you want to install it, _e.g._, `/opt/AutoMeKin`{: .language-bash .highlight}
```bash
make 
```
```bash
make install
```
For convenience, and once “Environment Modules” has been installed, you
should add the following line to your `.bashrc` file:
```bash
module use path_to_program/modules
```
where `path_to_program` is the path where you installed amk (_e.g._,
`$HOME/amk-2021`{: .language-bash .highlight}).

## 3. Singularity container <a name="singularity"></a>
If singularity is already installed in your
computer, you can obtain the container from sylabs. First check the
latest image, Tag, by typing: 

```bash
singularity search automekin
```

and replace `<Tag>` below by that number.
Then, from your `$HOME` type: 

```bash
singularity pull library://emartineznunez/default/automekin:<Tag>
```

You can start an instance of the container and run it using:

```bash
singularity instance start automekin_<Tag>.sif automekin
```
```bash
singularity run instance://automekin
```

which will allow you to run low-level scripts. You can stop the instance
using:

```bash
singularity instance stop automekin
```

Note, however, that if you want to use G09/G16 you must bind it to the
container. To help you do so, we created the scripts `SingularitygXX.sh`
(replace `XX` with 09 or 16), which can be downloaded as:
```bash
curl -LJO https://github.com/emartineznunez/Singularity_amk/raw/main/SingularitygXX.sh
```
The script should be run with the complete path to the sif file as
argument as in the example:
```bash
SingularitygXX.sh $HOME/automekin_<Tag>.sif
```
Note that `SingularitygXX.sh` will start a new instance of the container
every time it is executed. To list the instances use:
```bash
singularity instance list
```
And stop them as indicated above.



## 4. Auto installer <a name="autoinstaller"></a>
An auto installer script is provided to install singularity and
download the last release container image from [sylabs](https://cloud.sylabs.io/library/emartineznunez/default/automekin) as
`$HOME/automekin_<tag>.sif`{: .language-bash .highlight}. Note that this is done only the first time
you use it unless a new image is available. Then, the script will detect
singularity and the image (that must be located in your `$HOME`{: .language-bash .highlight}) and will
only start an instance of the container. The container includes [![GitHub - amk_tools](https://img.shields.io/badge/GitHub-amk_tools-blue?logo=github)](https://github.com/dgarayr/amk_tools/). 

{: .warning }  
This option offers an outdated version of singularity, lacking proper image verifying capabilities. Consequently, an error is consistently triggered upon downloading a new image.




_To start/stop the container follow these steps_:

- Download script: 
   ```bash
   curl -LJO https://github.com/emartineznunez/Singularity_amk/raw/main/installer/Automekin.sh
   ```

- ```bash
   chmod +x Automekin.sh
   ```

- ```bash
   ./Automekin.sh
   ```

{: .note }  
Depending on your Linux configuration, before running the
autoinstaller you might need to change some parameters which will
require admin or root privilege. If that is the case and once you
changed the parameters with your admin or root accounts, no further
admin or root privilege will be needed. Return to your user account and
run the auto installer again.

Once the above steps are completed, singularity will be installed
under `${TMPDIR-/tmp}/amk_installer-${USER}/software`{: .language-bash .highlight} in bash shell script
syntax and an instance of the container will be started using a sandbox
image deployed under `/tmp/selfextract.XXXXXX`{: .language-bash .highlight} folder (where `XXXXXX` is a
randomly generated character sequence). The container comes with all
AutoMeKin's tools installed in `$AMK`{: .language-bash .highlight}, which
can be run from the container. A bash shell session under `$HOME`{: .language-bash .highlight} will
start under the deployed instance. Note that you can open new sessions
and access AutoMeKin's output files from your Linux environment and use
your own tools as well.

- To exit the container just type: `exit`{: .language-bash .highlight}

- Once your calculations are done, remember to stop the instance:
```bash
./Automekin.sh stop
```

{: .note }  
To download the file directly from your terminal, curl must be installed. The autoinstaller also works on Ubuntu 20.04 LTS on Windows.  




