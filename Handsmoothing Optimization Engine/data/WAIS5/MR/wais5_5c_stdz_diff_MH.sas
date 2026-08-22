/********************************************************/
/*        Mantel Haenszel DIF Analysis Macro            */
/********************************************************/
/* Started by Hsinyi Chen, James Yang & J.J. Zhu        */
/* Revised by Bin Chen, & Xiaobin Zhou 2009             */
/* Revised by Tianshu Pan 2009, 2014                    */
/********************************************************/
/*This macro detects DIF using Mantel-Haenszel method   */
/********************************************************/
/* Macro Variable Definition:                           */
/* DATA: input SAS data file name                       */
/* ITEM: item score variable list for DIF analysis      */
/* VAR : Matching Variable Name, Default total raw score*/
/*nslice:number of ability groups for matching control  */
/* grp : group membership variable for DIF analysis     */
/* ref: group variable value1 for reference group       */
/* foc: group variable value2 for focal group           */
/*reflab: reference group label                         */
/*foclab: reference group label                         */
/* out : output SAS data file name                      */
/********************************************************/
proc datasets kill; run; quit;
options nomprint nomlogic;
%LET day=%SYSFUNC(date(), date7.);

%include 'C:\projects\WAIS5\sas code\macros\DIF_MH.sas';
/*  Note: Oversample does not discontine so use administered item scores     */
/*         (recode -7,-8 to missing)                                         */
/* Differential item functioning analysis by P/SED, sex, and race for the following subtests: SI, VC, IN, CO, SR, AR */
/* Andrea Olson 20aug2019                                                    */
/*updated for 50% analysis - David Crittnedon								 */

%LET day=%SYSFUNC(date(), date7.);

/*libname k 'K:\Clinical Psychometrics\ongoing projects\WAIS5\stdz\data';*/
libname c 'C:\projects\WAIS5\data\_100pct_2024';

proc datasets kill; run; quit;
data wais;
 set c.wais5_stdz_scored_final_2024 /*wais5_stdz_scored_dc_&day.*/
(keep=teid agey agegrp stdz sex edl eth region clingrp data_type 
wais5_si_s01-wais5_si_s18
wais5_vc_s01-wais5_vc_s24
wais5_in_s01-wais5_in_s24
wais5_co_s01-wais5_co_s18
wais5_sr_s01-wais5_sr_s27
wais5_arnb_s01-wais5_arnb_s22
wais5_ar_s01-wais5_ar_s22
);
rename 
wais5_si_s01-wais5_si_s18 = sis01-sis18
wais5_vc_s01-wais5_vc_s24 = vcs01-vcs24
wais5_in_s01-wais5_in_s24 = ins01-ins24
wais5_co_s01-wais5_co_s18 = cos01-cos18
wais5_sr_s01-wais5_sr_s27 = srs01-srs27
wais5_arnb_s01-wais5_arnb_s22 = arnbs01-arnbs22
wais5_ar_s01-wais5_ar_s22 = arbns01-arbns22
;
/* if white='1' then white='Y';*/
/* if white='0' then white='N';*/

 if sex='F' then female_male='F';
 if sex='M' then female_male='M';

 if eth='WH' then white_black='WH';
 if eth='BL' then white_black='BL';

 if eth='WH' then white_hispanic='WH';
 if eth='HI' then white_hispanic='HI';

 if edl=5 then ed_5_12='ed5 ';
 if edl=1 then ed_5_12='ed12';
 if edl=2 then ed_5_12='ed12';

 if edl=5 then ed_5_3='ed5';
 if edl=3 then ed_5_3='ed3';

 if stdz='Y';
run;
proc freq data=wais; table sex edl eth region ; run;

proc freq data=wais; table female_male white_black white_hispanic ed_5_12 ed_5_3; run;

data aa; set wais;
  keep sex eth edl female_male white_black white_hispanic ed_5_12 ed_5_3;
  if white_black=' ';run;

