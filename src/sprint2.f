      program sprint2
ccc it uses the adjacency matrix like in sprint (with real numbers)
ccc the Laplacian is based on a adjacency with whole numbers
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      integer,dimension(:,:),allocatable :: ia
      integer,dimension(:),allocatable :: ideg
      real,dimension(:,:),allocatable :: a,al
      real,dimension(:),allocatable :: deg,s,d,e,f
     
      amaxi=-1d200 
      read(5,*) m,natom
      print*, "Natom=",natom
      allocate(a(natom,natom),al(natom,natom),ia(natom,natom))
      allocate(deg(natom),s(natom),d(natom),e(natom),f(natom),
     &ideg(natom))
      print*, "steps=",m
      do i=1,m
         print*, "Step",i
         print*, "Adjacency matrix"
         do j=1,natom
            read(5,*)  (a(j,k),k=1,natom)
c            print*,  (a(j,k),k=1,natom)
            print "(999f18.8)",  (a(j,k),k=1,natom)
            deg(j)=0.d0
            do k=1,natom
               deg(j)=deg(j)+a(j,k)
            enddo
         enddo 
         do j=1,natom
            read(5,*)  (ia(j,k),k=1,natom)
            ideg(j)=0
            do k=1,natom
               ideg(j)=ideg(j)+ia(j,k)
            enddo
         enddo 
         print*, "deg of each vertex"
         do k=1,natom
            print*, deg(k)
         enddo

         print*, "Laplacian of the graph"
         do ii=1,natom
            do jj=1,natom
               if(ii.eq.jj) al(ii,jj)=dble(ideg(ii))
               if(ii.ne.jj) al(ii,jj)=-dble(ia(ii,jj))
            enddo
c            print*,  (al(ii,k),k=1,natom)
            print "(999f18.8)",  (al(ii,k),k=1,natom)
         enddo
cccc
         call tred2(a,natom,natom,d,e)
         call tqli(d,e,natom,natom,a)

         do jj=1,natom
            if(d(jj)>amaxi) then
               imaxi=jj
               amaxi=d(jj)
            endif
         enddo

         do jj=1,natom-1
            do kk=jj+1,natom
               if(d(jj)>d(kk)) then
                  temp=d(kk)
                  d(kk)=d(jj)
                  d(jj)=temp 
               endif
            enddo
         enddo
         write(6,3) (d(ii),ii=1,natom)
         sumsq=0
         sumst=0
         do kk=1,natom
            sumsq=sumsq+d(kk)*d(kk)
            sumst=sumst+d(kk)*d(kk)*d(kk)
            dum=a(kk,imaxi)
            a(kk,imaxi)=sqrt(dum*dum)
         enddo
         write(6,4) sumsq/2.d0
         write(6,5) sumst/6.d0
         do jj=1,natom-1
            do kk=jj+1,natom
               if(a(jj,imaxi)>a(kk,imaxi)) then
                  temp=a(kk,imaxi)
                  a(kk,imaxi)=a(jj,imaxi)
                  a(jj,imaxi)=temp 
               endif
            enddo
         enddo
         cc=sqrt(real(natom))*d(natom)
         do k=1,natom
            s(k)=cc*a(k,imaxi)
         enddo
         write(6,1) (a(j,imaxi),j=1,natom) 
         write(6,2) (s(j),j=1,natom) 
ccc
         write(*,*)
         print*, "Results for the Laplacian"
         call tred2(al,natom,natom,d,e)
         call tqli(d,e,natom,natom,al)
         do jj=1,natom-1
            do kk=jj+1,natom
               if(d(jj)>d(kk)) then
                  temp=d(kk)
                  d(kk)=d(jj)
                  d(jj)=temp 
               endif
            enddo
         enddo
         write(6,3) (d(ii),ii=1,natom)

      enddo

1     format('EigenVector of lambda_max      ',90f12.3)
2     format('Sprint coordinates ordered     ',90f12.3)
3     format('Lambda (from lowest to highest)',90f12.3)
4     format('(Sum Lambda^2)/2 (# of bonds  )',90f12.3)
5     format('(Sum Lambda^3)/6 (# of triangs)',90f12.3)
      end


      SUBROUTINE TRED2(A,N,NP,D,E)
      DIMENSION A(NP,NP),D(NP),E(NP)
      IF(N.GT.1)THEN
        DO 18 I=N,2,-1  
          L=I-1
          H=0.
          SCALE=0.
          IF(L.GT.1)THEN
            DO 11 K=1,L
              SCALE=SCALE+ABS(A(I,K))
