************************************************
Read in sources and create manual norms tables:
Admin: (complete)
Admin A.3	 Standard Score Norm: VCI
Admin A.4	Standard Score Norm: VSI
Admin A.5	Standard Score Norm: FRI
Admin A.6	Standard Score Norm: WMI
Admin A.7	Standard Score Norm: PSI
Admin A.8	Standard Score Norm: FSIQ
Admin C.1	Standard Score Norm: VECI 
Admin C.2	Standard Score Norm: VRI
Admin C.3	Standard Score Norm: EVSI
Admin C.4	Standard Score Norm: EFI
Admin C.5	Standard Score Norm: QRI 
Admin C.6	Standard Score Norm: EWMI
Admin C.7	Standard Score Norm: VWMI 
Admin C.8	Standard Score Norm: AWMI-R
Admin C.9	Standard Score Norm: AWMI-M
Admin C.10	Standard Score Norm: EPSI
Admin C.11	Standard Score Norm: MRPSI
Admin C.12	Standard Score Norm: NVI 
Admin C.13	Standard Score Norm: NMI 
Admin C.14	Standard Score Norm: GAI 
Admin C.15	Standard Score Norm: CPI 
************************************************;
proc datasets kill nolist; 
options compress=yes nomprint nocenter ps=100;run;
dm 'log' clear; dm 'output' clear;

*%let pa=C:\Projects;
/*%let pa=K:\Clinical Psychometrics\ongoing projects;*/
*%let pa=K:\ongoing projects;

%let cipath=C:\projects\WAIS5\norms\composite;
/*%let xlspath=K:\Clinical Psychometrics\ongoing projects\WISC5\Stdz\tables\admin tables\temp;*/
libname sas4 "C:\projects\WAIS5\tables\SAS tables\norm\composite";
%include "C:\projects\WAIS5\sas code\macros\wais5 norm macro.sas";

%let group     = ss;
%LET day=%SYSFUNC(date(), date7.);

************************************************
import all composite norms via their [ci (true score)] tab
************************************************;
%macro getcomp (norm,rel,tn);
options nolabel;
PROC IMPORT OUT= &norm.
            DATAFILE= "&cipath.\&norm. norms.xlsx"
            DBMS=EXCEL REPLACE;
     SHEET="out$";      GETNAMES=YES;     MIXED=YES;     SCANTEXT=YES;     USEDATE=YES;     SCANTIME=YES;

RUN;
data &norm.; 
   retain sum &norm. pr ci90 ci95;
   set &norm.(rename=(wais5_&norm._sum=sum wais5_&norm._ss=&norm _0__CI=ci90 _5__CI=ci95 __tile=pr)); 
   where sum~=.; 
   drop f1-f50; 
   ** replace dashes with en-dashes in the CI range **;
   ci90=tranwrd(ci90,"-",byte(150));** en-dash **;
   ci95=tranwrd(ci95,"-",byte(150));** en-dash **;
run;
data &norm.2; set &norm.(drop=ci90 ci95); 
   ** check CI using True Scores and SEE **;
   ci90=compress(put(ROUND((100+&rel.*(&norm.-100))-(1.645*(15*&rel.*SQRT(1-&rel.))),1),3.)||byte(150)||put(ROUND((100+&rel.*(&norm.-100))+(1.645*(15*&rel.*SQRT(1-&rel.))),1),3.));
   ci95=compress(put(ROUND((100+&rel.*(&norm.-100))-(1.96 *(15*&rel.*SQRT(1-&rel.))),1),3.)||byte(150)||put(ROUND((100+&rel.*(&norm.-100))+(1.96 *(15*&rel.*SQRT(1-&rel.))),1),3.));
run;
proc compare base=&norm.  comp=&norm.2/* briefsummary*/; 
/*   id sum;*/
   title1 "********* PROC COMPARE: check CI calculation *********";
run;title;
options label;
data sas4.&tn._&norm.; set &norm.; run;
proc export data=sas4.&tn._&norm. outfile= "C:\projects\WAIS5\tables\excel\Admin_A3_8_C1_15_Composite_norms.xlsx" replace; 
   sheet="&norm.";
run;
%mend;

/*adjusted output format for these to have range in sum column*/
%macro getcomp_fmt2 (norm,rel);
options nolabel;
PROC IMPORT OUT= &norm.
            DATAFILE= "&cipath.\&norm. norms.xlsx"
            DBMS=EXCEL REPLACE;
     SHEET="out$";      GETNAMES=YES;     MIXED=YES;     SCANTEXT=YES;     USEDATE=YES;     SCANTIME=YES;
