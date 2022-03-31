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

program rotate
use constants 
use atsymb
use rancom
implicit none
! program to rotate a molecule about its euler angles
real(kind=8) :: rand
integer(kind=8) :: iclock
real, dimension(:), allocatable :: rr
real :: twopi,rnd,phi,csthta,chi,thta,snthta,csphi,snchi,cschi,snphi
real :: rxx, rxy,rxz,ryx,ryy,ryz,rzx,rzy,rzz,xcm1,ycm1,zcm1,xcm2,ycm2,zcm2,wt,x,y,z
real :: dist,distm,xdum,ydum,zdum,rmin
integer :: i,n1,n,j,iii,nc,ijk,at1,at2

real,dimension(:),allocatable :: q,qq,w
real, dimension(3) :: vcm,qcm
character*2,dimension(:),allocatable :: fasymb
read(*,*) n,n1,dist,distm
read(*,*) at1,at2
allocate(q(3*n),qq(3*n),fasymb(n),w(n),rr(n1*(n-n1)))
do i=1,n
   read(*,*) fasymb(i),q(3*i-2),q(3*i-1),q(3*i)
   do j = 1 , natom
      if(fasymb(i)==asymb(j)) w(i)=ams(j)
   enddo
enddo
! com of second monomer
xcm2=0
ycm2=0
zcm2=0
wt=0
do i=n1+1,n
   xcm2=xcm2+w(i)*q(3*i-2) 
   ycm2=ycm2+w(i)*q(3*i-1) 
   zcm2=zcm2+w(i)*q(3*i  ) 
   wt=wt+w(i)
enddo
xcm2=xcm2/wt
ycm2=ycm2/wt
zcm2=zcm2/wt
do i=n1+1,n
   if(at2==-1) then
      qq(3*i-2)=q(3*i-2)-xcm2
      qq(3*i-1)=q(3*i-1)-ycm2
      qq(3*i  )=q(3*i  )-zcm2
   else
      qq(3*i-2)=q(3*i-2)-q(3*at2-2)
      qq(3*i-1)=q(3*i-1)-q(3*at2-1)
      qq(3*i  )=q(3*i  )-q(3*at2  )
   endif
enddo

! com of first monomer
xcm1=0
ycm1=0
zcm1=0
wt=0
do i=1,n1
   xcm1=xcm1+w(i)*q(3*i-2) 
   ycm1=ycm1+w(i)*q(3*i-1) 
   zcm1=zcm1+w(i)*q(3*i  ) 
   wt=wt+w(i)
enddo
xcm1=xcm1/wt
ycm1=ycm1/wt
zcm1=zcm1/wt
do i=1,n1
   if(at1==-1) then
      qq(3*i-2)=q(3*i-2)-xcm1
      qq(3*i-1)=q(3*i-1)-ycm1
      qq(3*i  )=q(3*i  )-zcm1 
   else
      qq(3*i-2)=q(3*i-2)-q(3*at1-2)
      qq(3*i-1)=q(3*i-1)-q(3*at1-1)
      qq(3*i  )=q(3*i  )-q(3*at1  )
   endif
enddo

twopi=2*pi

CALL SYSTEM_CLOCK(COUNT=iclock)
CALL RANDST(iclock)


do iii=1,10000000
!
   rand=rand0(0)
   PHI=TWOPI*RAND
   rand=rand0(0)
   CSTHTA=2.0D0*RAND-1.0D0
   rand=rand0(0)
   CHI=TWOPI*RAND
   THTA=ACOS(CSTHTA)
   SNTHTA=SIN(THTA)
   SNPHI=SIN(PHI)
   CSPHI=COS(PHI)
   SNCHI=SIN(CHI)
   CSCHI=COS(CHI)
   RXX=CSTHTA*CSPHI*CSCHI-SNPHI*SNCHI
   RXY=-CSTHTA*CSPHI*SNCHI-SNPHI*CSCHI
   RXZ=SNTHTA*CSPHI
   RYX=CSTHTA*SNPHI*CSCHI+CSPHI*SNCHI
   RYY=-CSTHTA*SNPHI*SNCHI+CSPHI*CSCHI
   RYZ=SNTHTA*SNPHI
   RZX=-SNTHTA*CSCHI
   RZY=SNTHTA*SNCHI
   RZZ=CSTHTA
!print*, n
!print*,
   DO I=N1+1,N
      x=QQ(3*i-2)*RXX+QQ(3*i-1)*RXY+QQ(3*i)*RXZ
      y=QQ(3*i-2)*RYX+QQ(3*i-1)*RYY+QQ(3*i)*RYZ
      z=QQ(3*i-2)*RZX+QQ(3*i-1)*RZY+QQ(3*i)*RZZ
      q(3*i-2)=x
      q(3*i-1)=y
      q(3*i  )=z
   ENDDO

   rand=rand0(0)
   PHI=TWOPI*RAND
   rand=rand0(0)
   CSTHTA=2.0D0*RAND-1.0D0
   rand=rand0(0)
   CHI=TWOPI*RAND
   THTA=ACOS(CSTHTA)
   SNTHTA=SIN(THTA)
   SNPHI=SIN(PHI)
   CSPHI=COS(PHI)
   SNCHI=SIN(CHI)
   CSCHI=COS(CHI)
   RXX=CSTHTA*CSPHI*CSCHI-SNPHI*SNCHI
   RXY=-CSTHTA*CSPHI*SNCHI-SNPHI*CSCHI
   RXZ=SNTHTA*CSPHI
   RYX=CSTHTA*SNPHI*CSCHI+CSPHI*SNCHI
   RYY=-CSTHTA*SNPHI*SNCHI+CSPHI*CSCHI
   RYZ=SNTHTA*SNPHI
   RZX=-SNTHTA*CSCHI
   RZY=SNTHTA*SNCHI
   RZZ=CSTHTA
   nc=0
   DO I=1,N1
      x=QQ(3*i-2)*RXX+QQ(3*i-1)*RXY+QQ(3*i)*RXZ
      y=QQ(3*i-2)*RYX+QQ(3*i-1)*RYY+QQ(3*i)*RYZ
      z=QQ(3*i-2)*RZX+QQ(3*i-1)*RZY+QQ(3*i)*RZZ
      q(3*i-2)=x+dist
      q(3*i-1)=y
      q(3*i  )=z
      do ijk=n1+1,n
         nc=nc+1
         xdum= q(3*i-2) - q(3*ijk-2)
         ydum= q(3*i-1) - q(3*ijk-1)
         zdum= q(3*i  ) - q(3*ijk  )
         rr(nc)=sqrt(xdum*xdum + ydum*ydum + zdum*zdum)
!         print*, nc,rr(nc)
      enddo
   ENDDO
   rmin=minval(rr)
!   print*, rmin
   if(rmin>distm) exit 
enddo
do i=1,n
   print*, fasymb(i),q(3*i-2),q(3*i-1),q(3*i)
enddo

end program rotate 
