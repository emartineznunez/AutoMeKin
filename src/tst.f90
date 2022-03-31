program tst
use constants 
implicit none
integer, parameter :: dp = selected_real_kind(15,307)
! program to calculate tst rate
real (dp) :: deltag,rate,temp,deg
! read deltag (in kcal/mol) and temperature (in K)
read(*,*) deltag,temp,deg
rate=deg*boltz*temp/planck*exp(-deltag/r/temp)
! rate in s-1
print*, rate

end program tst 

