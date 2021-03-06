c-----------------------------------------------------------------------
c     Yld2000-2d model for the case of planar stress condition where
c     sig_xx,sig_yy,sig_xy are non-zeros.

c     Ref
c     [1] Barlat et al., IJP 19, 2003, p1297-1319
c     [2] Manual of abaqusPy <man.tex>
c
c     Youngung Jeong
c     youngung.jeong@gmail.com
c-----------------------------------------------------------------------
      subroutine yld2000_2d(cauchy,phi,dphi,d2phi,yldc)
      implicit none
c     Arguments
c     cauchy: cauchy stress
c     phi   : yield surface
c     dphi  : yield surface 1st derivative w.r.t cauchy stress
c     d2phi : The 2nd derivative w.r.t. cauchy stress
c     yldc  : yield surface components
      integer ntens
      parameter(ntens=3)
      dimension cauchy(ntens),sdev(ntens),dphi(ntens),d2phi(ntens,ntens)
     $     ,yldc(9)
      real*8 cauchy,phi,dphi,d2phi,yldc,hydro,sdev
cf2py intent(in)  cauchy,yldc
cf2py intent(out) phi,dphi,d2phi
      call deviat(ntens,cauchy,sdev,hydro)
c     call yld2000_2d_dev(sdev,phi,dphi,d2phi,yldc)
      call yld2000_2d_cauchy(cauchy,phi,dphi,d2phi,yldc)
      return
      end subroutine yld2000_2d
c     yld2000_2d_dev is implementation of the yld2000-2d model as a
c     function of 'deviatoric' stress and yield function constants
c     stored in yldc.
c-----------------------------------------------------------------------
      subroutine yld2000_2d_cauchy(cauchy,psi,dpsi,d2psi,yldc)
