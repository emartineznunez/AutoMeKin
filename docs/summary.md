

## Summary of keywords and options<a name="sko"></a>


```
sampling^1 LowLevel^2 General Method Screening Kinetics
```

#### MD

```
mopac
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo, recalc
```
```
ntraj, seed,
atoms,
factorflipv, fs,
multiple_minima,
post_proc: bbfs,
temp, thmass,
nbondsfrozen,
nbondsbreak,
nbondsform,
Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
```
qcore
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo
```
```
ntraj, seed, fs,
multiple_minima,
post_proc: bbfs,
temp
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
MD-micro mopac^

```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo, recalc
```
```
ntraj, seed,
etraj,
factorflipv, fs,
modes,
multiple_minima,
post_proc: bbfs,
nbondsfrozen,
nbondsbreak,
nbondsform,
Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
#### BXDE

```
mopac
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo, recalc
```
```
ntraj, fs,
Friction, Hookean,
multiple_minima,
post_proc: bbfs,
bots, temp,
Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
```
qcore
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo
```
```
ntraj, fs,
Friction, Hookean,
multiple_minima,
post_proc: bbfs,
temp
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
external

```
mopac
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo, recalc
```
```
ntraj, post_proc:
bbfs, bots,
Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
```
qcore
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
```
```
ntraj, post_proc:
bbfs
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```

```
mult, iop,
LowLevelTSopt,
pseudo
```
```
ChemKnow mopac^
```
```
molecule,
LowLevel,
HighLevel,
HL_rxn_network,
IRCpoints,
charge, Memory,
mult, iop,
LowLevelTSopt,
pseudo, recalc
```
```
active, nbonds,
startd, neighbors,
comb22, Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
```
associati
on
```
```
mopac
```
```
molecule,
fragmentA,
fragmentB,
LowLevel
```
```
rotate, Nassoc
MAPEmax,
BAPEmax,
eigLmax
```
```
qcore
```
```
molecule,
fragmentA,
fragmentB,
LowLevel
```
```
rotate, Nassoc
```
```
MAPEmax,
BAPEmax,
eigLmax
```
```
vdW
```
```
mopac
```
```
molecule,
fragmentA,
fragmentB,
LowLevel,
HighLevel,
IRCpoints,
charge, Memory,
iop,
LowLevelTSopt,
pseudo, recalc
```
```
rotate, Nassoc,
ntraj, fs,
Friction, Hookean,
multiple_minima,
post_proc: bbfs,
Use_LET
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
```
qcore
```
```
molecule,
fragmentA,
fragmentB,
LowLevel,
HighLevel,
IRCpoint,
charge, Memory,
iop,
LowLevelTSopt,
pseudo
```
```
rotate, Nassoc,
ntraj, fs,
Friction, Hookean,
multiple_minima,
post_proc: bbfs
```
```
imagmin,
MAPEmax,
BAPEmax,
eigLmax
```
```
Energy,
Temperature,
imin, nmol,
Stepsize,
MaxEn,
ImpPaths
```
(^1) Value of sampling keyword (in section: Method). (^2) First value of LowLevel keyword, i.e., program, (in section
General).
