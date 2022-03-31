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

program initialqv
use constants 
use atsymb
use rancom
implicit none
! program to calculate initial q and v for a drc mopac run
! Activate with a microcanonical ensemble
! enmta is the energy of the microcanonical ensemble in kcal/mol
! nmbar is the number of normal modes of the molecule
! nlms is the number of modes excited
! inlms are the indixes of the normal modes to be excited 
real(kind=8) :: rand
integer(kind=8) :: iclock0,iclock,flagseed
real,dimension(:),allocatable :: ampa,wwa,ww,coor,dcoor,q,p,w,qz,qq,pp,v,norm
real,dimension(:,:),allocatable :: c
real :: enmta,dum,sdum,wt,rnd
real, dimension(3) :: vcm,qcm
integer :: nn,nmbar,i,n,k,j,ii,nlin,ncbl,idum,jfrst,jlast,nlms,icount
integer, dimension(:),allocatable :: inlms
character*2,dimension(:),allocatable :: fasymb
! read number of modes and energy 
read(*,*) flagseed
read(*,*) n
allocate(q(3*n),p(3*n),v(3*n),qz(3*n),qq(3*n),pp(3*n),w(n),fasymb(n))
do i=1,n
   read(*,*) fasymb(i),qz(3*i-2),qz(3*i-1),qz(3*i)
   do j = 1 , natom
!      if(string_tolower(fasymb(i))==asymb(j)) w(i)=ams(j) 
      if(fasymb(i)==asymb(j)) w(i)=ams(j) 
   enddo
enddo
read(*,*) nlin
wt=sum(w)
nmbar=3*n-6+nlin
! read the energy (in kcal/mol)
read(*,*) enmta
!****new
read(*,*) nlms 
allocate(ampa(nmbar),wwa(nmbar),ww(nmbar),coor(nmbar),dcoor(nmbar),c(3*n,nmbar),norm(nmbar),inlms(nmbar))
if(nlms>0) read(*,*) (inlms(i),i=1,nlms)
if(nlms==0) then
   inlms=(/ (i,i=1,nmbar) /)
   nlms=nmbar
endif
nmbar=inlms(nlms)
!****new
DUM=ENMTA*C1
! normal modes-1
NN=NMBAR-1
! read the freqs and eigenvectors 
! ncbl is the number of complete blocks (in freq MOPAC file) 8 columns
if(mod(real(nmbar),8.)==0) then
   ncbl=nmbar/8
else
   ncbl=nmbar/8+1
endif
! read the first complete blocks
DO I=1,ncbl
   if(i<ncbl) then
      jfrst=8*i-7
      jlast=8*i
   else
      jfrst=8*ncbl-7
      jlast=nmbar
   endif
   read(*,*) (wwa(j),j=jfrst,jlast)
   do ii=1,3*n
      read(*,*) idum,(c(ii,j),j=jfrst,jlast)
   enddo
enddo
ww=wwa*c6
! normalize the eigenvectors
norm=0
do i=1,nmbar
   do j=1,n
      norm(i)=norm(i)+c(3*j-2,i)*c(3*j-2,i)*w(j)
      norm(i)=norm(i)+c(3*j-1,i)*c(3*j-1,i)*w(j)
      norm(i)=norm(i)+c(3*j  ,i)*c(3*j  ,i)*w(j)
   enddo
   norm(i)=sqrt(norm(i))
   do j=1,n
      c(3*j-2,i)=c(3*j-2,i)/norm(i)
      c(3*j-1,i)=c(3*j-1,i)/norm(i)
      c(3*j  ,i)=c(3*j  ,i)/norm(i)
   enddo
enddo
!call exit
!
! random_number generator
! it ensures a different random sequence every time is run

CALL SYSTEM_CLOCK(COUNT=iclock0)
if(flagseed==0) iclock=iclock0
if(flagseed>0) iclock=flagseed
CALL RANDST(iclock)


!
icount=0
do i=1,nn
   do j=1,nlms
      if(i==inlms(j)) then
         icount=icount+1
         rand=rand0(0)
         SDUM=1.0D0/DBLE(nlms-Icount)
         SDUM=DUM*(1.0D0-RAND**SDUM)
         DUM=DUM-SDUM
         AMPA(I)=SQRT(2.0D0*SDUM)/WW(I)
      endif
   enddo
ENDDO
AMPA(NMBAR)=SQRT(2.0D0*DUM)/WW(NMBAR)

! coor and dcoor are the Q and QDOT vectors
do i=1,nmbar
   rand=rand0(0)
   dum=2.d0*pi*rand
! for low freq modes give only kinetic energy
   if(wwa(i)<=1000) then
     coor(i)=0.d0
     dcoor(i)=-ww(i)*ampa(i)
   else
     coor(i)=ampa(i)*cos(dum)
     dcoor(i)=-ww(i)*ampa(i)*sin(dum)
   endif
enddo


!
!  TRANSFORM FROM NORMAL MODE TO CARTESIAN COORDINATES AND VELOCIT
!
q=0
p=0
DO I=1,N
   DO K=1,3
      J=3*I+1-K
      DO ii=1,NMbar
         Q(J)=Q(J)+C(J,ii)*COOR(ii)
         P(J)=P(J)+C(J,ii)*DCOOR(ii)
      ENDDO
      P(J)=P(J)*W(I)
      Q(J)=Q(J)+QZ(J)
   ENDDO
ENDDO

!! remove center of mass velocity
vcm=0
qcm=0
DO I=1,N
   VCM(1)=VCM(1)+P(3*i-2)
   VCM(2)=VCM(2)+P(3*i-1)
   VCM(3)=VCM(3)+P(3*i  )
   QCM(1)=QCM(1)+W(i)*Q(3*i-2)
   QCM(2)=QCM(2)+W(i)*Q(3*i-1)
   QCM(3)=QCM(3)+W(i)*Q(3*i  )
ENDDO
vcm=vcm/wt
qcm=qcm/wt

DO I=1,N
   PP(3*i-2)=P(3*i-2)-W(i)*VCM(1)
   PP(3*i-1)=P(3*i-1)-W(i)*VCM(2)
   PP(3*i  )=P(3*i  )-W(i)*VCM(3)
   QQ(3*i-2)=Q(3*i-2)-QCM(1)
   QQ(3*i-1)=Q(3*i-1)-QCM(2)
   QQ(3*i  )=Q(3*i  )-QCM(3)
ENDDO
q=qq
p=pp
!write(*,*) "Cartesian coordinates (Angstroms)"
!write(*,*) 
do i=1,n
   write(*,*) fasymb(i),q(3*i-2),"1",q(3*i-1),"1",q(3*i),"1"
enddo
!write(*,*) "Cartesian velocities (cm/s)"
write(*,*) 
do i=1,n
   v(3*i-2)=vf*p(3*i-2)/w(i)
   v(3*i-1)=vf*p(3*i-1)/w(i)
   v(3*i  )=vf*p(3*i  )/w(i)
   write(*,*) v(3*i-2),v(3*i-1),v(3*i)
enddo

contains
function string_tolower( string ) result (new)
    character(len=*)           :: string

    character(len=len(string)) :: new

    integer                    :: i
    integer                    :: k

    new    = string
    do i = 1,len(string)
        k = iachar(string(i:i))
        if ( k >= iachar('A') .and. k <= iachar('Z') ) then
            k = k + iachar('a') - iachar('A')
            new(i:i) = achar(k)
        endif
    enddo
end function string_tolower


end program initialqv