c     psi is defiend as ((phi`+phi``)/2)^(1/q)
c       where phi` and phi`` are analogous to Hershey isotropic functions;
c             and q is the yield function exponent
c       note that phi` and phi`` are functions of principal values of
c       'linearly' transformed stress tensors.
c     psi is a homogeneous function of degree 1.

c     Arguments
c     cauchy: cauchy stress
c     psi   : yield surface
c     dpsi  : yield surface 1st derivative w.r.t cauchy stress
c     d2psi : 2nd derivative - (not included yet)
c     yldc  : yield surface constants
c             yldc(1:8) - alpha values, yldc(9): yield function exponent
      implicit none
      integer ntens
      parameter(ntens=3)
      dimension cauchy(ntens),sdev(ntens),dpsi(ntens),d2psi(ntens,ntens)
     $     ,c(2,ntens,ntens),x1(ntens),x2(ntens),dx_dsig(2,ntens,ntens),
     $     phis(2),dphis(2,ntens),yldc(9),alpha(8),aux2(ntens,ntens),
     $     aux1(ntens),xs(2,ntens),xp1(2),xp2(2),chis(2,2),
     $     dphis_dchi(2,2),x(ntens),dchi_dx(2,2,ntens),aux23(2,ntens),
     $     aux233(2,ntens,ntens),dphis_aux(2,ntens)
      real*8 cauchy,sdev,psi,dpsi,d2psi,c,x1,x2,a,phis,dphis,yldc,alpha,
     $     dx_dsig,aux2,aux1,hydro,xs,xp1,xp2,chis,dphis_dchi,x,dchi_dx,
     $     aux23,aux233,dphis_aux
      integer i
c     locals controlling
      integer imsg,ind,j,k
      logical idiaw
cf2py intent(in)  cauchy,yldc
cf2py intent(out) psi,dpsi,d2psi
      imsg = 0
      idiaw = .false.
      alpha(:) = yldc(1:8)
      a        = yldc(9)        ! yield surface exponent
      dphis(:,:)=0d0
      call alpha2lc(alpha,c,dx_dsig)
      aux2(:,:) = c(1,:,:)
      call deviat(ntens,cauchy,sdev,hydro)
      call calc_x_dev(sdev,aux2,x1) ! x1: linearly transformed stress (prime)
      xs(1,:)=x1(:)
      aux2(:,:) = c(2,:,:)
      call calc_x_dev(sdev,aux2,x2) ! x2: linearly transformed stress (double prime)
      xs(2,:)=x2(:)
      call calc_princ(x1,xp1)
      chis(1,:)=xp1(:)
      call calc_princ(x2,xp2)
      chis(2,:)=xp2(:)
      call hershey(xp1,xp2,a,phis(1),phis(2),dphis_dchi)
      psi = (0.5d0*(phis(1)+phis(2)))**(1d0/a)
      if (idiaw) then
         call w_chr(0,'phis:')
         call w_dim(0,phis,2,1d0,.true.)
         call w_val(0,'psi :',psi)
         call fill_line(0,'*',52)
      endif
      aux2(:,:) = c(1,:,:)
      call calc_dphi_dev(sdev,aux2,a,aux1,0)
      dphis(1,:) = aux1(:)
      if (idiaw) call fill_line(0,'-',52)
      aux2(:,:) = c(2,:,:)
      call calc_dphi_dev(sdev,aux2,a,aux1,1)
      dphis(2,:) = aux1(:)
      dpsi(:) = 0d0
      do 5 i=1,ntens
         dpsi(i) = 1d0/2d0/a * ((phis(1)+phis(2))/2d0)**(1d0/a-1d0) *
     $        (dphis(1,i) + dphis(2,i))
 5    continue
c     Just to check if chain-rule based yield surface derivative is
c     equivalent to the derivations shown in the yld2000-2d paper
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 53 in Ref [2]
      do ind=1,2
         x=xs(ind,:)
         call calc_dchi_dx(x,aux23,aux233)
         dchi_dx(ind,:,:)=aux23(:,:)
      enddo
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     1st derivatives
c     See = Eq. 43 in Ref [43]
      dphis_aux(:,:)=0d0
      do 10 ind=1,2
      do 10 i=1,ntens
      do 10 j=1,2
      do 10 k=1,3
         dphis_aux(ind,i) = dphis_aux(ind,i) +
     $        dphis_dchi(ind,j)*dchi_dx(ind,j,k)*dx_dsig(ind,k,i)
 10   continue

      do 20 ind=1,2
      do 20 i=1,ntens
         if (dabs(dphis(ind,i)-dphis_aux(ind,i)).gt.1e-3) then
            write(*,*)
            write(*,'(4a8)')'ind','i','dp_sol','dp_x'
            write(*,'(i8,i8,f8.3,f8.3)') ind,i,
     $           dphis(ind,i),dphis_aux(ind,i)
c            call exit(-1)
         endif
 20   continue

c     2nd derivatives - on my to-do list
      d2psi(:,:) = 0d0
      call yld2000_2d_hessian(psi,dpsi,cauchy,chis,xs,
     $     dx_dsig,yldc(9),d2psi)

      return
      end subroutine yld2000_2d_cauchy
c-----------------------------------------------------------------------
      subroutine yld2000_2d_hessian(psi,dpsi,cauchy,chis,xs,
     $     dx_dsig,a,d2psi)
c     Arguments
c     psi    : yld2000-2d yield surface
c     dpsi   : yld2000-2d yield surface 1st derivatives
c     cauchy : cauchy stress
c     chis   : principal values of transformed stress
c     xs     : transformed stress
c     dx_dsig: the L matrix.
c     a      : yield surface exponent
c     d2psi  : the send derivative of yld2000-2d (to be calculated)
      implicit none
      dimension cauchy(3),chis(2,2),xs(2,3),dx_dsig(2,3,3),
     $     dphis_dchi(2,2),d2phis_dchidchi(2,2,2),d2psi(3,3),
     $     dpsi(3)
      real*8, intent(in)  :: cauchy,chis,xs,dx_dsig,a,
     $     psi,dpsi
      real*8, intent(out) :: d2psi
      dimension dchi_dx(2,2,3), d2chi_dxdx(2,2,3,3),x(3),
     $     aux23(2,3),aux233(2,3,3),d2phis_dsigdsig(2,3,3)
      real*8 tempval1,tempval2,tempval3,sgn1,sgn2, dchi_dx,d2chi_dxdx,
     $     aux23,aux233,d2phis_dchidchi,d2phis_dsigdsig,dphis_dchi,x
      integer i,j,k,l,m,n,ind
      write(3,*) cauchy,chis,xs,dx_dsig,a
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 46 in Ref [2] - calculate dphis_dchi
      dphis_dchi(1,1) =  a * (chis(1,1) - chis(1,2))**(a-1d0)
      dphis_dchi(1,2) = - dphis_dchi(1,1)
      tempval1 = 2d0*chis(2,2) + chis(2,1)
      tempval2 = 2d0*chis(2,1) + chis(2,2)
      sgn1 = sign(1d0,tempval1)
      sgn2 = sign(1d0,tempval2)
      dphis_dchi(2,1) =       a * dabs(tempval1)**(a-1d0) * sgn1
     $                + 2d0 * a * dabs(tempval2)**(a-1d0) * sgn2
      dphis_dchi(2,2) = 2d0 * a * dabs(tempval1)**(a-1d0) * sgn1
     $                      + a * dabs(tempval2)**(a-1d0) * sgn2
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 47 in Ref [2] - calculate (d2phis)_(dchi,dchi)
      d2phis_dchidchi(1,1,1) = a*(a-1d0)*(chis(1,1)-chis(1,2))**(a-2d0)
      d2phis_dchidchi(1,1,2) = -d2phis_dchidchi(1,1,1)
      d2phis_dchidchi(1,2,1) = -d2phis_dchidchi(1,1,1)
      d2phis_dchidchi(1,2,2) =  d2phis_dchidchi(1,1,1)
c     --
      tempval1 = dabs(2d0*chis(2,2)+chis(2,1))**(a-2d0)
      tempval2 = dabs(2d0*chis(2,1)+chis(2,2))**(a-2d0)
      tempval3 = a*(a-1d0)
      d2phis_dchidchi(2,1,1) =     tempval1 + 4d0*tempval2
      d2phis_dchidchi(2,1,2) = 2d0*tempval1 + 2d0*tempval2
      d2phis_dchidchi(2,2,1) = d2phis_dchidchi(2,1,2)
      d2phis_dchidchi(2,2,2) = 4d0*tempval1 +     tempval2
      d2phis_dchidchi(2,:,:) = tempval3*d2phis_dchidchi(2,:,:)
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 53 in Ref [2]
      do ind=1,2
         x(:)=xs(ind,:)
         call calc_dchi_dx(x,aux23,aux233)
         dchi_dx(ind,:,:)=aux23(:,:)
         d2chi_dxdx(ind,:,:,:)=aux233(:,:,:)
      enddo
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 45 in Ref [2]
      d2phis_dsigdsig(:,:,:)=0d0
      do 20 ind=1,2
      do 10 i=1,3
      do 10 j=1,3
      do 10 n=1,3
      do 10 m=1,2
      do 10 l=1,3
      do 10 k=1,2
         d2phis_dsigdsig(ind,i,j)=d2phis_dsigdsig(ind,i,j)+
     $        d2phis_dchidchi(ind,k,m)*dchi_dx(ind,k,l)*
     $        dx_dsig(ind,l,i)*dchi_dx(ind,m,n)*dx_dsig(ind,n,j)
 10   continue
      do 20 i=1,3
      do 20 j=1,3
      do 20 m=1,3
      do 20 l=1,3
      do 20 k=1,2
         d2phis_dsigdsig(ind,i,j) = d2phis_dsigdsig(ind,i,j) +
     $        dphis_dchi(ind,k) * d2chi_dxdx(ind,k,l,m)
     $        * dx_dsig(ind,l,i) *dx_dsig(ind,m,j)
 20   continue
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c     Eq. 44 in Ref [2]
      d2psi(:,:)=0d0
      do 30 i=1,3
      do 30 j=1,3
         d2psi(i,j) = (1d0-a)/psi * dpsi(i) * dpsi(j) +
     $        psi**(1d0-a) / (2d0*a) *
     $        (d2phis_dsigdsig(1,i,j)+d2phis_dsigdsig(2,i,j))
 30   continue
      return
      end subroutine yld2000_2d_hessian
c-----------------------------------------------------------------------
      subroutine calc_dchi_dx(x,dchi,d2chi)
      dimension x(3),dchi(2,3),d2chi(2,3,3)
      real*8, intent(in)  :: x
      real*8, intent(out) :: dchi,d2chi
      real*8 delta,delta_sqrt,delta_sqrt3
      dimension dd_dx(3),d2d_dx(3,3)
      real*8 dd_dx,d2d_dx
      integer i,j
      delta = (x(1) - x(2))*(x(1) - x(2)) + 4d0 * x(3) * x(3)
      delta_sqrt  = delta**(-1d0/2d0)
      delta_sqrt3 = delta**(-3d0/2d0)

c     Eq 51 in Ref [2]
      dd_dx(1) =  2d0*(x(1)-x(2))
      dd_dx(2) = -dd_dx(1)
      dd_dx(3) =  8d0*x(3)

c     Eq 52 in Ref [2]
      d2d_dx(:,:)= 0d0
      d2d_dx(1,1)= 2d0
      d2d_dx(1,2)=-2d0
      d2d_dx(2,1)=-2d0
      d2d_dx(2,2)= 2d0
      d2d_dx(3,3)= 8d0

c     Eq 53 in Ref [2]
      dchi(1,1) = 1d0 + 0.5d0*dd_dx(1) * delta_sqrt
      dchi(1,2) = 1d0 - 0.5d0*dd_dx(1) * delta_sqrt
      dchi(1,3) =       0.5d0*dd_dx(3) * delta_sqrt
      dchi(1,1:3) = dchi(1,1:3)  * 0.5d0

      dchi(2,1) =  dchi(1,2)
      dchi(2,2) =  dchi(1,1)
      dchi(2,3) = -dchi(1,3)

c     Eq 54 in Ref [2]
      do 10 i=1,3
      do 10 j=1,3
         d2chi(1,i,j) = d2d_dx(i,j) * delta_sqrt
     $        - 0.5d0 * dd_dx(i) * dd_dx(j) * delta_sqrt3
         d2chi(1,i,j) = d2chi(1,i,j) * 0.25d0
 10   continue
c     Using Eq 53 in Ref[2], d2chi(2,:,:) is obtained as below

      d2chi(2,1,:) = d2chi(1,2,:)
      !d2chi(2,1,2) = d2chi(1,2,2)
      !d2chi(2,1,3) = d2chi(1,2,3)
      d2chi(2,2,:) = d2chi(1,1,:)
      !d2chi(2,2,2) = d2chi(1,1,2)
      !d2chi(2,2,3) = d2chi(1,1,3)
      d2chi(2,3,:) =-d2chi(1,3,:)
      !d2chi(2,3,2) =-d2chi(1,3,2)
      !d2chi(2,3,3) =-d2chi(1,3,3)

      return
      end subroutine calc_dchi_dx
c-----------------------------------------------------------------------
c     yld2000_2d_dev is implementation of the yld2000-2d model as a
c     function of 'deviatoric' stress and yield function constants
c     stored in yldc.
      subroutine yld2000_2d_dev(sdev,psi,dpsi,d2psi,yldc)
c     psi is defiend as ((phi`+phi``)/2)^(1/q)
c       where phi` and phi`` are analogous to Hershey isotropic functions;
c             and q is the yield function exponent
c       note that phi` and phi`` are functions of principal values of
c       'linearly' transformed stress tensors.
c     psi is a homogeneous function of degree 1.

