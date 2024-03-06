AC_INIT([amk], [2021], [emilio.nunez@usc.es],[amk-SOURCE])
AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([src/bbfs.f90])
AC_PREFIX_DEFAULT([$HOME/AC_PACKAGE_NAME-AC_PACKAGE_VERSION])

AC_PROG_AWK
if test x"$AWK" != x"gawk" ; then
    AC_MSG_ERROR([Please install GNU gawk package before proceeding.])
fi

AC_PROG_LN_S
AC_PROG_CC
AC_PROG_F77([gfortran])
AC_PROG_FC([gfortran])

if test x"$FC" != x"gfortran" ; then
    AC_MSG_ERROR([Please install gfortran compiler before proceeding.])
fi


AM_PATH_PYTHON([3])

AC_PATH_PROG(PYTHON3, python3, no)
if test x"$PYTHON3" = xno; then
	AC_MSG_ERROR([Please install python3 or create symbolic link python3 before proceeding.])
fi

AC_MSG_CHECKING(for numpy scipy ase networkx)
$PYTHON -c "import numpy,scipy,ase,networkx;" 2>/dev/null
if test $? == 0; then
	AC_MSG_RESULT([found])
else
	AC_MSG_ERROR([not found numpy, scipy and/or ase])
fi

AC_CHECK_PROG(PARALLELS_CHECK,parallel,yes)
if test x"$PARALLELS_CHECK" != x"yes" ; then
    AC_MSG_ERROR([Please install GNU Parallel package before proceeding.])
fi

AC_CHECK_PROG(SQLITE_CHECK,sqlite3,yes)
if test x"$SQLITE_CHECK" != x"yes" ; then
    AC_MSG_ERROR([Please install sqlite3 package before proceeding.])
fi

AC_PATH_PROG(GNUPLOT, gnuplot, no)
if test x"$GNUPLOT" = xno; then
	AC_MSG_ERROR([Please install gnuplot package before proceeding.])
fi

AC_PATH_PROG(BC_CALCULATOR, bc, no)
if test x"$BC_CALCULATOR" = xno; then
	AC_MSG_ERROR([Please install bc package before proceeding.])
fi

AC_PATH_PROG(svnversioncommand, svnversion)
if test "X$svnversioncommand" = "X" || test "`$svnversioncommand -n '.'`" = "Unversioned directory" || test "`$svnversioncommand -n '.'`" = "exported"; 
then
AC_DEFINE_UNQUOTED(AMK_BUILD, ["`cat share/amk_build`"], [repository svn version])
else
AC_DEFINE_UNQUOTED(AMK_BUILD, ["`svnversion -n`"], [repository svn version])
`svnversion -n > share/amk_build`
fi

AC_CONFIG_FILES([Makefile])
AC_OUTPUT([ src/Makefile \
	    src/HL/Makefile\
	     scripts/Makefile\
	     scripts/HLscripts/Makefile\
	     scripts/MOPAC_DEV/Makefile\
      	     docs/Makefile\
	     modules/Makefile\
	     examples/Makefile \
	     share/Makefile])

AC_MSG_NOTICE([

=======================================================

"Environment Modules" (http://modules.sourceforge.net/)
has not been checked. Make sure it is installed.
 
After installation, add this to your .bashrc file: 

module use $prefix/modules		 

=======================================================

])
