program bbfs
implicit none
! the ts is located according to the interatomic distances
integer,dimension(:,:,:),allocatable :: nrxn ,tnm 
integer,dimension(:,:),allocatable :: nm,nmold,nbir,nbir2,nbir3
integer,dimension(:),allocatable :: code, nstepijojn
integer,dimension(:),allocatable :: npath,jold,jnew
integer,dimension(:),allocatable :: kkj  ,kkj3
integer, parameter :: one=1, zero=0
real,dimension(:,:),allocatable :: q
real,dimension(:,:),allocatable :: r,rnei,rout,rscale
real,dimension(:),allocatable :: rmin,rmax
logical, dimension(:),allocatable :: bir 
character*2,dimension(:),allocatable :: symb

integer natom,nsteps,irange,npathc,i,j,irange2,idum,iexp,iunit,idlt,nmmb
integer jstep,kk,iii,k,prod1,prod2,ijk,ijc,tnb0,jfinish,diff1,diff2
real xdum,ydum,zdum,dum


! read the number of trajs,atoms and steps along the traj
read(*,*) irange
irange2=irange/2
read(*,*) natom
read(*,*) nsteps
! allocate arrays
allocate(nrxn(natom,natom,natom),tnm(natom,natom,natom))
allocate(q(3*natom,nsteps),nbir(natom,nsteps),nbir2(3*natom,nsteps),nbir3(natom,nsteps))
allocate(r(natom,natom),rnei(natom,natom),rout(natom,natom),rscale(natom,natom),nm(natom,natom),nmold(natom,natom))
allocate(npath(0:nsteps),rmin(natom),rmax(natom),jold(natom),jnew(natom),bir(natom),kkj(nsteps),kkj3(nsteps),code(0:nsteps))
allocate(nstepijojn(0:nsteps))
allocate(symb(natom))
! initialize some variables and arrays
! irange=20 fs is the range to see if there is a 1st change in connectivities
! irange=20
npathc=0
nrxn=0
tnm=0
kkj=0 
kkj3=0
jfinish=nsteps
npath(0)=-100

! Reading, conn matrix and scale matrix
open(1,file='ConnMat')
open(2,file='ScalMat')
do i=1,natom
   read(1,*) (nm(i,j),j=1,natom)
enddo 
nmold=nm
code(npathc)=0
tnb0=sum(nm)
idum=0
do iii=1,natom
   do kk=iii+1,natom 
      idum=idum+1
      iexp=natom*(natom-1)/2-idum
      code(npathc)=code(npathc)+nm(iii,kk)*2**iexp
   enddo
enddo
! rscale matrix elements
do i=1,natom
   rscale(i,i)=1
   do j=i+1,natom
      read(2,*) rscale(i,j)
      dum=rscale(i,j)
      rscale(j,i)=dum
   enddo
enddo
close(1)
close(2)

! loop over the steps
steps: do jstep=1,nsteps
   if(jstep==(jfinish+irange)) exit steps 
! loop over the atoms
   do i=1,natom
rij:  do j=1,natom
         if(i==1) read(*,*) symb(j),q(3*j-2,jstep),q(3*j-1,jstep),q(3*j,jstep)
         xdum=q(3*i-2,jstep)-q(3*j-2,jstep)
         ydum=q(3*i-1,jstep)-q(3*j-1,jstep)
         zdum=q(3*i  ,jstep)-q(3*j  ,jstep)
         r(i,j)=sqrt(xdum*xdum+ydum*ydum+zdum*zdum)/rscale(i,j)
         rnei(i,j)=r(i,j)*nm(i,j)
         rout(i,j)=r(i,j)*(1-nm(i,j))
      enddo rij
! min of r(i,j) for the atoms that not the neighbouts at every step
      rmin=minval(rout,2,mask=rout>0)
      jnew=minloc(rout,2,mask=rout>0)
! max of r(i,j) for the neighs at every step
      rmax=maxval(rnei,2)
      jold=maxloc(rnei,2)

! if an atom which is not in the list of neighs is closer to i than all the neighs, then ... 
      if(rmin(i)<=rmax(i))   then
         nrxn(i,jold(i),jnew(i))=nrxn(i,jold(i),jnew(i))+1
         if(nrxn(i,jold(i),jnew(i))==1) then
            tnm(i,jold(i),jnew(i))=0
            tnm(i,jnew(i),jold(i))=0
            tnm(jold(i),jnew(i),i)=0
         endif
         nstepijojn(0)=jstep-1 
         nstepijojn(nrxn(i,jold(i),jnew(i)))=jstep
         diff1=nstepijojn(nrxn(i,jold(i),jnew(i)))-nstepijojn(nrxn(i,jold(i),jnew(i))-1)
         if(diff1>1) nrxn(i,jold(i),jnew(i))=0
         if(rnei(i,jold(i))<1.1.and.nrxn(i,jold(i),jnew(i))>3) tnm(i,jold(i),jnew(i))=1 
         if(rout(i,jnew(i))<1.1.and.nrxn(i,jold(i),jnew(i))>3) tnm(i,jnew(i),jold(i))=1 
         if(r(jold(i),jnew(i))<1.1.and.nrxn(i,jold(i),jnew(i))>3) tnm(jold(i),jnew(i),i)=1 
         if(rnei(i,jold(i))>3) tnm(i,jold(i),jnew(i))=0 
         if(rout(i,jnew(i))>3) tnm(i,jnew(i),jold(i))=0 
         if(r(jold(i),jnew(i))>3) tnm(jold(i),jnew(i),i)=0 