c     Arguments
c     sdev  : deviatoric stress
c     psi   : yield surface
c     dpsi  : yield surface 1st derivative w.r.t cauchy stress
c     d2psi : 2nd derivative - (not included yet)
c     yldc  : yield surface constants
c             yldc(1:8) - alpha values, yldc(9): yield function exponent
      implicit none
      integer ntens
      parameter(ntens=3)
      dimension sdev(ntens),dpsi(ntens),d2psi(ntens,ntens),
     $     c(2,ntens,ntens),x1(ntens),x2(ntens),l2c(2,ntens,ntens),
     $     phis(2),dphis(2,ntens),yldc(9),alpha(8),aux2(ntens,ntens),
     $     aux1(ntens),dphis_dchi(2,2)
      real*8 sdev,psi,dpsi,d2psi,c,x1,x2,a,phis,dphis,yldc,alpha,l2c,
     $     aux2,aux1,dphis_dchi
      integer i
c     locals controlling
      integer imsg
      logical idiaw
cf2py intent(in)  sdev,yldc
cf2py intent(out) psi,dpsi,d2psi
      imsg = 0
      idiaw = .false.
      alpha(:) = yldc(1:8)
      a        = yldc(9)        ! yield surface exponent
      if (idiaw) then
         call w_chr(imsg,'alpha')
         call w_dim(imsg,alpha,8,1d0,.true.)
         call w_val(imsg,'exponent:',a)
      endif
      dphis(:,:)=0d0
      call alpha2lc(alpha,c,l2c)
      if (idiaw) then
         call fill_line(imsg,'*',52)
         call w_chr(imsg,'c1')
         aux2(:,:) = c(1,:,:)
         call w_mdim(imsg,aux2,3,1d0)
         call w_chr(imsg,'c2')
         aux2(:,:) = c(2,:,:)
         call w_mdim(imsg,aux2,3,1d0)
      endif

      aux2(:,:) = c(1,:,:)
      call calc_x_dev(sdev,aux2,x1) ! x1: linearly transformed stress (prime)
      aux2(:,:) = c(2,:,:)
      call calc_x_dev(sdev,aux2,x2) ! x2: linearly transformed stress (double prime)
      call hershey(x1,x2,a,phis(1),phis(2),dphis_dchi)
      psi = (0.5d0*(phis(1)+phis(2)))**(1d0/a)
      if (idiaw) then
         call w_chr(0,'phis:')
         call w_dim(0,phis,2,1d0,.true.)
         call w_val(0,'psi :',psi)
         call fill_line(0,'*',52)
      endif
      aux2(:,:) = c(1,:,:)
      call calc_dphi_dev(sdev,aux2,a,aux1,0)
      dphis(1,:) = aux1(:)
      if (idiaw) call fill_line(0,'-',52)
      aux2(:,:) = c(2,:,:)
      call calc_dphi_dev(sdev,aux2,a,aux1,1)
      dphis(2,:) = aux1(:)
      if (idiaw) call fill_line(0,'*',52)
      dpsi(:) = 0d0
      do 5 i=1,ntens
         dpsi(i) = 1d0/2d0/a * ((phis(1)+phis(2))/2d0)**(1d0/a-1d0) *
     $        (dphis(1,i) + dphis(2,i))
 5    continue
      dpsi(3)=dpsi(3)
      if (idiaw) call w_dim(0,dpsi,3,1d0,.true.)

