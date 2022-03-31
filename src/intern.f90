program intern
use atsymb
implicit none
real, parameter :: pi=3.1415927
integer, parameter :: dp = selected_real_kind(15,307)
real(dp),dimension(:),allocatable :: x,y,z
real(dp),dimension(:,:),allocatable :: dx,dy,dz,r
real(dp) :: angijk,angjkl,fnum,fnum2,cosang,cosang2,a1,a2,b1,b2,c1,c2
real(dp) :: rnum,rden,arg,tau,sos,diff1,diff2
integer :: ii,jj,i,j,k,l,n
character*2,dimension(:),allocatable :: fasymb

read(*,*) n
read(*,*) 
allocate(x(n),y(n),z(n),fasymb(n))
allocate(dx(n,n),dy(n,n),dz(n,n),r(n,n))
do ii=1,n
   read(*,*) fasymb(ii),x(ii),y(ii),z(ii)
enddo
read(*,*) i,j,k,l
do ii=1,n
   do jj=1,n
      dx(ii,jj)=x(ii)-x(jj)
      dy(ii,jj)=y(ii)-y(jj)
      dz(ii,jj)=z(ii)-z(jj)
   enddo
enddo
do ii=1,n
   do jj=1,n
      r(ii,jj)=sqrt(dx(ii,jj)*dx(ii,jj) + dy(ii,jj)*dy(ii,jj) + dz(ii,jj)*dz(ii,jj))
   enddo
enddo
fnum= dx(i,j)*dx(k,j)+dy(i,j)*dy(k,j)+dz(i,j)*dz(k,j)
fnum2=dx(j,k)*dx(l,k)+dy(j,k)*dy(l,k)+dz(j,k)*dz(l,k)
cosang=  fnum/r(i,j)/r(k,j)
cosang2=fnum2/r(j,k)/r(l,k)
angijk=acos(cosang )
angjkl=acos(cosang2)
diff1=(cosang+1)
diff2=(cosang2+1)
if(diff1<0.004.or.diff2<0.004) then
   print*, "angle close to 180 degrees. Abort"
   call exit
endif

a1=(dy(i,j)*dz(k,j)-dy(k,j)*dz(i,j))
a2=(dy(j,k)*dz(l,k)-dy(l,k)*dz(j,k))
b1=(dx(k,j)*dz(i,j)-dx(i,j)*dz(k,j))
b2=(dx(l,k)*dz(j,k)-dx(j,k)*dz(l,k))
c1=(dx(i,j)*dy(k,j)-dx(k,j)*dy(i,j))
c2=(dx(j,k)*dy(l,k)-dx(l,k)*dy(j,k))

rnum=a1*a2+b1*b2+c1*c2
rden=r(i,j)*r(j,k)*r(j,k)*r(k,l)*sin(angijk)*sin(angjkl)
arg=rnum/rden
if(arg>1)arg=1
if(arg<-1)arg=-1
tau=acos(arg)

sos=(b1*c2)*dx(k,j)-(b2*c1)*dx(k,j)-(a1*c2)*dy(k,j)+(a2*c1)*dy(k,j)+(a1*b2)*dz(k,j)-(b1*a2)*dz(k,j)
if(sos<0)tau=-tau

print*, fasymb(i),r(i,j),"1",angijk*180/pi,"1",tau*180/pi,"-1",j,k,l
end program intern
