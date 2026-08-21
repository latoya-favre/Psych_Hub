************************************************
Read in sources and create manual norms tables:
Admin: (complete)
A.1   Scaled Score Equivalents of Total Raw Scores for Subtests, by Age Group
C.6   Standard Subtest and Process Score Equivalents of Total Raw Scores for Ancillary Subtests, by Age Group
C.14  Scaled Score Equivalents of Process Total Raw Scores, by Age Group
************************************************;
proc datasets kill nolist; 
options compress=yes nomprint nocenter ps=100;run;
dm 'log' clear; dm 'output' clear;

*%let pa=C:\Projects;
%let pa=K:\Clinical Psychometrics\ongoing projects;
*%let pa=K:\ongoing projects;

%let sipath=C:\projects\WAIS5\norms\subtest;
%let xlspath=C:\projects\WAIS5\tables\excel;
libname sas1 "C:\projects\WAIS5\tables\SAS tables\norm\Subtest";
/*libname sas2 "&pa.\WISC5\Stdz\tables\SAS tables\norm\Process";*/
/*libname sas3 "&pa.\WISC5\Stdz\tables\SAS tables\norm\Ancillary";*/
%include "C:\projects\WAIS5\sas code\macros\wais5 norm macro.sas";
%include "C:\projects\WAIS5\sas code\macros\oneTableCVT (2).sas";

%let group     = ss;
%LET day=%SYSFUNC(date(), date7.);

************************************************
import all subtest norms via their xls out tab
************************************************;
%macro getsub19 (norm, tot, ss);
options nolabel;
PROC IMPORT OUT= &norm.
            DATAFILE= "&sipath.\&norm norms.xlsx"
            DBMS=EXCEL REPLACE;
     SHEET="out$";      GETNAMES=YES;     MIXED=NO;     SCANTEXT=YES;     USEDATE=YES;     SCANTIME=YES;

RUN;
proc sort data=&norm.; by &tot; run;
data &norm.; set &norm.; where &tot~=.; subtest="          "; subtest="&norm.";
   array scr ss: ;
   do over scr; if scr>19 then scr=19; end;
run;
options label;
%mend;

%macro getsub155 (norm, tot, ss);
options nolabel;
PROC IMPORT OUT= &norm.
            DATAFILE= "&sipath.\&norm norms.xlsx"
            DBMS=EXCEL REPLACE;
     SHEET="out$";      GETNAMES=YES;     MIXED=NO;     SCANTEXT=YES;     USEDATE=YES;     SCANTIME=YES;

RUN;
proc sort data=&norm.; by &tot; run;
data &norm.; set &norm.; where &tot~=.; subtest="          "; subtest="&norm.";
run;
options label;
%mend;
/* subtest norms */
*%getsub (norm, tot);
%getsub19 (si, wais5_si_raw);
%getsub19 (bd, wais5_bd_raw);
%getsub19 (mr, wais5_mr_raw);
%getsub19 (df, wais5_df_raw);
%getsub19 (dq, wais5_dq_raw);
%getsub19 (cd, wais5_cd_raw);
%getsub19 (vc, wais5_vc_raw);
%getsub19 (fw, wais5_fw_raw);
%getsub19 (vp, wais5_vp_raw);
%getsub19 (rd, wais5_rd_raw);
%getsub19 (ss, wais5_ss_raw);
%getsub19 (in, wais5_in_raw);
%getsub19 (ar, wais5_ar_raw);
%getsub19 (db, wais5_db_raw);
%getsub19 (ssp, wais5_ssp_raw);
%getsub19 (nsq, wais5_nsq_raw);
%getsub19 (co, wais5_co_raw);
%getsub19 (sr, wais5_sr_raw);
%getsub19 (sa, wais5_sa_raw);
%getsub19 (ln, wais5_ln_raw);

