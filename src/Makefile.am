
ATSYMB        = atsymb.f90
CONSTANTS     = constants.f90

BBFS          = bbfs.f90
INTERN        = intern.f90
KMC           = kmc.f90
KMCEND        = kmcEND.f90
NM            = nm.f90
RRKM          = omegas.f90 constants_rrkm.f90 rrkm.f
ROTATE        = rotate.f90
SPRINT        = sprint.f
SPRINT2       = sprint2.f
SYMM0         = symm0.f
SYMM          = symm.f
TERMO         = termo.f90
TST           = tst.f90


bin_PROGRAMS=bbfs.exe  intern.exe  \
	     kmc.exe kmcEND.exe nm.exe  \
	     rrkm.exe rotate.exe sprint.exe sprint2.exe symm0.exe \
	     symm.exe termo.exe tst.exe     

bbfs_exe_SOURCES         = $(BBFS)
intern_exe_SOURCES       = $(ATSYMB) $(INTERN)
kmc_exe_SOURCES          = $(KMC)
kmcEND_exe_SOURCES       = $(KMCEND)
nm_exe_SOURCES           = $(CONSTANTS) $(NM) $(ATSYMB)
rrkm_exe_SOURCES         = $(RRKM) $(MOD3) $(MOD4)
rotate_exe_SOURCES       = $(ROTATE) $(ATSYMB) $(CONSTANTS)
sprint_exe_SOURCES       = $(SPRINT)
sprint2_exe_SOURCES      = $(SPRINT2)
symm0_exe_SOURCES        = $(SYMM0)
symm_exe_SOURCES         = $(SYMM)
termo_exe_SOURCES        = $(TERMO) $(ATSYMB) $(CONSTANTS)
tst_exe_SOURCES          = $(TST) $(CONSTANTS)