c     2nd derivatives - on my to-do list
      d2psi(:,:) = 0d0
      return
      end subroutine yld2000_2d_dev
c-----------------------------------------------------------------------
      subroutine calc_dphi_dcauchy(cauchy,c,a,dphi,iopt)
c     Arguments
c     cauchy: cauchy stress
c     c     : c matrix
c     a     : yield exponent
c     dphi  : dphi  (dphi` or dphi``)
c     iopt  : iopt (0: dphi`; 1: dphi``)
      implicit none
      dimension cauchy(3),c(3,3),dphi(3),sdev(3)
      real*8 cauchy,c,a,dphi,sdev,hydro
      integer iopt
      call deviat(3,cauchy,sdev,hydro)
      call calc_dphi_dev(sdev,c,a,dphi,iopt)
      return
      end subroutine calc_dphi_dcauchy
c-----------------------------------------------------------------------
      subroutine calc_dphi_dev(sdev,c,a,dphi,iopt)
c     Arguments
c     sdev  : deviatoric stress
c     c     : c matrix
c     a     : yield exponent
c     dphi  : dphi  (dphi` or dphi``)
c     iopt  : iopt (0: dphi`; 1: dphi``)
      implicit none
      dimension sdev(3),c(3,3),dphi(3),x(3),xp(2),dphi_dp(2),
     $     dp_dx(2,3),dphi_dx(3),l(3,3)
      real*8 c,delta,x,dphi,xp,dp_dx,dphi_dp,a,dphi_dx,l,sdev
      integer iopt,i,j
      call calc_x_dev(sdev,c,x)
      call calc_delta(x,delta)
      call calc_princ(x,xp)
      dphi_dx(:) = 0d0
      if (iopt.eq.0) call calc_a14(xp,a, dphi_dp) ! eq A1.4
      if (iopt.eq.1) call calc_a18(xp,a, dphi_dp) ! eq A1.8

      if (delta.ne.0) then
         call calc_a15(x,delta,dp_dx) ! eq A1.9 = eq A1.5