! new path: change in connectivities
         if(nrxn(i,jold(i),jnew(i))>irange) then 
            npathc=npathc+1
            npath(npathc)=jstep-irange-1
            nmold=nm
! change in connectivities
            nm(i,jold(i))=tnm(i,jold(i),jnew(i))
            nm(i,jnew(i))=tnm(i,jnew(i),jold(i))
            nm(jold(i),jnew(i))=tnm(jold(i),jnew(i),i)
            nm(jold(i),i)=nm(i,jold(i))
            nm(jnew(i),i)=nm(i,jnew(i))
            nm(jnew(i),jold(i))=nm(jold(i),jnew(i))
! re-set variables 
            nrxn(i,:,:)=0
! calculate the code of the new structure
            code(npathc)=0
            idum=0
            bir=any((nm-nmold)/=0, dim=2)
            do iii=1,natom
               if(bir(iii)) then
                  kkj(npathc)=kkj(npathc)+1
                  nbir(kkj(npathc),npathc)=iii
               endif
               do kk=iii+1,natom 
                  idum=idum+1
                  iexp=natom*(natom-1)/2-idum
                  code(npathc)=code(npathc)+nm(iii,kk)*2**iexp
               enddo
            enddo
         endif
      endif
! 
   enddo 
!
enddo steps


if(npathc>50) npathc=50
print "(t3,a,i7)","Number of paths",npathc
npath(npathc+1)=nsteps+100
if(npathc>0) then
npc:   do ijk=1,npathc
      prod1=1
      prod2=1
      ijc=0
! join paths that are 20 fs apart
      diff1=npath(ijk)-npath(ijk-1) 
      diff2=npath(ijk+1)-npath(ijk) 
      if(diff1>irange.and.diff2>irange) then
         nbir2(:,ijk)=nbir(:,ijk)
      else if(diff1<=irange.and.diff2>irange) then
         nbir2(1:kkj(ijk),ijk)=nbir(1:kkj(ijk),ijk)
         nbir2(kkj(ijk)+1:kkj(ijk)+kkj(ijk-1),ijk)=nbir(1:kkj(ijk-1),ijk-1)
      else if(diff2<=irange.and.diff1>irange) then
         nbir2(1:kkj(ijk),ijk)=nbir(1:kkj(ijk),ijk)
         nbir2(kkj(ijk)+1:kkj(ijk)+kkj(ijk+1),ijk)=nbir(1:kkj(ijk+1),ijk+1)
         ijc=1
      else if(diff2<=irange.and.diff1<=irange) then
         nbir2(1:kkj(ijk),ijk)=nbir(1:kkj(ijk),ijk)
         nbir2(kkj(ijk)+1:kkj(ijk)+kkj(ijk+1),ijk)=nbir(1:kkj(ijk+1),ijk+1)
         nbir2(kkj(ijk)+kkj(ijk+1)+1:kkj(ijk)+kkj(ijk+1)+kkj(ijk-1),ijk)=nbir(1:kkj(ijk-1),ijk-1)
      endif
nb3:  do kk=1,natom
         k=1
         do while(nbir2(k,ijk)>0) 
            if(nbir2(k,ijk)==kk) then 
               kkj3(ijk)=kkj3(ijk)+1
               nbir3(kkj3(ijk),ijk)=kk
               cycle nb3
            endif
            k=k+1
         enddo 
      enddo nb3
      print "(t3,a,i5,a,i5,a,100(i5))","Path=",ijk," Step=",npath(ijk)," Atoms involved=",(nbir3(k,ijk),k=1,kkj3(ijk))
      print "(t3,a,i5,a,i5)","Path=",ijk," Joint path=",ijc
      do j=1,irange
         idlt=npath(ijk)-irange2+j
         if(idlt<1) idlt=1
         iunit=100*ijk+j
         open(11,file='partial_opt/fort.'//trim(str(iunit)))
         do i=1,natom
            nmmb=one
            do kk=1,kkj3(ijk)
               if(i==nbir3(kk,ijk)) nmmb=zero
            enddo
            write(11,6) symb(i),q(3*i-2,idlt),nmmb,q(3*i-1,idlt),nmmb,q(3*i,idlt),nmmb
         enddo
         close(11)
      enddo 
   enddo npc
endif
print "(t3,a,/)","*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*"
6 format(a,3(f20.10,i5))
!

contains

character(len=20) function str(k)
   integer, intent(in) :: k
   write(str,*) k
   str = adjustl(str)
end function str


end program  bbfs

