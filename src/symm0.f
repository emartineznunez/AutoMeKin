      program symm0
      implicit none

      integer i,j,k,n,idx,lin,plane
      real(8) diff,dumx,dumy,dumz,norm1,norm2
      real(8) dp,dp2
      real(8),dimension(:,:),allocatable:: x,v
      real(8),dimension(3)   :: vd1,vd2,vp
      integer,dimension(:),allocatable:: ian

      read(5,*) n
      allocate(ian(n))
      allocate(x(3,n))
      allocate(v(3,n*(n-1)/2))

      do i=1,n
         read(5,*) ian(i),x(1,i),x(2,i),x(3,i)
      enddo 
c construct the distance matrix
      idx=0
      lin=1
      plane=1 
      do i=1,n
         do j=1,n
            dumx=x(1,i)-x(1,j)
            dumy=x(2,i)-x(2,j)
            dumz=x(3,i)-x(3,j)
            if(j>i) then
               idx=idx+1
               v(1,idx)=dumx 
               v(2,idx)=dumy 
               v(3,idx)=dumz 
c               print*, idx,(v(l,idx),l=1,3)
            endif
         enddo
      enddo
c      print*, "idx",idx 
      do i=1,idx
         do j=1,i-1
            do k=1,3
               vd1(k)=v(k,j)
               vd2(k)=v(k,i)
            enddo
            norm1=dsqrt(vd1(1)*vd1(1)+vd1(2)*vd1(2)+vd1(3)*vd1(3))
            norm2=dsqrt(vd2(1)*vd2(1)+vd2(2)*vd2(2)+vd2(3)*vd2(3))
            dp=abs(dot_product(vd1,vd2)/norm1/norm2)
            diff=abs(dp-1.0d0)
            if(diff>0.005d0.and.lin==1) then
               lin=0
               vp(1) = vd1(2) * vd2(3) - vd1(3) * vd2(2)
               vp(2) = vd1(3) * vd2(1) - vd1(1) * vd2(3)
               vp(3) = vd1(1) * vd2(2) - vd1(2) * vd2(1)
            endif 
c            print*, j,i,idx,dp,diff
         enddo 
         if(lin==0) then
           dp2=dot_product(vd2,vp)
           diff=abs(dp2)
c           print*, i,diff
           if(diff>0.005d0) then
             plane=0
           endif
         endif 
      enddo
      if(lin==0) then
         print*, "Non-lineal molecule"
      else
         print*, "Lineal molecule"
         print*, "Symmetry: CS"
         print*, "No more calc"
      endif
      if(lin==0.and.plane==0) print*, "Non-planar molecule"
      if(lin==0.and.plane==1) print*, "Planar molecule"
      if(lin==0.and.plane==1) print*, "Symmetry CS"
      if(lin==0.and.plane==1) print*, "No more calc"


      end