!        eq A1.3
         do 5 j=1,3
         do 5 i=1,2
            dphi_dx(j) = dphi_dx(j) + dphi_dp(i) * dp_dx(i,j)
 5       continue
      else
         if     (iopt.eq.0) then
!        eq A1.6
            dphi_dx(:) = 0d0
         elseif (iopt.eq.1) then
!        eq A1.10
            dphi_dx(1) = dphi_dp(1)
            dphi_dx(2) = dphi_dp(2)
            dphi_dx(3) = 0d0
         endif
      endif
      ! dphi_dx
      dphi(:)=0d0
      call calc_l(c,l)
      do 10 j=1,3
      do 10 i=1,3
         dphi(j) = dphi(j) + dphi_dx(i) * l(i,j)
 10   continue
      return
      end subroutine calc_dphi_dev
c-----------------------------------------------------------------------
      subroutine calc_a15(x,delta,dp_dx)
c     Arguments
c     x     : linearly transformed stress
c     delta : delta used in the principal stress calculation
c     dp_dx : round (principal stress) / round (linearly transformed stress)
      implicit none
      dimension x(3),dp_dx(2,3)
      real*8 x,delta,dp_dx,deno
      deno = dsqrt(delta)
      dp_dx(1,1) = 0.5d0 * ( 1d0 + (x(1)-x(2))/deno)
      dp_dx(1,2) = 0.5d0 * ( 1d0 - (x(1)-x(2))/deno)
      dp_dx(1,3) = 2.0d0 * x(3) / deno

      dp_dx(2,1) = 0.5d0 * ( 1d0 - (x(1)-x(2))/deno)
      dp_dx(2,2) = 0.5d0 * ( 1d0 + (x(1)-x(2))/deno)
      dp_dx(2,3) =-2.0d0 * x(3) / deno
      return
      end subroutine
c-----------------------------------------------------------------------
      subroutine calc_a14(xp,a,dphi_dp)
c     Arguments
c     xp      : principal components of linearly transformed stress
c     a       : yield function exponent
c     dphi_dp : round(phi) / round(xp)
      implicit none
      dimension xp(2),dphi_dp(2)
      real*8 xp,dphi_dp,a
      dphi_dp(1) = a*(xp(1)-xp(2))**(a-1d0)
      dphi_dp(2) =-a*(xp(1)-xp(2))**(a-1d0)
      end subroutine calc_a14
c-----------------------------------------------------------------------
      subroutine calc_a18(xp,a,dphi_dp)