/*%getsub155 (rnco, wisc5_rnco_t);*NSco normed 1-410 theor 1-600*;*/
/*%getsub155 (rnsco, wisc5_rnsco_t);*NSsco normed 1-460 theor 1-600*;*/
/*%getsub155 (rnln, wisc5_rnln_t);*NSln normed 1-260 theor 1-600*;*/
/*%getsub155 (rnq, wisc5_rnq_t);*NSQ normed 1-160 theor 1-600*;*/
/*%getsub155 (rnli, wisc5_rnli_t);*NSL ng1-3:normed 1-800 theor 1-1200 ng4-9:normed 1-500 theor 1-1200 ng10-33:normed 1-260 theor 1-600*;*/
/*%getsub155 (pa1, wisc5_pa1_raw);*IST*;*/
/*%getsub155 (pad, wisc5_pad_raw);*DST*;*/
/*%getsub155 (pac, wisc5_pac_raw);*RST*; *f35 extra*;*/

*** change names to final and extend norms to theoretical max where appropriate ***;
/*data bdn; set bdnb(rename=(wisc5_bdnb_raw=wisc5_bdn_raw)); subtest="bdn";run;*/
/*%let new=nsco; */
/*%let old=rnco;*/
/*data &new;  set &old (rename=(wisc5_&old._t =wisc5_&new._t)); subtest="&new"; */
/*   if wisc5_&new._t<=410 then output;*/
/*   if wisc5_&new._t =410 then do;*/
/*      do wisc5_&new._t=411 to 600; output; end;*/
/*   end;*/
/*   drop ss4-ss33;*/
/*run;*/
/*%let new=nssco; */
/*%let old=rnsco;*/
/*data &new;  set &old (rename=(wisc5_&old._t =wisc5_&new._t));  subtest="&new";  */
/*   if wisc5_&new._t<=460 then output;*/
/*   if wisc5_&new._t =460 then do;*/
/*      do wisc5_&new._t=461 to 600; output; end;*/
/*   end;*/
/*   drop ss10-ss33;*/
/*run;*/
/*%let new=nsln; */
/*%let old=rnln;*/
/*data &new;  set &old (rename=(wisc5_&old._t =wisc5_&new._t));   subtest="&new"; */
/*   if wisc5_&new._t<=260 then output;*/
/*   if wisc5_&new._t =260 then do;*/
/*      do wisc5_&new._t=261 to 600; output; end;*/
/*   end;*/
/*   drop ss1-ss3;*/
/*run;*/
/*%let new=nsq; */
/*%let old=rnq;*/
/*data &new;  set &old (rename=(wisc5_&old._t =wisc5_&new._t));   subtest="&new"; */
/*   if wisc5_&new._t<=160 then output;*/
/*   if wisc5_&new._t =160 then do;*/
/*      do wisc5_&new._t=161 to 600; output; end;*/
/*   end;*/
/*run;*/
*NSL ng1-3:normed 1-800 theor 1-1200 ng4-9:normed 1-500 theor 1-1200 ng10-33:normed 1-260 theor 1-600*;
/*%let new=nsl; */
/*%let old=rnli;*/
/*data &new;  set &old (rename=(wisc5_&old._t =wisc5_&new._t));   subtest="&new"; */
/*   if wisc5_&new._t<=800 then output;*/
/*   if wisc5_&new._t =800 then do;*/
/*      do wisc5_&new._t=801 to 1200; output; end;*/
/*   end;*/
/*run;*/
/*data nsl; set nsl;*/
/*   array one ss1-ss3;*/
/*   array two ss4-ss9;*/
/*   array tre ss10-ss33;*/
/*   if wisc5_&new._t in (801:1200) then do; do over one; one=45; end; end;*/
/*   if wisc5_&new._t in (501:1200) then do; do over two; two=45; end; end;*/
/*   if wisc5_&new._t in (261:600)  then do; do over tre; tre=45; end; end;*/
/*run;*/
/*data ist; set pa1(rename=(wisc5_pa1_raw=wisc5_ist_raw));  subtest="&new"; run;*/
/*data dst; set pad(rename=(wisc5_pad_raw=wisc5_dst_raw));  subtest="&new"; run;*/
/*data rst; set pac(rename=(wisc5_pac_raw=wisc5_rst_raw));  subtest="&new"; run;*/

