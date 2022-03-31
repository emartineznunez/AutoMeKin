      program rrkmp
      use constants_rrkm
      use omegas
      implicit double precision(a-h,o-z)

      character line*5,title*70

      read(5,'(a)') title
      read(5,*) m,ezpe0,delta,qmbt,deg,erot,edum
      allocate(ro(0:m),rots(0:m),w(0:m),wts(0:m),ke(0:m),wdum(0:m))
      write(6,45)
      write(6,46)
      write(6,466)
      write(6,47)
      write(6,48)
      write(6,45)
      write(6,30)
      write(6,61) title     
      write(6,30)      
      write(6,50) ezpe0/cmtokcal 
      write(6,51) erot
      if(qmbt==1) then
         read(5,*) v0,v1,omega
         allocate(wtemp(0:m))
      endif
      if(erot>0) read(5,*) aibc,aibcts
      read(5,*) nrot,nrotts
      write(6,52) m/cmtokcal
      write(6,30)
      write(6,55) nrot,nrotts
      if(nrot  >0) read(5,*) nmr ,nbr 
      if(nrotts>0) read(5,*) nmts,nbts
      write(6,30)
      if(nrotts>0)write(6,15)
      if(nrotts>0)write(6,16)
      if(nrotts>0)write(6,131) nmr,nbr
      if(nrotts>0)write(6,11) nmts,nbts
      if(nrotts>0)write(6,30)
      if(nrotts>0) then
      allocate(sigmatsm(nmts),brottsm(nmts))
      allocate(sigmatsb(nbts),brottsb(nbts))
      allocate(sigmam(nmr),brotm(nmr))
      allocate(sigmab(nbr),brotb(nbr))
      do i=1,nmr
         print*, "Reactant 1D rotors"
         write(6,13)
         write(6,14)
         read(5,*) brotm(i),sigmam(i)
         write(6,12)  brotm(i),sigmam(i)
      enddo
      do i=1,nbr
         print*, "Reactant 2D rotors"
         write(6,13)
         write(6,14)
         read(5,*) brotb(i),sigmab(i)
         write(6,12)  brotb(i),sigmab(i)
      enddo
      do i=1,nmts
         print*, "TS 1D rotors"
         write(6,13)
         write(6,14)
         read(5,*) brottsm(i),sigmatsm(i)
         write(6,12)  brottsm(i),sigmatsm(i)
      enddo
      do i=1,nbts
         print*, "TS 2D rotors"
         write(6,30)
         write(6,13)
         write(6,14)
         read(5,*) brottsb(i),sigmatsb(i)
         write(6,12)  brottsb(i),sigmatsb(i)
      enddo
      endif

      read(5,'(a)') line
      if(line.eq.'rrkm ') then
          write(6,62)
          rrkm=1
      elseif(line.eq.'vrrkm') then
          write(6,64)
          rrkm=2
      endif
cc
cc       leemos un factor de escalado de las frecuencias
cc

      read(5,*) fnscale
      omega=omega*fnscale
      read(5,*) nreac
      enpuce=0.0d0
      enpucets=0.0d0

      write(6,30)

      write(6,32)
      write(6,34)
      allocate(nfrecr(nreac))
      do i=1,nreac
         read(5,*) nfrecr(i)
         dum=nfrecr(i)
         nfrecr(i)=dum*fnscale
         enpuce=enpuce+0.5d0*nfrecr(i)       
         write(6,20) i,nfrecr(i)
      enddo
      write(6,30)
c   
c       calculamos la energia del punto cero escalada
c

      write(6,31) enpuce/cmtokcal
      write(6,30)

 
      read(5,*) nts
      allocate(nfrect(nreac))
      if(rrkm==2) then
         read(5,*) npoints
         allocate(r(npoints),ezpe0v(npoints))
         allocate(nfrectv(npoints,nts))
         allocate(wtsmin(0:m),rmin(0:m))
         print*, npoints,' points selected for variational RRKM'
         do i=1,npoints