RUN;
data &norm.; 
   retain sum &norm. pr ci90 ci95;
   set &norm.(rename=(wais5_&norm._sum=sum wais5_&norm._ss=&norm _0__CI=ci90 _5__CI=ci95 __tile=pr)); 
   where sum~=.; 
   drop f1-f50; 
   ** replace dashes with en-dashes in the CI range **;
   ci90=tranwrd(ci90,"-",byte(150));** en-dash **;
   ci95=tranwrd(ci95,"-",byte(150));** en-dash **;
run;
** turn sum into ranges **;
proc sort data= &norm.; by &norm. sum;
data f&norm.; sum="          ";
   set &norm.(rename=(sum=osum)); by &norm.;
   retain low high;
      if first.&norm. then low=osum;
      if last.&norm. then high=osum;
   if low=high then sum=compress(put(low,3.));
   else sum=compress(put(low,3.)||byte(150)||put(high,3.));
   if last.&norm. then output;
   drop osum low high; 
run;
data &norm.2; set &norm.(drop=ci90 ci95); 
   ** check CI using True Scores and SEE **;
   ci90=compress(put(ROUND((100+&rel.*(&norm.-100))-(1.645*(15*&rel.*SQRT(1-&rel.))),1),3.)||byte(150)||put(ROUND((100+&rel.*(&norm.-100))+(1.645*(15*&rel.*SQRT(1-&rel.))),1),3.));
   ci95=compress(put(ROUND((100+&rel.*(&norm.-100))-(1.96 *(15*&rel.*SQRT(1-&rel.))),1),3.)||byte(150)||put(ROUND((100+&rel.*(&norm.-100))+(1.96 *(15*&rel.*SQRT(1-&rel.))),1),3.));
run;
proc compare base=&norm.  comp=&norm.2/* briefsummary*/; 
/*   id sum;*/
   title1 "********* PROC COMPARE: check CI calculation *********";
run;title;
options label;
data sas4.&norm.; set f&norm.; run;
proc export data=sas4.&norm. outfile= "C:\projects\WAIS5\tables\excel\Admin_A3_8_C1_15_Composite_norms.xlsx" replace; 
   sheet="&norm.";
run;
%mend;
*%getcomp (norm,rel);
** source for composite reliabilty:
K:\Clinical Psychometrics\ongoing projects\WISC5\Stdz\results\final
WISC5_stdz_comp_reliability.xlsx 05-13-2014 2:47pm 

also table 4.1 in tech should match, please check **;
%getcomp (norm=vci  ,rel=0.93, tn=admin_A3);
%getcomp (norm=vsi  ,rel=0.93, tn=admin_A4);
%getcomp (norm=fri  ,rel=0.94, tn=admin_A5);
%getcomp (norm=wmi  ,rel=0.93, tn=admin_A6);
%getcomp (norm=psi  ,rel=0.90, tn=admin_A7);
%getcomp (norm=fsiq ,rel=0.97, tn=admin_A8);
%getcomp (norm=veci ,rel=0.96, tn=admin_C1);
%getcomp (norm=vri  ,rel=0.95, tn=admin_C2);
%getcomp (norm=evsi ,rel=0.96, tn=admin_C3);
%getcomp (norm=efi  ,rel=0.97, tn=admin_C4);
%getcomp (norm=qri  ,rel=0.95, tn=admin_C5);
%getcomp (norm=ewmi ,rel=0.97, tn=admin_C6);
%getcomp (norm=vwmi ,rel=0.93, tn=admin_C7);
%getcomp (norm=awmir,rel=0.93, tn=admin_C8);
%getcomp (norm=awmim,rel=0.94, tn=admin_C9);
%getcomp (norm=epsi ,rel=0.91, tn=admin_C10);
%getcomp (norm=mrpsi,rel=0.85, tn=admin_C11);
%getcomp (norm=nvi  ,rel=0.97, tn=admin_C12);
%getcomp (norm=nmi  ,rel=0.97, tn=admin_C13);
%getcomp (norm=gai  ,rel=0.96, tn=admin_C14);
%getcomp (norm=cpi  ,rel=0.94, tn=admin_C15);

*NEW CODE WAS ADDED BY JJ on 30May2014 for reformatted versions of NSI STI and SRI -Ben;
/*
%getcomp_fmt2 (nsi  ,.90);*was .91*;
%getcomp_fmt2 (sti  ,.94);*was .83*;
%getcomp_fmt2 (sri  ,.94);
*/
title; ods html close;
*****************
    THE END
*****************;


