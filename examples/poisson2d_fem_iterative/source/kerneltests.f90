MODULE kerneltests

use system
use kernels
use omp_lib

implicit none

CONTAINS


  !------------------------------------------------------------------------------
  ! kernel test driver
  !------------------------------------------------------------------------------
  SUBROUTINE testsuite(n,n_loops,n_maxthreads)

    integer :: n, n_loops, n_maxthreads

    ! Local variables
    real(RP), allocatable, dimension(:,:) :: x1, x2, x3
    real(RP)  :: s(3,3)
    integer   :: i, i_test, n1, n2, n_threads
    real(DP)  :: t0, t1, times(n_loops), tav, tref, dtmp
    character(len=40) :: ctest
    !------------------------------------------------------------------------------

    s = 2.1_RP

    write (*,*) 
    write (*,*) '---------------------------------------'
    write (*,*) '           kernel timings'
    write (*,*) '---------------------------------------'

    testrun: do i_test=1,3

    ! matrix-vector
    do n_threads=1,n_maxthreads
       call omp_set_num_threads(n_threads)

       n1 = n*n_threads
       n2 = n
       allocate(x1(n1,n2))
       allocate(x2(n1,n2))
       allocate(x3(n1,n2))
       x1 = 1.2_RP
       x2 = 1.3_RP
       x3 = 1.4_RP

       do i=1,n_loops

          call ztime(t0)
          select case (i_test)

             case (1)
                ctest = '    matrix-vector'
                call call_matvec(n1,n2,x1,s,x2,-1.0_RP,x3)

             case (2)
                ctest = '    jacobi iteration'
                call call_jacobi(n1,n2,x1,x2,x3,s)

             case (3)
                ctest = '    sor/gauss-seidel iteration'
                call call_sorgs(n1,n2,x1,x2,s)

          end select
          call ztime(t1)
          times(i) = t1-t0

       end do

       tav = sum(times(2:n_loops-1))/(n_loops-2)
       if ( n_threads==1 ) then
          tref = tav
       endif
       call output(ctest,n_threads,tav,(n1-2)*(n2-2),n_flops_mv,n_memw_mv,tav/tref)

       deallocate(x3)
       deallocate(x2)
       deallocate(x1)

    end do

    write (*,*) '---------------------------------------'
    end do testrun

  END SUBROUTINE testsuite
  !------------------------------------------------------------------------------


  !------------------------------------------------------------------------------
  ! kernel test driver
  !------------------------------------------------------------------------------
  SUBROUTINE output(ctest,nt,t,n,n_flops,n_memw,xfac)

    real(DP) :: t, bwf, bwm, xfac
    integer  :: n, nt, n_flops, n_memw
    character(len=40) :: ctest
    !------------------------------------------------------------------------------

    bwf  = n_flops*n/t/1.0e9_DP
    bwm  = n_bpw*n_memw*n/t/(1024**3)

    if ( nt==1 ) then
       write (*,'(a)') ctest
       write (*,*) '---------------------------------------'
       write (*,*) 'nt |  CPU time |   Gf/s |   GB/s |   x '
       write (*,*) '---------------------------------------'
    end if

    write (*,'(I3,A,E9.2,A,F6.1,A,F6.1,A,F4.1,A)') &
         nt,' | ',t,' | ',bwf,' | ',bwm,' | ',xfac

  END SUBROUTINE output
  !------------------------------------------------------------------------------


END MODULE kerneltests