c ezpe0v en cm-1 y frec en cm-1
            read(5,*) r(i),ezpe0v(i),(nfrectv(i,j),j=1,nts)
            print*, i,r(i),ezpe0v(i)
         enddo
      else
         write(6,33)
         write(6,35)
         do i=1,nts
            read(5,*) nfrect(i)
            dum=nfrect(i)
            nfrect(i)=dum*fnscale
            enpucets=enpucets+0.5d0*nfrect(i)
            write(6,20) i,nfrect(i)              
         enddo
      endif
  
      write(6,30)
      write(6,21) enpucets/cmtokcal
      write(6,30)
       
      if(nrotts>0) call convots(m,nmts,nbts)
c inicializamos matrices
      do i=0,m
         w(i)=1.d0
         if(i<ezpe0)  wts(i)=0.d0
         if(i>=ezpe0) then
            if(nrotts==0) then
               wts(i)=1.d0
            else
               wts(i)=wdum(i-ezpe0) 
            endif
         endif 
         if(i==0)     ro(i)=1.d0
         if(i>0)      ro(i)=0.d0
      enddo

      if(rrkm==1) then
         do j=1,nts 
            k=nfrect(j)+ezpe0 
            do i=k,m
               wts(i)=wts(i)+wts(i-nfrect(j))
            enddo
         enddo
      else if(rrkm==2) then
         do i=0,m
            wtsmin(i)=1.d100
         enddo
         do ijk=1,npoints
            do i=0,m
               w(i)=1
               if(i<ezpe0v(ijk)) wts(i)=0.d0
               if(i>=ezpe0v(ijk)) then
                  if(nrotts==0) then
                     wts(i)=1.d0
                  else
                     wts(i)=wdum(i-ezpe0v(ijk)) 
                  endif
               endif   
            enddo
            do j=1,nts
               k=nfrectv(ijk,j)+ezpe0v(ijk)
               do i=k,m
                  wts(i)=wts(i)+wts(i-nfrectv(ijk,j))
               enddo
            enddo
            do i=0,m
               if(wts(i)<wtsmin(i)) then
                 wtsmin(i)=wts(i)
                 rmin(i)=r(ijk)
               endif
            enddo
            print*, "Doing point ",ijk," of ",npoints
         enddo
         print*, 'Variational calculation of Wts'
         do i=0,m
            wts(i)=wtsmin(i)
         enddo
         do i=0,m
            write(6,111) i/349.76d0,rmin(i),wts(i)
         enddo
      endif
111   format(" Energy=",f8.2," kcal/mol."," Min R=",f8.2," SOS =",e8.2)


      if(qmbt==1) then
         rint=0
         do i=0,m
            iener=i
            if(i>1000) call mill(iener,rint)
            wtemp(i)=rint
         enddo
      endif

c reactant sum of states

      if(nrot>0) call convo(m,nmr,nbr)
      do j=1,nreac
         do i=nfrecr(j),m
            w(i)=w(i)+w(i-nfrecr(j))
         enddo
      enddo
c  reactant density of states
      do j=1,nreac
         do i=nfrecr(j),m
            ro(i)=ro(i)+ro(i-nfrecr(j))
         enddo
      enddo

        
      if(erot>0) then
         ratio=aibc/aibcts
      else
         ratio=0
      endif
      do i=1,m 
         a=(ratio*erot)*cmtokcal
         j=int(a)
         adummy=wts(i+j)
         if(ro(i)>0) ke(i)=deg*wts(i)/ro(i)/h
         if(erot>0.and.ro(i)>0) ke(i)=deg*adummy/ro(i)/h
         if(qmbt==1) ke(i)=deg*wtemp(i)/ro(i)/h
      enddo
 
      write(6,30)
      write(6,40)
      write(6,41)

      do i=0,m,10
c         ekm=dble(i)/cmtokcal
         ekm=dble(i)
c         if(ke(i)>0.and.erot==0) 
         if(ke(i)>0.and.erot==0) 
     1   write(6,112) i,ke(i)
c         if(erot==0) 
c     1   write(17,112) i,ke(i)
         if(ke(i)>0.and.erot>0) 
     1   write(6,10) ekm+erot,ke(i)
      enddo
 