%raw_trans (si, wais5_si_raw, 1,13);
%raw_trans (bd, wais5_bd_raw, 1,13);
%raw_trans (mr, wais5_mr_raw, 1,13);
%raw_trans (df, wais5_df_raw, 1,13);
%raw_trans (dq, wais5_dq_raw, 1,13);
%raw_trans (cd, wais5_cd_raw, 1,13);
%raw_trans (vc, wais5_vc_raw, 1,13);
%raw_trans (fw, wais5_fw_raw, 1,13);
%raw_trans (vp, wais5_vp_raw, 1,13);
%raw_trans (rd, wais5_rd_raw, 1,13);
%raw_trans (ss, wais5_ss_raw, 1,13);
%raw_trans (in, wais5_in_raw, 1,13);
%raw_trans (ar, wais5_ar_raw, 1,13);
%raw_trans (db, wais5_db_raw, 1,13);
%raw_trans (ssp, wais5_ssp_raw, 1,13);
%raw_trans (nsq, wais5_nsq_raw, 1,13);
%raw_trans (co, wais5_co_raw, 1,13);
%raw_trans (sr, wais5_sr_raw, 1,13);
%raw_trans (sa, wais5_sa_raw, 1,13);
%raw_trans (ln, wais5_ln_raw, 1,13);

***********************************
create table output for Admin table A.1
**********************************;
data baseA1; 
   do sscr=1 to 19; output; end;
run;
data tblA1(rename=(sscr=Scaled_Score sscr2=Scaled_Score2)); merge baseA1 
N_si N_bd N_mr N_df N_dq N_cd N_vc N_fw N_vp N_rd N_ss N_in N_ar N_db N_ssp N_nsq N_co N_sr N_sa N_ln;
   by sscr;
   sscr2=sscr;
   label sscr='Scaled Score';
   label sscr2='Scaled Score';
   ** fill any blanks from individual subtests with em-dashes **;
   array scrs _CHARACTER_ ;
   do over scrs; if scrs='' then scrs=byte(151); end;** em-dash **;
run;

%macro outA1(ngrp,age);
/*data sas1.A1_6_0; set tblA1; */
/*   keep Scaled_Score BD_1 SI_1 MR_1 DS_1 CD_1 VC_1 FW_1 VP_1 PS_1 SS_1 IN_1 PC_1 LN_1 CA_1 CO_1 AR_1 Scaled_Score2;*/
/*run;*/
data Admin_A1_&age(rename=(
 si_&ngrp=si  bd_&ngrp=bd  mr_&ngrp=mr  df_&ngrp=df  dq_&ngrp=dq  cd_&ngrp=cd  vc_&ngrp=vc  fw_&ngrp=fw  vp_&ngrp=vp
 rd_&ngrp=rd  ss_&ngrp=ss  in_&ngrp=in ar_&ngrp=ar  db_&ngrp=db  ssp_&ngrp=ssp  nsq_&ngrp=nsq  co_&ngrp=co  sr_&ngrp=sr  
 sa_&ngrp=sa  ln_&ngrp=ln)); 
set tblA1; 
   keep Scaled_Score 
       si_&ngrp  bd_&ngrp  mr_&ngrp  df_&ngrp  dq_&ngrp  cd_&ngrp  vc_&ngrp  fw_&ngrp  vp_&ngrp
       rd_&ngrp  ss_&ngrp  in_&ngrp ar_&ngrp  db_&ngrp  ssp_&ngrp  nsq_&ngrp  co_&ngrp  sr_&ngrp  
       sa_&ngrp  ln_&ngrp Scaled_Score2;
run;

%tableC(inlib=work, outlib=work, dsn=Admin_A1_&age, 
  statlist=0dec char char char char char char char char char char char char char char char char char char char char 0dec,  
  ctlvar=,
  clen=15);

data sas1.Admin_A1_&age; set Admin_A1_&age.b; run;

proc export data=sas1.Admin_A1_&age outfile= "&xlspath\Admin_A.1_Subtest_Scaled_Score_Norms.xlsx" replace; 
   sheet="A1_&age";
run;
%mend;
*%outA1(ngrp,age);
%outA1(1,16_17);
%outA1(2,18_19);
%outA1(3,20_24);
%outA1(4,25_29);
%outA1(5,30_34);
%outA1(6,35_44);
%outA1(7,45_54);
%outA1(8,55_64);
%outA1(9,65_69);
%outA1(10,70_74);
%outA1(11,75_79);
%outA1(12,80_84);
%outA1(13,85_90);

*****************
    THE END
*****************;



