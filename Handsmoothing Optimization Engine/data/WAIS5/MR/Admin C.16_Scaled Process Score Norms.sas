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
libname sas1 "C:\projects\WAIS5\tables\SAS tables\norm\process";
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
%getsub19 (bdn, wais5_bdn_raw);
%getsub19 (bdp, wais5_bdp_raw);
%getsub19 (dsp, wais5_dsp_raw);

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

%raw_trans (bdn, wais5_bdn_raw, 1,13);
%raw_trans (bdp, wais5_bdp_raw, 1,13);
%raw_trans (dsp, wais5_dsp_raw, 1,13);

***********************************
create table output for Admin table A.1
**********************************;
data baseA1; 
   do sscr=1 to 19; output; end;
run;
data tblC16(rename=(sscr=Scaled_Score sscr2=Scaled_Score2)); merge baseA1 
N_bdn N_bdp N_dsp;
   by sscr;
   sscr2=sscr;
   label sscr='Scaled Score';
   label sscr2='Scaled Score';
   ** fill any blanks from individual subtests with em-dashes **;
   array scrs _CHARACTER_ ;
   do over scrs; if scrs='' then scrs=byte(151); end;** em-dash **;
run;

%macro outA1(ngrp,age);
data Admin_C16_&age(rename=(
 bdn_&ngrp=bdn  bdp_&ngrp=bdp  dsp_&ngrp=dsp)); 
set tblC16; 
   keep Scaled_Score bdn_&ngrp bdp_&ngrp dsp_&ngrp Scaled_Score2;
run;

%tableC(inlib=work, outlib=work, dsn=Admin_C16_&age, 
  statlist=0dec char char char 0dec,  
  ctlvar=,
  clen=15);

data sas1.Admin_C16_&age; set Admin_C16_&age.b; run;

proc export data=sas1.Admin_C16_&age outfile= "&xlspath\Admin_C.16_Scaled_Process_Score_Norms.xlsx" replace; 
   sheet="C16_&age";
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



