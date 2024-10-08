C   December, 2005 -- updated to work with MODFLOW-2005
C   September, 2000 -- updated to work with MODFLOW-2000
C   May, 2000 -- fixed error that caused incorrect critical head values
C   to be written in an external file when the option to write an
C   external file (IHCSV>0) is used.
C   June, 1996 -- 3 statements in the version documented
C   in TWRI 6-A2 have been modified in order to correct a problem.
C   Although subsidence is only meant to be active for layers in which
C   IBQ>0, some of the subroutines performed subsidence calculations when
C   IBQ<0.  Note that this was a problem only if negative IBQ values
C   were specified.  That is, the code has always worked correctly for
C   IBQ=0 and IBQ>0.
C   September, 2003 -- added the following:
C    1. Print a warning message that the IBS1 Package has been supseseded
C       by the SUB Package.
C    2. If the SUB Package and the IBS package are used simultaneously,
C       stop the simulation.
C
      MODULE GWFIBSMODULE
        INTEGER, SAVE, POINTER    ::IIBSCB,IIBSOC,ISUBFM,ICOMFM,IHCFM
        INTEGER, SAVE, POINTER    ::ISUBUN,ICOMUN,IHCUN
        INTEGER, SAVE,    DIMENSION(:),     POINTER ::IBQ
        INTEGER, SAVE,    DIMENSION(:),     POINTER ::IBQ1
        REAL,    SAVE,    DIMENSION(:,:,:), POINTER ::HC
        REAL,    SAVE,    DIMENSION(:,:,:), POINTER ::SCE
        REAL,    SAVE,    DIMENSION(:,:,:), POINTER ::SCV
        REAL,    SAVE,    DIMENSION(:,:,:), POINTER ::SUB
      TYPE GWFIBSTYPE
        INTEGER,POINTER    ::IIBSCB,IIBSOC,ISUBFM,ICOMFM,IHCFM
        INTEGER,POINTER    ::ISUBUN,ICOMUN,IHCUN
        INTEGER,    DIMENSION(:),     POINTER ::IBQ
        INTEGER,    DIMENSION(:),     POINTER ::IBQ1
        REAL,       DIMENSION(:,:,:), POINTER ::HC
        REAL,       DIMENSION(:,:,:), POINTER ::SCE
        REAL,       DIMENSION(:,:,:), POINTER ::SCV
        REAL,       DIMENSION(:,:,:), POINTER ::SUB
      END TYPE GWFIBSTYPE
      TYPE(GWFIBSTYPE),SAVE ::GWFIBSDAT(10)
      END MODULE GWFIBSMODULE



      SUBROUTINE GWF2IBS7AR(IN,INSUB,IGRID)
C
C  Based on
C-----VERSION 07JUN1996 GWF1IBS6ALP AND VERSION 1117 02JUN1988 GWF1IBS6RPP
C-----VERSION 01AUG1996 -- modified to allow 200 layers instead of 80
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR INTERBED STORAGE PACKAGE
C     READ INTERBED STORAGE DATA
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY: NCOL,NROW,NLAY,IOUT,DELR,DELC,HNEW
      USE GWFIBSMODULE, ONLY: HC,SCE,SCV,SUB,IBQ,IBQ1,IIBSCB,IIBSOC,
     1                        ISUBFM,ICOMFM,IHCFM,ISUBUN,ICOMUN,IHCUN
      CHARACTER*24 ANAME(4)
C
      DATA ANAME(1) /'   PRECONSOLIDATION HEAD'/
      DATA ANAME(2) /'ELASTIC INTERBED STORAGE'/
      DATA ANAME(3) /' VIRGIN INTERBED STORAGE'/
      DATA ANAME(4) /'     STARTING COMPACTION'/
C     ------------------------------------------------------------------
C
      ALLOCATE(IIBSCB,IIBSOC,ISUBFM,ICOMFM,IHCFM,ISUBUN,ICOMUN,IHCUN)
      ALLOCATE(IBQ(NLAY),IBQ1(NLAY))
C
C1------IDENTIFY PACKAGE.
      WRITE(IOUT,*)'IBS:'
