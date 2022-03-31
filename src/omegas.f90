module omegas 
implicit none
! Definition of the constants
integer, parameter :: dp = selected_real_kind(15,307)
integer,dimension(:),allocatable :: nfrecr,nfrect
real(dp), dimension(:),allocatable :: ro,rots,w,wts,ke,wtemp,wdum
real(dp), dimension(:),allocatable :: sigmatsm,brottsm,sigmatsb,brottsb
real(dp), dimension(:),allocatable :: sigmam,brotm,sigmab,brotb
real(dp), dimension(:),allocatable :: r,rmin,wtsmin 
integer, dimension(:),allocatable :: ezpe0v
integer, dimension(:,:),allocatable :: nfrectv
integer :: ezpe0
real(dp) :: v0,v1,omega,enpuce
end module omegas 

