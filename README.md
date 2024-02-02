# AutoMeKin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb) [![Download AutoMeKin](https://img.shields.io/sourceforge/dm/automekin.svg)](https://sourceforge.net/projects/automekin/files/latest/download)

This is the official repository of the automated reaction discovery program **AutoMeKin** (**Auto**mated **Me**chanisms and **Kin**etics).

<p align="left">
   <img src="logo.png" alt="alt text" width="200" height="100">
</p>


AutoMeKin (formerly tsscds) has been designed to discover reaction mechanisms in an automated fashion. Transition states are located using MD simulations and Graph Theory algorithms. Monte Carlo simulations afford kinetic results. The only input is a starting structure in XYZ format. The method is described in these two publications: [1](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790) [2](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h#!divAbstract). At present [MOPAC2016](https://github.com/openmopac/mopac), [Entos Qcore](https://software.entos.ai/qcore/documentation/) and [Gaussian (G09/G16)](https://gaussian.com/) are interfaced with AutoMeKin. The program has been tested on the following Linux distros: CentOS 7, Red Hat Enterprise Linux and Ubuntu 20.04 LTS.


Further details: https://github.com/emartineznunez/AutoMeKin/wiki

Try it out in Colab: 
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb)

## Installation
### Content
- [Auto installer](#autoinstaller)
- [Singularity container](#singularity)
- [Build from source](#build)

### Auto installer <a name="autoinstaller"></a>
An auto installer script is provided to install singularity and
download the last release container image from [sylabs](https://cloud.sylabs.io/library/emartineznunez/default/automekin) as
`$HOME/automekin_<tag>.sif`. Note that this is done only the first time
you use it unless a new image is available. Then, the script will detect
singularity and the image (that must be located in your `$HOME`) and will
only start an instance of the container. The container includes
**[amk-tools](https://github.com/dgarayr/amk_tools)**. 

**Follow these three steps to start the container**.

1. Download script: 
   ```
   curl -LJO https://github.com/emartineznunez/Singularity_amk/raw/main/installer/Automekin.sh
   ```

4. ```
   chmod +x Automekin.sh
   ```

3. ```
   ./Automekin.sh
   ```

Note that depending on your Linux configuration, before running the
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

**To exit the container** just type: `exit`

**Once your calculations are done, remember to stop the instance:** 
```
./Automekin.sh stop
```

**Important notes:**

- To download the file directly from your terminal, curl must be installed.
- The autoinstaller also works on Ubuntu 20.04 LTS on Windows.

### Singularity container <a name="singularity"></a>
If singularity is already installed in your
computer, you can obtain the container from sylabs. First check the
latest image (Tag) by typing: 

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

### Build from source <a name="build"></a>

The most recent and up to date version is avaialable at this repository.

You can build (system-wide and including dependencies) using this script (on a CentOS):
```
curl -LJO https://raw.githubusercontent.com/emartineznunez/AutoMeKin/main/Build_Centos.sh
```
You can also check how to install AutoMeKin and its dependencies in this Notebook: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb)

If you prefer to install everything manually, follow the next steps.

#### Installing dependencies 
The following packages are required beforehand:

- [GNU Autoconf](https://www.gnu.org/software/autoconf/), [GNU Bash](https://www.gnu.org/software/bash/), [GNU bc](https://www.gnu.org/software/bc/), [environment-modules](https://github.com/cea-hpc/modules), [GNU Awk (gawk)](https://www.gnu.org/software/gawk/), [GNU C Compiler (gcc)](https://gcc.gnu.org/), [Gnuplot](http://www.gnuplot.info/), [GNU Fortran Compiler (gfortran)](https://gcc.gnu.org/wiki/GFortran), [GNU Parallel](https://www.gnu.org/software/bash/manual/html_node/GNU-Parallel.html), [SQLite (version \>= 3)](https://www.sqlite.org/index.html), [Zenity](https://wiki.gnome.org/Projects/Zenity)

For your convenience, you use the scripts: `install-required-packages-distro.sh` (where `distro`=ubuntu-16.4lts,
centos7 or sl7), which will do the work for you.The ubuntu-16.4lts
script installs all dependencies, but for the RHEL derivatives (centos7
and sl7) you have to install parallel separately, and you have two
choices:

1. `install-gnu-parallel-from-source.sh`. This script installs parallel
latest version from source thanks to Ole Tange (the author). Also it can
fallback to a user private installation into `$HOME/bin` if you have not
administrator permisions to install it globally.

2. `install-gnu-parallel-from-epel.sh`. Enables the EPEL repository and
installs parallel from it.

Additionally, the following python3 libraries (easily installed with pip) are
needed:

- ASE (\>= 3.21.1), Matplotlib (\>= 3.3.4), NetworkX (\>= 2.5), NumPy (\>= 1.19.5), SciPy (\>= 1.5.4)

The installation of [molden](https://www.theochem.ru.nl/molden/linux.html) is highly recommended to analyze the results:

#### Installing AutoMeKin

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