c      if(edum>0) then
c         do j=0,int(edum*cmtokcal),350
c            ekm=j/cmtokcal
c            dum=0.d0
c             write(16,101) int(ekm+0.5d0),dum
c         enddo
c      endif
c
c      mup=m-int(edum*cmtokcal+0.5d0)
c      do i=0,mup,350
c         ekm=i/cmtokcal
c         write(16,101) int(ekm+edum+0.5d0),ke(i)
c      enddo
c    
c      write(6,30)
c      write(6,60)
c      write(6,41)
c
c      do i=0,m 
c         ekm=dble(i)/cmtokcal
c         write(6,10) ekm,ro(i)
c      enddo

c      write(6,*)
c      write(6,63)
c      write(6,41)
c      do i=1,m
c         ekm=dble(i)/cmtokcal
c         write(6,10) ekm,wts(i)
c      enddo                                                                  
c
      write(6,59)
        
10    format(3x,f9.4,5x,3(e11.4)) 
108   format(3x,i9,5x,e20.8) 
112   format(3x,i10,5x,f20.0)
101   format(3x,i9,5x,3(f20.0)) 
131   format(3x,'Hay',i3,1x,'rotor/es 1D y',i3,1x,
     *'rotor/es 2D en el reactivo')
11    format(3x,'Hay',i3,1x,'rotor/es 1D y',i3,1x,
     *'rotor/es 2D en el TS')
12    format(3x,f7.2,'cm-1',f7.2)
13    format(6x,'cte. rot.',2x,'sigma')
14    format(6x,'========',2x,'=====')
15    format(3x,'Parametros para los rotores del estado de transicion')
16    format(3x,'====================================================')
20    format(7x,'frec',i5,2x,i7,2x,'cm-1')
21    format(3x,'Energia del punto cero en el TS=',f9.2,'kcal/mol')
22    format(3x,'Energia critica para el calculo RRK=',f9.2,'kcal/mol')
30    format(/)
31    format(3x,'Energia del punto cero en el re=',f9.2,'kcal/mol')
32    format(3x,'Frecuencias vibracionales del reactivo')
34    format(3x,'======================================')
33    format(3x,'Frecuencias vibracionales del estado de transicion')
35    format(3x,'==================================================')
40    format(5x,'Energia',6x,'k(E,J)/s-1')
41    format(5x,'=======',6x,'==========')
45    format(5x,'**************************************************')
46    format(5x,'*                PROGRAM  RRKM                   *')
466   format(5x,'*              E. Martinez-Nunez                 *')
47    format(5x,'*       Departamento de Quimica Fisica           *')
48    format(5x,'*  Universidad de Santiago de Compostela(Spain)  *')
50    format(3x,'Energia critica   =',f7.2,'kcal/mol')
51    format(3x,'Energia rotacional=',f7.2,'kcal/mol')
52    format(3x,'Energia mas alta  =',f7.2,'kcal/mol')
55    format(3x,'Rotores libres del reactivo=',i2,7x,
     1'Rotores libres del TS=',i2)
56    format(/,3x,'Teoria rrkm armonica clasica (rrk)')
57    format(/,3x,'Notese que el cero de energia no es la ZPE',/) 
58    format(/,3x,'El factor vibracional nu es',e11.4,'s-1')
59    format(/,'***END OF RRKM CALCULATIONS***')
60    format(5x,'Energia',6x,'ro(E)/cm  ')
63    format(5x,'Energia',6x,' W(E)/cm  ')    
61    format(3x,a60)
62    format(/,3x,'Teoria rrkm armonica cuantica')  
64    format(/,3x,'Teoria variacional rrkm armonica cuantica')  
65    format(/,3x,'Teoria variacional rrkm armonica clasica (RRK)')  

      end


      subroutine mill(iener,rint)