!      WRITE(IOUT,1)IN
!    1 FORMAT(1H0,'IBS -- INTERBED STORAGE PACKAGE, VERSION 7,',
!     1     ' 12/27/2005',' INPUT READ FROM UNIT',I3)
C1a------PRINT WARNING MESSAGE THAT PACKAGE HAS BEEN SUPERSEDED.
!      WRITE(IOUT,103)
!  103 FORMAT(1H0,'***NOTICE*** AS OF SEPTEMBER 2003, THE INTERBED ',
!     1     'STORAGE PACKAGE HAS ',/,
!     2     'BEEN SUPERSEDED BY THE SUBSIDENCE AND AQUIFER-SYSTEM ',
!     3     'COMPACTION PACKAGE.',/,' SUPPORT FOR IBS MAY BE ',
!     4     'DISCONTINUED IN THE FUTURE.')
C1b------PRINT A MESSAGE AND STOP THE SIMULATION OF BOTH IBS AND SUB
C1b------ ARE USED.
      IF(INSUB.GT.0) THEN
       WRITE(IOUT,104)
  104  FORMAT(1H0,'***ERROR*** THE IBS AND SUB PACKAGE SHOULD ',
     1     'NOT BOTH BE USED IN ',/,
     2     'THE SAME SIMULATION. ********STOPPING******** ')
       CALL USTOP(' ')
      ENDIF
C
C4------READ FLAG FOR STORING CELL-BY-CELL STORAGE CHANGES AND
C4------FLAG FOR PRINTING AND STORING COMPACTION, SUBSIDENCE, AND
C4------CRITICAL HEAD ARRAYS.
      READ(IN,3) IIBSCB,IIBSOC
    3 FORMAT(2I10)
      WRITE(IOUT,*) 'IIBSCB,IIBSOC:'
      WRITE(IOUT,*) IIBSCB,IIBSOC
C
C5------IF CELL-BY-CELL TERMS TO BE SAVED THEN PRINT UNIT NUMBER.
!      IF(IIBSCB.GT.0) WRITE(IOUT,105) IIBSCB
!  105 FORMAT(1X,'CELL-BY-CELL FLOW TERMS WILL BE SAVED ON UNIT',I3)
C
C5A-----IF OUTPUT CONTROL FOR PRINTING ARRAYS IS SELECTED PRINT MESSAGE.
!      IF(IIBSOC.GT.0) WRITE(IOUT,106)
!  106 FORMAT(1X,'OUTPUT CONTROL RECORDS FOR IBS PACKAGE WILL BE ',
!     1 'READ EACH TIME STEP.')
C
C6------READ INDICATOR AND FIND OUT HOW MANY LAYERS HAVE INTERBED STORAGE.
      READ(IN,110) (IBQ(K),K=1,NLAY)
  110 FORMAT(40I2)
      WRITE(IOUT,*) '(IBQ(K),K=1,NLAY):'
      WRITE(IOUT,*) (IBQ(K),K=1,NLAY)
      NAQL=0
      DO 120 K=1,NLAY
      IF(IBQ(K).LE.0) GO TO 120
      NAQL=NAQL+1
      IBQ1(NAQL)=K
  120 CONTINUE
C
C7------IDENTIFY WHICH LAYERS HAVE INTERBED STORAGE.
!      WRITE(IOUT,130) (IBQ1(K),K=1,NAQL)
!  130 FORMAT(1X,'INTERBED STORAGE IN LAYER(S) ',80I2)
C
C8------ALLOCATE SPACE FOR THE ARRAYS HC, SCE, SCV, AND SUB.
      IF(NAQL.GT.0) THEN
        ALLOCATE(HC(NCOL,NROW,NAQL))
        ALLOCATE(SCE(NCOL,NROW,NAQL))
        ALLOCATE(SCV(NCOL,NROW,NAQL))
        ALLOCATE(SUB(NCOL,NROW,NAQL))
      ELSE
        ALLOCATE(HC(1,1,1))
        ALLOCATE(SCE(1,1,1))
        ALLOCATE(SCV(1,1,1))
        ALLOCATE(SUB(1,1,1))
      END IF