c     Arguments
c     xp : principal components of linearly transformed stress
c     a  : yield function exponent
c     dphi_dp : round(phi) / round(xp)
      implicit none
      dimension xp(2),dphi_dp(2)
      real*8 xp,dphi_dp,sgn1,sgn2,a
      sgn1=sign(1d0, 2d0*xp(2)+xp(1))
      sgn2=sign(1d0, 2d0*xp(1)+xp(2))

      dphi_dp(1) =       a * dabs(2d0*xp(2) + xp(1))**(a-1d0)*sgn1+
     $             2d0 * a * dabs(2d0*xp(1) + xp(2))**(a-1d0)*sgn2
      dphi_dp(2) = 2d0 * a * dabs(2d0*xp(2) + xp(1))**(a-1d0)*sgn1+
     $                   a * dabs(2d0*xp(1) + xp(2))**(a-1d0)*sgn2
      end subroutine calc_a18
c-----------------------------------------------------------------------
      subroutine calc_l(c,l)
c     Arguments
c     c: c matrix
c     l: l matrix
c     intent(in) c
c     intent(out) l
      implicit none
      dimension c(3,3),l(3,3),t(3,3)
      real*8 c,l,t
      t(:,:)= 0d0
      t(1,1)= 2d0/3d0
      t(1,2)=-1d0/3d0
      t(2,2)= 2d0/3d0
      t(2,1)=-1d0/3d0
      t(3,3)= 1d0
      call mult_array2(c,t,3,l)
      return
      end subroutine calc_l
c-----------------------------------------------------------------------
c     eq (A1.2) delta used in principal stress calculation
      subroutine calc_delta(x,delta)
c     Arguments
c     x: linearly transformed stress using a particular c matrix (intent: in)
c     delta: to be calculated (intent: out)
      implicit none
      dimension x(3)
      real*8 x,delta
      delta = (x(1)-x(2))**2+4d0*x(3)**2d0
      return
      end subroutine calc_delta
c-----------------------------------------------------------------------
      subroutine hershey(xp1,xp2,a,phi1,phi2,dphis_dchi)
c     Arguments
c     x1, x2: two linearly transformed stresses
c     phi1, phi2: the two Hershey components
c     a: exponent
      implicit none
      dimension xp1(2),xp2(2),dphis_dchi(2,2),chis(2,2)
      real*8, intent(in)::xp1,xp2,a
      real*8, intent(out)::phi1,phi2,dphis_dchi
      real*8 tempval1,tempval2,sgn1,sgn2,chis
      phi1 = dabs(xp1(1) - xp1(2))**a
      phi2 = dabs(2d0*xp2(2)+xp2(1))**a +dabs(2d0*xp2(1)+xp2(2))**a

c     dphis/dchi
      chis(1,:)=xp1(:)
      chis(2,:)=xp2(:)

c     dphi1/dchi
      dphis_dchi(1,1) =  a * (chis(1,1) - chis(1,2))**(a-1d0)
      dphis_dchi(1,2) = -dphis_dchi(1,1)
c     dphi2/dchi
      tempval1 = 2d0*chis(2,2) + chis(2,1)
      tempval2 = 2d0*chis(2,1) + chis(2,2)
      sgn1=sign(1d0,tempval1)
      sgn2=sign(1d0,tempval2)
      dphis_dchi(2,1) =       a * dabs(tempval1)**(a-1d0) * sgn1
     $                + 2d0 * a * dabs(tempval2)**(a-1d0) * sgn2
      dphis_dchi(2,2) = 2d0 * a * dabs(tempval1)**(a-1d0) * sgn1
     $                      + a * dabs(tempval2)**(a-1d0) * sgn2
      end subroutine hershey
c-----------------------------------------------------------------------
      subroutine calc_princ(s,xp)
c     Arguments
c     s: stress tensor in the in-plane strss space (sxx,syy,sxy)
c     xp: the two principal components
      implicit none
      dimension xp(2),s(3)
      real*8 xx,yy,xy,f,s,xp
      xx=s(1)
      yy=s(2)
      xy=s(3)
      f  = dsqrt((xx-yy)**2 + 4d0 * xy**2)
      xp(1) = 0.5d0*(xx+yy+f)
      xp(2) = 0.5d0*(xx+yy-f)
      return
      end subroutine calc_princ
c-----------------------------------------------------------------------
c     Convert cauchy stress to linearly transformed X (eq 14 )
      subroutine calc_x(cauchy,c,x)
c     Arguments
c     cauchy : cauchy stress
c     c      : c matrix
c     x      : x tensor
      implicit none
      dimension cauchy(3),c(3,3),x(3),sdev(3)
      real*8 cauchy,c,x,sdev
      call cauchy2sdev(cauchy,sdev)
      call calc_x_dev(sdev,c,x)
      return
      end subroutine calc_x
c-----------------------------------------------------------------------
c     Convert deviatoric stress to linearly transformed X (eq 14 )
      subroutine calc_x_dev(sdev,c,x)
c     Arguments
c     sdev : deviatoric stress
c     c    : c matrix
c     x    : x tensor
      implicit none
      dimension sdev(3),c(3,3),x(3)
      real*8 c,x,sdev
      call mult_array(c,sdev,3,x)
      return
      end subroutine calc_x_dev