c
c   esta subrutina calcula la integral de convolucion entre la suma de
c   estados clasica y la probabilidad de tunel cuantica
c
      use omegas
      implicit double precision(a-h,o-z)  

      deltatot=iener+enpuce
      deltain=deltatot/100.0d0
      rint=0.0d0
      do k=1,101
         x=-v0+deltain*(k-1)
         call sint(bres,x,deltatot)   
         dum=bres
         if(k.eq.1.or.k.eq.101) dum=bres/2.0d0
         rint=rint+deltain*dum
      enddo
      return
      end

      subroutine sint(bres,x,deltatot)
c
c     esta subrutina calcula el valor de la probabilidad de tunel
c     y de la suma de estados a los valores requeridos por la surutina
c     mill
      use omegas
      implicit double precision(a-h,o-z)  
         
      cte=4.0d0*3.1416/(omega)/(1.0d0/dsqrt(v0)+1.0d0/dsqrt(v1))
      arg=x+v0
      arg2=x+v1
      if(arg<=0.or.arg2<=0) then
         bres=0
         return
      endif
      rv0=dsqrt(arg) 
      rv1=dsqrt(arg2)  
      a1=cte*rv0
      b1=cte*rv1
      ab2=(a1+b1)/2.0d0
      c1=2.0d0*3.1416*dsqrt(((v0*v1)/(omega)**2)-0.0625d0)
      den=sinh(ab2)*sinh(ab2)+cosh(c1)*cosh(c1)
      sa=sinh(a1)
      ca=cosh(a1)
      sb=sinh(b1)
      cb=cosh(b1)
      sab=sinh(ab2)
      cab=cosh(ab2) 
      p=cte/2.0d0*((ca*sb/rv0+sa*cb/rv1)*(den)-sa*sb*
     1sab*cab*(1.0d0/rv0+1.0d0/rv1))/den**2
      k=int(deltatot-enpuce-x)
      bres=p*wts(k) 
   
      return
      end

      subroutine convo(m,nm,nb)
      use constants
      use omegas 
      implicit double precision(a-h,o-z)
      iu=nm
      ip=nb 
      dum=pi**(iu/2.0d0)
      expo=ip+iu/2.0d0-1.0d0
      pm=1.0d0
      pb=1.0d0
      do i=1,iu
         pm=pm*(1.0d0/sigmam(i))*dsqrt(1.0d0/brotm(i))
      enddo
      do i=1,ip
         pb=pb*(1.0d0/sigmab(i)/brotb(i))
      enddo
      ro(0)=1.d0
      do i=1,m
         ro(i)=dum/sigf(ip,iu)*(i**(expo))*pm*pb
         suma=0.d0
         do j=0,i
            suma=suma+ro(j)
         enddo
         w(i)=suma
      enddo


      return
      end

      subroutine convots(m,nm,nb)
      use constants
      use omegas
      implicit double precision(a-h,o-z)
      iu=nm
      ip=nb
      dum=pi**(iu/2.0d0)
      expo=ip+iu/2.0d0-1.0d0
      pm=1.0d0
      pb=1.0d0
      do i=1,iu
         pm=pm*(1.0d0/sigmatsm(i))*dsqrt(1.0d0/brottsm(i))
      enddo
      do i=1,ip
         pb=pb*(1.0d0/sigmatsb(i)/brottsb(i))
      enddo
      rots(0)=1.d0
      do i=1,m
         rots(i)=dum/sigf(ip,iu)*(i**(expo))*pm*pb
         suma=0.d0 
         do j=0,i
            suma=suma+rots(j) 
         enddo
         wdum(i)=suma
      enddo

      return
      end
 
      double precision function sigf(ip,iu)
      use constants
      implicit double precision (a-h,o-z)
cc
cc   esta funcion calcula el valor de la funcion gamma:
cc   gamma(x)=(x-1)! si x es entero,
cc   gamma(x)=(x-1)(x-2)...(3/2)pi**0.5 si x no es entero
cc
cc
      sigf=1.0d0
      integer=0
      arg=ip+iu/2.0d0
      iarg=int(arg)
      if(dabs(iarg-arg)<0.01) integer=1
      do i=1,iarg-1
         if(integer==1)sigf=sigf*i 
         if(integer==0)sigf=sigf*(i+0.5d0)
      enddo
      if(integer==0)sigf=sigf*sqrt(pi)
      return
      end
           

