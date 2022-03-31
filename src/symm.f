      program symm
      implicit none

      integer nosp,i,j,k,n,nsea,toteq,nobsea,ll,ijk,is,kk,js,l,lp
      real(8) diff,dumx,dumy,dumz,anorm,df1,df2,df3,df4,norm1,norm2
      real(8) anx2,any2,anz2,dp
      real(8),dimension(:),allocatable:: sai
      real(8),dimension(:,:),allocatable:: d
      real(8),dimension(:,:),allocatable:: x,xf
      real(8),dimension(3)   :: dx,vd1,vd2
      real(8),dimension(3,3) :: sig
      integer,dimension(:),allocatable:: ian,nn,icode,nn2
      integer,dimension(:,:),allocatable:: isea,isea2

      read(5,*) n
      allocate(sai(n))
      allocate(ian(n),nn(n),icode(n),nn2(n))
      allocate(d(n,n))
      allocate(isea(n,n),isea2(n,n))
      allocate(x(3,n),xf(3,n))

      nosp=0 
      nobsea=0
      do i=1,n
         nn(i)=0
         read(5,*) ian(i),x(1,i),x(2,i),x(3,i)
      enddo 
      nsea=0
c construct the distance matrix
      do i=1,n
         sai(i)=0
         do j=1,n
            dumx=x(1,i)-x(1,j)
            dumy=x(2,i)-x(2,j)
            dumz=x(3,i)-x(3,j)
            d(i,j)=dsqrt(dumx*dumx+dumy*dumy+dumz*dumz)
            sai(i)=sai(i)+ian(i)*d(i,j)**3
         enddo
      enddo

      do i=1,n
         icode(i)=0
         do k=1,n
            diff=abs(sai(i)-sai(k))
c            print*, i,k,sai(i),sai(k),diff
            if(diff<=0.15d0) then
               nn(i)=nn(i)+1
               isea(i,nn(i))=k
               icode(i)=icode(i)+k**k
            endif
         enddo
         if(nn(i)>1) then
            lp=1
            do l=1,i-1
               if(icode(i)==icode(l)) lp=0
            enddo
            if(lp==1)  then
               nobsea=nobsea+1
               nn2(nobsea)=nn(i) 
               do ll=1,nn2(nobsea)
                  isea2(nobsea,ll)=isea(i,ll) 
c                  print*, nobsea,ll,isea2(nobsea,ll)
               enddo
            endif
         endif
      enddo
      do i=1,nobsea
c         print*, "i",i,nobsea
         do j=1,nn2(i)
            do k=j+1,nn2(i) 
c all possible j-k combinations
c               print*, i,j,k,isea2(i,j),isea(i,k)
               dx(1)=x(1,isea2(i,j))-x(1,isea2(i,k))
               dx(2)=x(2,isea2(i,j))-x(2,isea2(i,k))
               dx(3)=x(3,isea2(i,j))-x(3,isea2(i,k))
               anx2=dx(1)*dx(1)
               any2=dx(2)*dx(2)
               anz2=dx(3)*dx(3)
               anorm=dsqrt( anx2+any2+anz2 ) 
               dx(1)=dx(1)/anorm
               dx(2)=dx(2)/anorm
               dx(3)=dx(3)/anorm
               do is=1,3
                  do js=is,3 
                     if(is==js) then
                        sig(is,js)=1-2*dx(is)*dx(js)
                     else
                        sig(is,js)=-2*dx(is)*dx(js)
                        sig(js,is)=sig(is,js)
                     endif 
                  enddo
               enddo
               xf=matmul(sig,x)    
               toteq=0  
               do ijk=1,n 
                  do kk=1,n
                     df1=ian(ijk)-ian(kk)
                     df2=xf(1,ijk)-x(1,kk)
                     df3=xf(2,ijk)-x(2,kk)
                     df4=xf(3,ijk)-x(3,kk)
                     diff=df1*df1+df2*df2+df3*df3+df4*df4
                     if(diff<=0.0001d0) toteq=toteq+1
                  enddo
                  if(toteq==n) then
                      nosp=nosp+1
                      print*, "Normal direction of symm. plane",
     &                isea2(i,j),isea2(i,k)
                  endif
               enddo
            enddo
         enddo
      enddo
      print*, "N of symmetry planes",nosp
      if(nosp>0)  print*, "Symmetry: CS" 
      if(nosp==0) print*, "Symmetry: C1" 
1     format('H',3(f20.10))
6     format('C',3(f20.10))
      end