C
C9------READ IN STORAGE AND CRITICAL HEAD ARRAYS
      KQ=0
      DO 160 K=1,NLAY
      IF(IBQ(K).LE.0) GO TO 160
      KQ=KQ+1
      CALL U2DREL(HC(:,:,KQ),ANAME(1),NROW,NCOL,K,IN,IOUT)
      CALL U2DREL(SCE(:,:,KQ),ANAME(2),NROW,NCOL,K,IN,IOUT)
      CALL U2DREL(SCV(:,:,KQ),ANAME(3),NROW,NCOL,K,IN,IOUT)
      CALL U2DREL(SUB(:,:,KQ),ANAME(4),NROW,NCOL,K,IN,IOUT)
  160 CONTINUE
C
C10-----LOOP THROUGH ALL CELLS WITH INTERBED STORAGE.
      KQ=0
      DO 180 K=1,NLAY
      IF(IBQ(K).LE.0) GO TO 180
      KQ=KQ+1
      DO 170 IR=1,NROW
      DO 170 IC=1,NCOL
C
C11-----MULTIPLY STORAGE BY AREA TO GET STORAGE CAPACITY.
      AREA=DELR(IC)*DELC(IR)
      SCE(IC,IR,KQ)=SCE(IC,IR,KQ)*AREA
      SCV(IC,IR,KQ)=SCV(IC,IR,KQ)*AREA
C
C12-----MAKE SURE THAT PRECONSOLIDATION HEAD VALUES
C12-----ARE CONSISTANT WITH STARTING HEADS.
      IF(HC(IC,IR,KQ).GT.HNEW(IC,IR,K)) HC(IC,IR,KQ)=HNEW(IC,IR,K)
  170 CONTINUE
  180 CONTINUE
C
C13-----INITIALIZE AND READ OUTPUT FLAGS.
      ICOMFM=0
      ISUBFM=0
      IHCFM=0
      ICOMUN=0
      ISUBUN=0
      IHCUN=0
      IF(IIBSOC.LE.0) GO TO 200
      READ(IN,190) ISUBFM,ICOMFM,IHCFM,ISUBUN,ICOMUN,IHCUN
  190 FORMAT(6I10)
      WRITE(IOUT,*) 'ISUBFM,ICOMFM,IHCFM,ISUBUN,ICOMUN,IHCUN:'
      WRITE(IOUT,*) ISUBFM,ICOMFM,IHCFM,ISUBUN,ICOMUN,IHCUN
!      WRITE(IOUT,191) ISUBFM,ICOMFM,IHCFM
!  191 FORMAT(1H0,'    SUBSIDENCE PRINT FORMAT IS NUMBER',I4/
!     1          '     COMPACTION PRINT FORMAT IS NUMBER',I4/
!     2          '  CRITICAL HEAD PRINT FORMAT IS NUMBER',I4)
!      IF(ISUBUN.GT.0) WRITE(IOUT,192) ISUBUN
!  192 FORMAT(1H0,'    UNIT FOR SAVING SUBSIDENCE IS',I4)
!      IF(ICOMUN.GT.0) WRITE(IOUT,193) ICOMUN
!  193 FORMAT(1H ,'    UNIT FOR SAVING COMPACTION IS',I4)
!      IF(IHCUN.GT.0)  WRITE(IOUT,194) IHCUN
!  194 FORMAT(1H ,' UNIT FOR SAVING CRITICAL HEAD IS',I4)
C
C14-----RETURN
  200 CALL SGWF2IBS7PSV(IGRID)
      RETURN
      END
!      SUBROUTINE GWF2IBS7ST(KPER,IGRID)
C
C-----Based on VERSION 15SEPT2000 GWF1IBS6ST
C     ******************************************************************
C     CHECK THAT NO STREE PERIOD IS STEADY STATE EXCEPT THE FIRST, AND
C     SET HC EQUAL TO THE STEADY-STATE HEAD IF STEADY-STATE HEAD IS
C     LOWER THAN HC.
C     ******************************************************************
!      SUBROUTINE GWF2IBS7FM(KPER,IGRID)
C
C  Based on:
C-----VERSION 07JUN1996 GWF1IBS6FM
C-----VERSION 01AUG1996 -- modified to allow 200 layers instead of 80
C     ******************************************************************
C        ADD INTERBED STORAGE TO RHS AND HCOF
C     ******************************************************************
!      SUBROUTINE GWF2IBS7BD(KSTP,KPER,IGRID)
C  Based on:
C-----VERSION 07JUN1996 GWF1IBS6BD
C-----VERSION 01AUG1996 -- modified to allow 200 layers instead of 80
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR INTERBED STORAGE
C     ******************************************************************
!      SUBROUTINE GWF2IBS7OT(KSTP,KPER,IN,IGRID)
C  Based on
C-----VERSION 07JUN1996 GWF1IBS6OT
C-----VERSION 01AUG1996 -- modified to allow 200 layers instead of 80
C     ******************************************************************
C     PRINT AND STORE SUBSIDENCE, COMPACTION AND CRITICAL HEAD.
C     ******************************************************************
      SUBROUTINE GWF2IBS7DA(IGRID)