c-----------------------------------------------------------------------
c$$$      program test
c$$$      implicit none
c$$$      dimension cauchy(3),dphi(3),d2phi(3,3),c(2,3,3),
c$$$     $     x1(3),x2(3),yldc(9)
c$$$      real*8 cauchy,dphi,d2phi,phi,c,x1,x2,pp,ppp,
c$$$     $     hershey1,hershey2,a,yldc
c$$$      real time0,time1
c$$$
c$$$      cauchy(:)=0d0
c$$$      cauchy(1)=1d0
c$$$      dphi(:)=0d0
c$$$      d2phi(:,:)=0d0
c$$$      call w_chr(0,'cauchy stress')
c$$$      call w_dim(0,cauchy,3,1d0,.true.)
c$$$c$$$      yldc(1:8)=1d0
c$$$c$$$      yldc(9)  =2d0
c$$$      call read_alpha('alfas.txt',yldc)
c$$$
c$$$      call cpu_time(time0)
c$$$      call yld2000_2d(cauchy,phi,dphi,d2phi,yldc)
c$$$      call sleep(2)
c$$$      call cpu_time(time1)
c$$$      write(*,*) time0,time1
c$$$
c$$$      call w_val(0,'phi:',phi)
c$$$      call w_chr(0,'dphi:')
c$$$      call w_dim(0,dphi,3,1d0,.true.)
c$$$c$$$      call w_chr(0,'d2phi:')
c$$$c$$$      call w_mdim(0,d2phi,3,1d0)
c$$$
c$$$      call w_empty_lines(0,3)
c$$$      write(*,'(a,e11.2,a)')'Elapsed time:',
c$$$     $     (time1-time0),'  seconds'
c$$$      write(*,'(a,f7.2,a)')'Elapsed time:',
c$$$     $     (time1-time0)/1d-3,' milli seconds'
c$$$      write(*,'(a,f7.2,a)')'Elapsed time:',
c$$$     $     (time1-time0)/1d-6,' micro seconds'
c$$$      write(*,'(a,f7.2,a)')'Elapsed time:',
c$$$     $     (time1-time0)/1d-9,' nano seconds'
c$$$      end program
c-----------------------------------------------------------------------
      subroutine cauchy2sdev(c,s)
      implicit none
c     Arguments
c     c : c matrix          (in)
c     s : deviatoric stress (out)
      dimension t(3,3),c(3),s(3)
      real*8 t,c,s
      t(:,:)= 0d0
      t(1,1)= 2d0/3d0
      t(1,2)=-1d0/3d0
      t(2,2)= 2d0/3d0
      t(2,1)=-1d0/3d0
      t(3,3)= 1d0
      call mult_array(t,c,3,s)
      return
      end subroutine cauchy2sdev
c-----------------------------------------------------------------------
c     Convert deviatoric stress to x tensor
      subroutine cmat(c,sdev,x)
c     Arguments
c     c    : c matrix
c     sdev : deviatorix stress
c     x    : linearly transformed stress using c
      implicit none
      dimension c(3,3),sdev(3),x(3)
      real*8 c, sdev,x
      call mult_array(c,sdev,3,x)
      return
      end subroutine cmat
c-----------------------------------------------------------------------
c     Convert alpha parameters to c and l matrices
      subroutine alpha2lc(alpha,c,l)
c     Arguments
c     alpha : the 8 parameters
c     C     : C matrix
c     L     : L matrix
      implicit none
      dimension alpha(8),c(2,3,3),l(2,3,3),aux266(2,6,6)
      real*8, intent(in)  :: alpha
      real*8, intent(out) :: c,l
      real*8 aux266,aux66(6,6),aux33(3,3)
      call alpha2l(alpha,aux266)
      aux66(:,:) = aux266(1,:,:)
      call reduce_basis(aux66,aux33)
      l(1,:,:) = aux33
      aux66(:,:) = aux266(2,:,:)
      call reduce_basis(aux66,aux33)
      l(2,:,:) = aux33
      call alpha2c(alpha,aux266)
      aux66(:,:) = aux266(1,:,:)
      call reduce_basis(aux66,aux33)
      c(1,:,:) = aux33
      aux66(:,:) = aux266(2,:,:)
      call reduce_basis(aux66,aux33)
      c(2,:,:) = aux33
      return
      end subroutine alpha2lc
c-----------------------------------------------------------------------
c     Reduce (6,6) matrix to (3,3) by ignoring 4 and 5 components
      subroutine reduce_basis(a,b)
c     Arguments
c     a (6,6) matrix
c     b (3,3) matrix
      implicit none
      dimension a(6,6),b(3,3)
      real*8 a,b
      integer i,j,ii,jj
      do 10 i=1,3
      do 10 j=1,3
         if (i.eq.3) ii=6
         if (i.ne.3) ii=i
         if (j.eq.3) jj=6
         if (j.ne.3) jj=j
         b(i,j) = a(ii,jj)
 10   continue
      return
      end subroutine reduce_basis
