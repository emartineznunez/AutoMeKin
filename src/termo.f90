module rancom
implicit none
save
real(kind=8) :: RANLST(100)
integer(kind=8) :: ISEED3(8),IBFCTR
contains

SUBROUTINE RANDST(ISEED)
real :: diff
integer(kind=8) :: is,iseed
integer :: i
IBFCTR = 256
IS=ISEED
DO I=1,8
   ISEED3(I)=MOD(IS,IBFCTR)
   IS=IS/IBFCTR
enddo
DO I=1,8
   ISEED3(I) = ISEED3(I) + ISEED3(I)
enddo
DO I=1,8
   diff=ISEED3(I)-IBFCTR
   do while(diff>=0) 
      ISEED3(I) = ISEED3(I) - IBFCTR
      ISEED3(I+1) = ISEED3(I+1) + 1
      diff=ISEED3(I)-IBFCTR
   enddo
enddo
ISEED3(1) = ISEED3(1) + 1
DO I=1,8
   diff=ISEED3(I)-IBFCTR
   do while(diff>=0)
      ISEED3(I) = ISEED3(I) - IBFCTR
      ISEED3(I+1) = ISEED3(I+1) + 1
      diff=ISEED3(I)-IBFCTR
   enddo
enddo
DO I=1,100
   RANLST(I)=RAND1(ISEED3)
enddo
end SUBROUTINE RANDST

FUNCTION RAND0(IDUM) 
integer :: idum,j
real(kind=8) :: rand0
J=INT(99E0*RANLST(100))+1
RAND0 = RANLST(100)
RANLST(100)=RANLST(J)
RANLST(J)=RAND1(ISEED3)
END FUNCTION RAND0

FUNCTION RAND1(ISEED)
integer(kind=8) :: ip
integer :: i,j,k
real :: bi,rand1
integer(kind=8) :: iseed(8),IA(8),IC(8),ID(8)
DATA IA/45,127,149,76,45,244,81,88/
DATA BI/3.90625D-3/

ID=0
IC=0
big: DO J=1,8
   middle: DO I=1,9-J
      K=J+I-1
      IP=IA(J)*ISEED(I)
      do while(k<=8)
         IP=IP+ID(K)
         ID(K)=MOD(IP,IBFCTR)
         IP=IP/IBFCTR
         IF (IP==0) cycle middle
         k=k+1
       enddo
   enddo middle
enddo big
iseed=id

RAND1=FLOAT(ISEED(1))
DO I=2,8
   RAND1=FLOAT(ISEED(I))+RAND1*BI
enddo
RAND1=RAND1*BI
END FUNCTION RAND1

end module rancom

program termo
use atsymb
use constants
use rancom
implicit none
integer, parameter:: b8 = selected_real_kind(14)
real(b8), parameter :: conv = 204548.28_b8
real(b8) normal,ran1
real(b8), parameter :: mean = 0_b8
real(b8), parameter :: sigma = 1_b8
real, dimension (:),allocatable :: px,py,pz,w,vx,vy,vz,q
real :: desket,temp,temp0,factor,sumx,sumy,sumz,tempf,ener,totmass,thmass
integer(kind=8) :: iclock
integer :: n,i,j,nate,natefin
integer, dimension(:),allocatable :: inate
character*2,dimension(:),allocatable :: fasymb

! nate is the number of excited atoms
! inate are the indeces  of those atoms

CALL SYSTEM_CLOCK(COUNT=iclock)
CALL RANDST(iclock)


read(*,*) n
allocate(q(3*n),px(n),py(n),pz(n),vx(n),vy(n),vz(n),w(n),fasymb(n))
do i=1,n
   read(*,*) fasymb(i),q(3*i-2),q(3*i-1),q(3*i)
   do j = 1 , natom
      if(fasymb(i)==asymb(j)) w(i)=ams(j)
   enddo
enddo
px=0
py=0
pz=0

read(*,*) temp
read(*,*) nate
if(nate==0) then
   nate=n
   allocate(inate(nate))
   inate=(/ (i,i=1,n) /)
else
   allocate(inate(nate))
   read(*,*) (inate(i),i=1,nate)