C  Deallocate IBS DATA
      USE GWFIBSMODULE
C
        DEALLOCATE(GWFIBSDAT(IGRID)%IIBSCB)
        DEALLOCATE(GWFIBSDAT(IGRID)%IIBSOC)
        DEALLOCATE(GWFIBSDAT(IGRID)%ISUBFM)
        DEALLOCATE(GWFIBSDAT(IGRID)%ICOMFM)
        DEALLOCATE(GWFIBSDAT(IGRID)%IHCFM)
        DEALLOCATE(GWFIBSDAT(IGRID)%ISUBUN)
        DEALLOCATE(GWFIBSDAT(IGRID)%ICOMUN)
        DEALLOCATE(GWFIBSDAT(IGRID)%IHCUN)
        DEALLOCATE(GWFIBSDAT(IGRID)%IBQ)
        DEALLOCATE(GWFIBSDAT(IGRID)%IBQ1)
        DEALLOCATE(GWFIBSDAT(IGRID)%HC)
        DEALLOCATE(GWFIBSDAT(IGRID)%SCE)
        DEALLOCATE(GWFIBSDAT(IGRID)%SCV)
        DEALLOCATE(GWFIBSDAT(IGRID)%SUB)
C
      RETURN
      END
      SUBROUTINE SGWF2IBS7PNT(IGRID)
C  Set IBS pointers for grid.
      USE GWFIBSMODULE
C
        IIBSCB=>GWFIBSDAT(IGRID)%IIBSCB
        IIBSOC=>GWFIBSDAT(IGRID)%IIBSOC
        ISUBFM=>GWFIBSDAT(IGRID)%ISUBFM
        ICOMFM=>GWFIBSDAT(IGRID)%ICOMFM
        IHCFM=>GWFIBSDAT(IGRID)%IHCFM
        ISUBUN=>GWFIBSDAT(IGRID)%ISUBUN
        ICOMUN=>GWFIBSDAT(IGRID)%ICOMUN
        IHCUN=>GWFIBSDAT(IGRID)%IHCUN
        IBQ=>GWFIBSDAT(IGRID)%IBQ
        IBQ1=>GWFIBSDAT(IGRID)%IBQ1
        HC=>GWFIBSDAT(IGRID)%HC
        SCE=>GWFIBSDAT(IGRID)%SCE
        SCV=>GWFIBSDAT(IGRID)%SCV
        SUB=>GWFIBSDAT(IGRID)%SUB
C
      RETURN
      END
      SUBROUTINE SGWF2IBS7PSV(IGRID)
C  Save IBS pointers for grid.
      USE GWFIBSMODULE
C
        GWFIBSDAT(IGRID)%IIBSCB=>IIBSCB
        GWFIBSDAT(IGRID)%IIBSOC=>IIBSOC
        GWFIBSDAT(IGRID)%ISUBFM=>ISUBFM
        GWFIBSDAT(IGRID)%ICOMFM=>ICOMFM
        GWFIBSDAT(IGRID)%IHCFM=>IHCFM
        GWFIBSDAT(IGRID)%ISUBUN=>ISUBUN
        GWFIBSDAT(IGRID)%ICOMUN=>ICOMUN
        GWFIBSDAT(IGRID)%IHCUN=>IHCUN
        GWFIBSDAT(IGRID)%IBQ=>IBQ
        GWFIBSDAT(IGRID)%IBQ1=>IBQ1
        GWFIBSDAT(IGRID)%HC=>HC
        GWFIBSDAT(IGRID)%SCE=>SCE
        GWFIBSDAT(IGRID)%SCV=>SCV
        GWFIBSDAT(IGRID)%SUB=>SUB
C
      RETURN
      END