c-----------------------------------------------------------------------
      subroutine alpha2l(a,l)
c     Arguments
c     a : the 8 parameters (alpha)
c     l : l matrix in the dimension of (2,3,3)
      implicit none
      dimension a(8), l(2,6,6)
      real*8, intent(in)  :: a
      real*8, intent(out) :: l
      l(:,:,:) = 0d0
!     l`
      l(1,1,1) = 2*a(1)/3
      l(1,1,2) =  -a(1)/3
      l(1,2,1) =  -a(2)/3
      l(1,2,2) = 2*a(2)/3
      l(1,6,6) = a(7)
      l(1,3,1) =-l(1,1,1)-l(1,2,1)
      l(1,3,2) =-l(1,1,2)-l(1,2,2)
      l(1,4,4) = 1d0
      l(1,5,5) = 1d0
      l(1,1,3) =  -a(1)/3
      l(1,2,3) =  -a(2)/3
      l(1,3,3) =-l(1,1,3)-l(1,2,3)
!     l``
      l(2,1,1) = (8*a(5)-2*a(3)-2*a(6)+2*a(4))/9
      l(2,1,2) = (4*a(6)-4*a(4)-4*a(5)+  a(3))/9
      l(2,2,1) = (4*a(3)-4*a(5)-4*a(4)+  a(6))/9
      l(2,2,2) = (8*a(4)-2*a(6)-2*a(3)+2*a(5))/9
      l(2,6,6) = a(8)
      l(2,3,1) =-l(2,1,1)-l(2,2,1)
      l(2,3,2) =-l(2,1,2)-l(2,2,2)
      l(2,4,4) = 1d0
      l(2,5,5) = 1d0
      l(2,1,3) = (a(3)-4*a(5)+2*a(4)-2*a(6))/9
      l(2,2,3) = (2*a(5)-2*a(3)+a(6)-4*a(4))/9
      l(2,3,3) =-l(2,1,3)-l(2,2,3)
      return
      end subroutine alpha2l
c-----------------------------------------------------------------------
      subroutine read_alpha(fn,alpha)
      implicit none
      character (len=*) fn
      character (len=288) prosa
      dimension alpha(9)
      integer iunit,i,k
      parameter(iunit=333)
      real*8 alpha
      open(iunit,file=fn,status='unknown')
      read(iunit,'(a)') prosa
      read(iunit,*) alpha(9)
      read(iunit,'(i3)') k
      read(iunit,'(a)') prosa
      read(iunit,'(a)') prosa
      read(iunit,*) (alpha(i),i=1,8)
      close(iunit)
      end subroutine read_alpha
c-----------------------------------------------------------------------
      subroutine alpha2c(a,c)
c     Arguments
c     a : the 8 parameters (alpha)
c     c : c matrix in the dimension of (2,3,3)
      implicit none
      dimension a(8),c(2,6,6)
      real*8 a, c
      c(:,:,:) = 0d0
c     c`
      c(1,1,1) = a(1)
      c(1,1,2) = 0d0
      c(1,2,1) = 0d0
      c(1,2,2) = a(2)
      c(1,6,6) = a(7)
      c(1,3,1) =-a(1)
      c(1,3,2) =-a(2)
      c(1,4,4) = 1d0
      c(1,5,5) = 1d0
c     c``
      c(2,1,1) = (4*a(5)-a(3))/3
      c(2,1,2) = 2*(a(6)-a(4))/3
      c(2,2,1) = 2*(a(3)-a(5))/3
      c(2,2,2) = (4*a(4)-a(6))/3
      c(2,6,6) = a(8)
      c(2,3,1) =-c(2,1,1)-c(2,2,1)
      c(2,3,2) =-c(2,1,2)-c(2,2,2)
      c(2,4,4) = 1d0
      c(2,5,5) = 1d0
      return
      end subroutine alpha2c
c-----------------------------------------------------------------------
c$$$c     Palmetto
c$$$      include '/home/younguj/repo/abaqusPy/umats/lib/algb.f'
c$$$      include '/home/younguj/repo/abaqusPy/umats/lib/lib_write.f'
c$$$      include '/home/younguj/repo/abaqusPy/umats/lib/lib.f'
c$$$      include '/home/younguj/repo/abaqusPy/umats/lib/is.f'

c     Mac
c$$$      include '/Users/yj/repo/abaqusPy/umats/lib/algb.f'
c$$$      include '/Users/yj/repo/abaqusPy/umats/lib/lib_write.f'
c$$$      include '/Users/yj/repo/abaqusPy/umats/lib/lib.f'
c$$$      include '/Users/yj/repo/abaqusPy/umats/lib/is.f'