endif 
read(*,*) thmass

desket=sqrt(r*temp)
sumx = 0.d0
sumy = 0.d0
sumz = 0.d0
natefin = 0.d0
do i = 1,n
   if(any(i .eq. inate)) then
      if(fasymb(i)=='H'.and.thmass==-1) then
         write(*,*) fasymb(i),'1.d1',q(3*i-2)," 1",q(3*i-1)," 1",q(3*i)," 1"
      else
         write(*,*) fasymb(i),q(3*i-2)," 1",q(3*i-1)," 1",q(3*i)," 1"
      endif
      if(w(i)>thmass) then
         totmass=totmass+w(i)
         px(i)=normal(mean,sigma)*desket*sqrt(w(i))
         py(i)=normal(mean,sigma)*desket*sqrt(w(i))
         pz(i)=normal(mean,sigma)*desket*sqrt(w(i))
         natefin=natefin+1
      endif
      sumx = sumx + px(i)
      sumy = sumy + py(i)
      sumz = sumz + pz(i)
   else
      write(*,*) fasymb(i),'1.d69',q(3*i-2)," 1",q(3*i-1)," 1",q(3*i)," 1"
   endif
enddo

ener=3*natefin*0.5*r*temp
write(66,*) "TEmp=",temp
write(66,*) "Ener=",ener
write(66,*) "Number of atoms to be excited=",natefin


write(*,*) 
sumx = sumx/totmass
sumy = sumy/totmass
sumz = sumz/totmass
!    make sure that the total linear momentum equals zero
temp0=0.d0
do i=1,n
   if(any(i .eq. inate)) then
     if(w(i)>thmass) then
        px(i) = px(i) - w(i)*sumx
        py(i) = py(i) - w(i)*sumy
        pz(i) = pz(i) - w(i)*sumz
        temp0=temp0+(px(i)**2+py(i)**2+pz(i)**2)/w(i)
     endif
   endif
enddo
! temp0 is the initial temperature
temp0=temp0/3/natefin/r
write(66,*) "Initial temp=",temp0
factor=sqrt(temp/temp0)
write(66,*) "factor",factor
tempf=0.d0
ener=0.d0
sumx = 0.d0
sumy = 0.d0
sumz = 0.d0
do i=1,n
   if(any(i .eq. inate) ) then  
      px(i) = px(i)*factor
      py(i) = py(i)*factor
      pz(i) = pz(i)*factor
      sumx = sumx + px(i)
      sumy = sumy + py(i)
      sumz = sumz + pz(i)
      tempf=tempf+(px(i)**2+py(i)**2+pz(i)**2)/w(i)
      ener=ener+0.5*(px(i)**2+py(i)**2+pz(i)**2)/w(i)
   endif
   vx(i)=px(i)/w(i)*conv
   vy(i)=py(i)/w(i)*conv
   vz(i)=pz(i)/w(i)*conv
   write(*,*) vx(i),vy(i),vz(i)
end do
tempf=tempf/3/natefin/r
write(66,*) "Final temp=",tempf
write(66,*) "Final ener=",ener,3*natefin*0.5*r*tempf
write(66,*) "SUmx,sumy,sumz",sumx,sumy,sumz

end program termo

function normal(mean,sigma) !returns a normal distribution 
use rancom
implicit none 
integer, parameter:: b8 = selected_real_kind(14)
real(b8) normal,tmp 
real(b8) mean,sigma 
integer flag 
real(b8) fac,gsave,rsq,r1,r2 
save flag,gsave 
data flag /0/ 
if (flag.eq.0) then 
rsq=2.0_b8 
   do while(rsq.ge.1.0_b8.or.rsq.eq.0.0_b8) ! new from for do 
      r1=2.0_b8*rand0(0)-1.0_b8 
      r2=2.0_b8*rand0(0)-1.0_b8 
      rsq=r1*r1+r2*r2 
   enddo 
   fac=sqrt(-2.0_b8*log(rsq)/rsq) 
   gsave=r1*fac 
   tmp=r2*fac 
   flag=1 
else 
   tmp=gsave 
   flag=0 
endif 
normal=tmp*sigma+mean 
return 
end function normal