11          CONTINUE
            IF(SCALE.EQ.0.)THEN
              E(I)=A(I,L)
            ELSE
              DO 12 K=1,L
                A(I,K)=A(I,K)/SCALE
                H=H+A(I,K)**2
12            CONTINUE
              F=A(I,L)
              G=-SIGN(SQRT(H),F)
              E(I)=SCALE*G
              H=H-F*G
              A(I,L)=F-G
              F=0.
              DO 15 J=1,L
                A(J,I)=A(I,J)/H
                G=0.
                DO 13 K=1,J
                  G=G+A(J,K)*A(I,K)
13              CONTINUE
                IF(L.GT.J)THEN
                  DO 14 K=J+1,L
                    G=G+A(K,J)*A(I,K)
14                CONTINUE
                ENDIF
                E(J)=G/H
                F=F+E(J)*A(I,J)
15            CONTINUE
              HH=F/(H+H)
              DO 17 J=1,L
                F=A(I,J)
                G=E(J)-HH*F
                E(J)=G
                DO 16 K=1,J
                  A(J,K)=A(J,K)-F*E(K)-G*A(I,K)
16              CONTINUE
17            CONTINUE
            ENDIF
          ELSE
            E(I)=A(I,L)
          ENDIF
          D(I)=H
18      CONTINUE
      ENDIF
      D(1)=0.
      E(1)=0.
      DO 23 I=1,N
        L=I-1
        IF(D(I).NE.0.)THEN
          DO 21 J=1,L
            G=0.
            DO 19 K=1,L
              G=G+A(I,K)*A(K,J)
19          CONTINUE
            DO 20 K=1,L
              A(K,J)=A(K,J)-G*A(K,I)
20          CONTINUE
21        CONTINUE
        ENDIF
        D(I)=A(I,I)
        A(I,I)=1.
        IF(L.GE.1)THEN
          DO 22 J=1,L
            A(I,J)=0.
            A(J,I)=0.
22        CONTINUE
        ENDIF
23    CONTINUE
      RETURN
      END

      SUBROUTINE TQLI(D,E,N,NP,Z)
      DIMENSION D(NP),E(NP),Z(NP,NP)
      IF (N.GT.1) THEN
        DO 11 I=2,N
          E(I-1)=E(I)
11      CONTINUE
        E(N)=0.
        DO 15 L=1,N
          ITER=0
1         DO 12 M=L,N-1
            DD=ABS(D(M))+ABS(D(M+1))
            IF (ABS(E(M))+DD.EQ.DD) GO TO 2
12        CONTINUE
          M=N
2         IF(M.NE.L)THEN
            IF(ITER.EQ.30) then
               print*, 'too many iterations'
               call exit
            endif
            ITER=ITER+1
            G=(D(L+1)-D(L))/(2.*E(L))
            R=SQRT(G**2+1.)
            G=D(M)-D(L)+E(L)/(G+SIGN(R,G))
            S=1.
            C=1.
            P=0.
            DO 14 I=M-1,L,-1
              F=S*E(I)
              B=C*E(I)
              IF(ABS(F).GE.ABS(G))THEN
                C=G/F
                R=SQRT(C**2+1.)
                E(I+1)=F*R
                S=1./R
                C=C*S
              ELSE
                S=F/G
                R=SQRT(S**2+1.)
                E(I+1)=G*R
                C=1./R  
                S=S*C
              ENDIF
              G=D(I+1)-P
              R=(D(I)-G)*S+2.*C*B
              P=S*R
              D(I+1)=G+P
              G=C*R-B
              DO 13 K=1,N
                F=Z(K,I+1)
                Z(K,I+1)=S*Z(K,I)+C*F
                Z(K,I)=C*Z(K,I)-S*F
13            CONTINUE
14          CONTINUE
            D(L)=D(L)-P
            E(L)=G
            E(M)=0.
            GO TO 1
          ENDIF
15      CONTINUE
      ENDIF
      RETURN
      END


