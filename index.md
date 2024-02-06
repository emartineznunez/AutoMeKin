---
title: Installing AutoMeKin
layout: home
nav_order: 1
---


# Installation of AutoMeKin

AutoMeKin offers three different installation and deployment methods. If you're eager to experience it firsthand, simply click on [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb) to quickly get a sense of the code.XYZ

## Intallation options
1. [Auto installer](#autoinstaller)
2. [Singularity container](#singularity)
3. [Build from source](#build)

## 1. Auto installer <a name="autoinstaller"></a>
An auto installer script is provided to install singularity and
download the last release container image from [sylabs](https://cloud.sylabs.io/library/emartineznunez/default/automekin) as
`$HOME/automekin_<tag>.sif`. Note that this is done only the first time
you use it unless a new image is available. Then, the script will detect
singularity and the image (that must be located in your `$HOME`) and will
only start an instance of the container. The container includes
[amk-tools](https://github.com/dgarayr/amk_tools). 

_To start/stop the container follow these steps_:

- Download script: 
   ```
   curl -LJO https://github.com/emartineznunez/Singularity_amk/raw/main/installer/Automekin.sh
   ```

- ```
   chmod +x Automekin.sh
   ```

- ```
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
under `${TMPDIR-/tmp}/amk_installer-${USER}/software` in bash shell script
syntax and an instance of the container will be started using a sandbox
image deployed under `/tmp/selfextract.XXXXXX` folder (where `XXXXXX` is a
randomly generated character sequence). The container comes with all
AutoMeKin's tools installed in `$AMK` plus vim, gnuplot and molden which
can be run from the container. A bash shell session under `$HOME` will
start under the deployed instance. Note that you can open new sessions
and access AutoMeKin's output files from your Linux environment and use
your own tools as well.

- To exit the container just type: `exit`

- Once your calculations are done, remember to stop the instance:
```
./Automekin.sh stop
```

{: .note }  
To download the file directly from your terminal, curl must be installed. The autoinstaller also works on Ubuntu 20.04 LTS on Windows.  

## 2. Singularity container <a name="singularity"></a>
If singularity is already installed in your
computer, you can obtain the container from sylabs. First check the
latest image, Tag, by typing: 

```
singularity search automekin
```

and replace `<Tag>` below by that number.
Then, from your `$HOME` type: 

```
singularity pull library://emartineznunez/default/automekin:<Tag>
```

You can start an instance of the container and run it using:

```
singularity instance start automekin_<Tag>.sif automekin
```
```
singularity run instance://automekin
```

which will allow you to run low-level scripts. You can stop the instance
using:

```
singularity instance stop automekin
```

Note, however, that if you want to use G09/G16 you must bind it to the
container. To help you do so, we created the scripts `SingularitygXX.sh`
(replace `XX` with 09 or 16), which can be downloaded as:
```
curl -LJO https://github.com/emartineznunez/Singularity_amk/raw/main/SingularitygXX.sh
```
The script should be run with the complete path to the sif file as
argument as in the example:
```
SingularitygXX.sh $HOME/automekin_<Tag>.sif
```
Note that `SingularitygXX.sh` will start a new instance of the container
every time it is executed. To list the instances use:
```
singularity instance list
```
And stop them as indicated above.

## 3. Build from source <a name="build"></a>

The most recent and up to date version is avaialable at this repository.

You can build, system-wide and including dependencies, using this CentOS-based script:
```
curl -LJO https://raw.githubusercontent.com/emartineznunez/AutoMeKin/main/Build_Centos.sh
```
You can also check how to install AutoMeKin and its dependencies in this Notebook: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb)

If you prefer to install everything manually, follow the next steps.

### Installing dependencies 

{: .highlight }    
The following packages are required beforehand:   
[GNU Autoconf](https://www.gnu.org/software/autoconf/), [GNU Bash](https://www.gnu.org/software/bash/), [GNU bc](https://www.gnu.org/software/bc/), [environment-modules](https://github.com/cea-hpc/modules), [GNU Awk, gawk](https://www.gnu.org/software/gawk/), [GNU C Compiler, gcc](https://gcc.gnu.org/), [Gnuplot](http://www.gnuplot.info/), [GNU Fortran Compiler, gfortran](https://gcc.gnu.org/wiki/GFortran), [GNU Parallel](https://www.gnu.org/software/bash/manual/html_node/GNU-Parallel.html), [SQLite\>= 3](https://www.sqlite.org/index.html), [Zenity](https://wiki.gnome.org/Projects/Zenity)

For your convenience, you use the scripts: `install-required-packages-distro.sh` (where `distro`=ubuntu-16.4lts, centos7 or sl7), which will do the work for you.The ubuntu-16.4lts
script installs all dependencies, but for the RHEL derivatives, centos7
and sl7, you have to install parallel separately, and you have two
choices:

- `install-gnu-parallel-from-source.sh`. This script installs parallel
latest version from source thanks to Ole Tange, the author. Also it can
fallback to a user private installation into `$HOME/bin` if you have not
administrator permisions to install it globally.

- `install-gnu-parallel-from-epel.sh`. Enables the EPEL repository and
installs parallel from it.

{: .highlight }    
The following python3 libraries are
needed:  
[ASE>= 3.21.1](https://wiki.fysik.dtu.dk/ase/install.html), [Matplotlib>= 3.3.4](https://matplotlib.org/stable/users/installing/index.html), [NetworkX>= 2.5](https://networkx.org/documentation/stable/install.html), [NumPy>= 1.19.5](https://numpy.org/install/), [SciPy>= 1.5.4](https://scipy.org/install/)  
The installation of [molden](https://www.theochem.ru.nl/molden/linux.html) is highly recommended to analyze the results.

#### **Electronic structure packages**

While mopac comes with the distribution, [gaussian](https://gaussian.com/) and/or [Entos Qcore](https://software.entos.ai/qcore/documentation/) should be installed by the user.

{: .highlight }   
Entos Qcore, which is free for academica, can be easily installed following these steps:

1. Install [miniconda](https://docs.conda.io/projects/miniconda/en/latest/)
2. Add the following line to `$HOME/.condarc`, creating the file if not present:
```
auto_activate_base: false
```
which avoids activation of base environment.   
3. Install qcore version 0.8.14 in the conda environment qcore-0.8.14-env:
```
conda create -n qcore-0.8.14-env -c entos -c conda-forge qcore==0.8.14 'tbb<2021'
```
4. Activate the newly created environment:
```
conda activate qcore-0.8.14-env
```
5. After installation, each user will be asked to read the Software License Agreement to generate a unique token:
```
qcore --academic-license
```

### Installing AutoMeKin

Once the above packages are installed, you can now install AutoMeKin
following these steps:. Clone AutoMeKin from GitHub:
```
git clone https://github.com/emartineznunez/AutoMeKin.git
```
```
cd AutoMeKin
```
```
autoreconf -i
```
```
./configure --prefix=path_to_program
```
Where you can specify where you want to install it, _e.g._, `/opt/AutoMeKin`
```
make 
```
```
make install
```
For convenience, and once “Environment Modules” has been installed, you
should add the following line to your `.bashrc` file:
```
module use path_to_program/modules
```
where `path_to_program` is the path where you installed amk (_e.g._,
`$HOME/amk-2021`).

