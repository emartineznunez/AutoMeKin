# AutoMeKin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This is the official repository of the automated reaction discovery program AutoMeKin.

<p align="center">
   <img src="logo.png" alt="alt text" width="200" height="100">
</p>

AutoMeKin (formerly tsscds) has been designed to discover reaction mechanisms in an automated fashion. Transition states are located using MD simulations and Graph Theory algorithms. Monte Carlo simulations afford kinetic results. The only input is a starting structure in XYZ format. 

Further details: https://github.com/emartineznunez/AutoMeKin/wiki

Try out a simple example here: 
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb)

## Installation

### Auto installer 
This is the easiest way to install/use AutoMeKin. The
auto installer script installs singularity in your computer and
downloads the last release container image from sylabs
(https://cloud.sylabs.io/library/emartineznunez/default/automekin) as
`$HOME/automekin\_<tag>.sif`. Note that this is done only the first time
you use it unless a new image is available. Then, the script will detect
singularity and the image (that must be located in your $HOME) and will
only start an instance of the container. The container includes
amk-tools

1\) Download AutoMeKin's auto installer script Automekin.sh (Last update
April 4, 2022) from your terminal:

curl -LJO
<https://github.com/emartineznunez/Singularity_amk/raw/main/installer/Automekin.sh>

2\) Make the script executable:

chmod +x Automekin.sh

3\) Run the script:

./Automekin.sh

Note that depending on your Linux configuration, before running the
autoinstaller you might need to change some parameters which will
require admin or root privilege. If that is the case and once you
changed the parameters with your admin or root accounts, no further
admin or root privilege will be needed. Return to your user account and
run the auto installer again.

4\) Once the above steps are completed, singularity will be installed
under ${TMPDIR-/tmp}/amk_installer-${USER}/software in bash shell script
syntax and an instance of the container will be started using a sandbox
image deployed under /tmp/selfextract.XXXXXX folder (where XXXXXX is a
randomly generated character sequence). The container comes with all
AutoMeKin's tools installed in $AMK plus vim, gnuplot and molden which
can be run from the container. A bash shell session under $HOME will
start under the deployed instance. Note that you can open new sessions
and access AutoMeKin's output files from your Linux environment and use
your own tools as well.

5\) To exit the container just type:

exit

6\) Once your calculations are done, remember to stop the instance:

./Automekin.sh stop

Important notes:

To download the file directly from your terminal, curl must be installed
Make sure your auto installer is up to date (see above) The
autoinstaller also works on Ubuntu 20.04 LTS on Windows 10. To install
Ubuntu 20.04 LTS on Windows 10, follow these instructions:
<https://docs.microsoft.com/en-us/windows/wsl/install-win10> AutoMeKin's
third-party packages in the container are updated (see below the minimum
required version numbers). Local installations of different versions of
these Python packages might interfere in the execution of AutoMeKin
Singularity container If singularity is already installed in your
computer, you can obtain the container from sylabs. First check what the
latest image (Tag) is by typing:

singularity search automekin and replace <Tag> below by that number.
Then, from your $HOME type: singularity pull
library://emartineznunez/default/automekin:<Tag> You can start an
instance of the container and run it using:

singularity instance start automekin\_<Tag>.sif automekin singularity
run instance://automekin

which will allow you to run low-level scripts. You can stop the instance
using:

singularity instance stop automekin

Note, however, that if you want to use G09/G16 you must bind it to the
container. To help you do so, we created the scripts SingularitygXX.sh
(XX=09/16), which can be downloaded as:

curl -LJO
<https://github.com/emartineznunez/Singularity_amk/raw/main/Singularityg09.sh>

curl -LJO
<https://github.com/emartineznunez/Singularity_amk/raw/main/Singularityg16.sh>

The script should be run with the complete path to the sif file as
argument as in the example:

SingularitygXX.sh $HOME/automekin\_<Tag>.sif

Note that SingularitygXX.sh will start a new instance of the container
every time it is executed. To list the instances use:

singularity instance list

And stop them as indicated above.

Build from source The most recent and up to date version is avaialable
at:

<https://github.com/emartineznunez/AutoMeKin>

You can build (system-wide) from source using this script (on a CentOS):

curl -LJO
<https://raw.githubusercontent.com/emartineznunez/AutoMeKin/main/Build_Centos.sh>

You can also check how to install AutoMeKin using Ubuntu:

<https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/master/AutoMeKin.ipynb>

which involves the installation of the following dependencies (before
the installation of AutoMeKin):

Installing dependencies Before installing amk for the first time, be
aware that the following packages are needed:

\- GNU Autoconf

\- GNU Bash

\- GNU bc

\- environment-modules

\- GNU Awk (gawk)

\- GNU C Compiler (gcc)

\- Gnuplot

\- GNU Fortran Compiler (gfortran)

\- GNU Parallel

\- SQLite (version \>= 3)

\- Zenity

You can install the missing ones manually, or you can use the scripts
located in amk-SOURCE-2021 and called
install-required-packages-distro.sh (where distro=ubuntu-16.4lts,
centos7 or sl7), which will do the work for you.The ubuntu-16.4lts
script installs all dependencies, but for the RHEL derivatives (centos7
and sl7) you have to install parallel separately, and you have two
choices:

a\) install-gnu-parallel-from-source.sh. This script installs parallel
latest version from source thanks to Ole Tange (the author). Also it can
fallback to a user private installation into $HOME/bin if you have not
administrator permisions to install it globally.

b\) install-gnu-parallel-from-epel.sh. Enables the EPEL repository and
installs parallel from it.

The program employs python3 and the following python3 libraries are
needed (which can be easily installed with pip):

\- ASE (version \>= 3.21.1)

\- Matplotlib (version \>= 3.3.4)

\- NetworkX (version \>= 2.5)

\- NumPy (version \>= 1.19.5)

\- SciPy (version \>= 1.5.4)

These packages might also be useful to analyze the results:

\- molden

\- sqlitebrowser

Installation

Once the above packages are installed, you can now install AutoMeKin
following these steps:. Clone AutoMeKin from GitHub:

git clone <https://github.com/emartineznunez/AutoMeKin.git>

Go to the AutoMeKin folder.

cd AutoMeKin

Now type:

autoreconf -i

./configure --prefix=path_to_program

Where you can specify where you want to install it, e.g., /opt/AutoMeKin

Finally, complete the installation:

make make install make clean The last command (make clean) is only
necessary if you want to remove from the src directory the object files
and executables created in the compilation process.

For convenience, and once “Environment Modules” has been installed, you
should add the following line to your .bashrc file:

module use path_to_program/modules

where path_to_program is the path where you installed amk (e.g.,
$HOME/amk-2021).