proc freq data=wais; table sex*female_male eth*white_black eth*white_hispanic edl*ed_5_12 edl*ed_5_3 /list missing; run;


%macro run_diff_DIF_MH(data= ,nslice= ,item= ,grp= ,ref= ,foc= ,reflab= ,foclab= ,out= ); 

/*check n-count per group per item*/
data temp; set wais; keep &item &grp; 
    array xx &item;
    do over xx; if xx~=. then xx=1; end;
run;
/*ods listing close;*/
proc tabulate data=temp out=ttab missing; class &item &grp; table &item ,&grp; run;
data ttab; set ttab; 
    length item $30;
    array xx(*) &item;
    do i=1 to dim(xx);
        if xx{i}=1 then item=VNAME(xx{i});
    end;
    keep  &grp n item;
    if item~='';
run;
/*ods listing;*/
proc sort data=ttab; by item &grp; run;
proc transpose data=ttab out=ttab(drop=_name_); id &grp; by item; var n; run;
proc print data=ttab noobs; run;

title1 "DIF Analysis (&item &grp)";
%DIF_MH(data=&data ,nslice=&nslice ,item=&item ,grp=&grp ,ref=&ref ,foc=&foc ,reflab=&reflab ,foclab=&foclab ,out=&out ); 

proc sort data=&out ; by itemlab; run;
proc sort data=ttab ; by item; run;
data &out; merge &out ttab(rename=(item=itemlab)); by itemlab; run;
proc export data=&out outfile="C:\projects\WAIS5\results\_100pct_analysis_2024\wais5_stdz_mh_diff_&day..xlsx" dbms=xlsx replace; sheet="&out"; run;

proc datasets; delete ttab; run; quit;
%mend;
%macro run_all_diff(it=,ab=);
%run_diff_DIF_MH(data=wais,nslice=4,item=&it ,grp=female_male   ,ref=M   ,foc=F  ,reflab='Male'     ,foclab='Female'    ,out=&ab._fm); 
%run_diff_DIF_MH(data=wais,nslice=4,item=&it ,grp=white_black   ,ref=BL  ,foc=WH ,reflab='Black'    ,foclab='White'     ,out=&ab._wb); 
%run_diff_DIF_MH(data=wais,nslice=4,item=&it ,grp=white_hispanic,ref=HI  ,foc=WH ,reflab='Hispanic' ,foclab='White'     ,out=&ab._wh); 
%run_diff_DIF_MH(data=wais,nslice=4,item=&it ,grp=ed_5_12       ,ref=ed12,foc=ed5,reflab='<12 years',foclab='>=16 years',out=&ab._ed512); 
%run_diff_DIF_MH(data=wais,nslice=4,item=&it ,grp=ed_5_3        ,ref=ed3 ,foc=ed5,reflab='12 years' ,foclab='>=16 years',out=&ab._ed53);
/*here! how do we know what value for nslice???  
standard MH code uses 4
my wisc5 winsteps uses 0.1
*/
title;
%mend;

* Example 1: 
 DIF analysis for 0-1 score using total raw score as matching variable;
Title1 "Similarities";
%run_all_diff(it=sis01-sis18,ab=si);

Title1 "Vocabulary";
%run_all_diff(it=vcs01-vcs24,ab=vc);

Title1 "Information";
%run_all_diff(it=ins01-ins24,ab=in);

Title1 "Comprehension";
%run_all_diff(it=cos01-cos18,ab=co);

Title1 "Set Relations";
%run_all_diff(it=srs01-srs27,ab=sr);

Title1 "Arithmetic No Bonus";
%run_all_diff(it=arnbs01-arnbs22,ab=arnb);

Title1 "Arithmetic With Bonus";
%run_all_diff(it=arbns01-arbns22,ab=arbn);

title; footnote;
*******************************
end of code
*******************************;
