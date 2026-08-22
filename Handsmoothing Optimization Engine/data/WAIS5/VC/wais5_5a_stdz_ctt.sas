/***********************************************************************/
/**   Macro of Classical Test Theory (CTT) Analysis Package           **/
/**                              Version 7.0                          **/
/***********************************************************************/
/**    James Yang, J.J.Zhu 06-15-05,                                  **/
/**          Updated by James Yang 06-12-08                           **/
/**          Updated by Tianshu Pan    2009     (V5)                  **/
/**          Updated by Andrea Olson 09-06-2012 (V6)                  **/
/**          Updated by Andrea Olson 02-04-2015 (V7)                  **/
/***********************************************************************/
/** Keyword parameter description (global variables):                 **/
/**   sysuserid   : analsyt name in titles               (SAS default)**/
/**   SYSDATE9    : date of analysis                     (SAS default)**/
/***********************************************************************/
/** Keyword parameter description (macro variables):                  **/
/**   data      : input SAS data set                   (required)     **/
/**   pid       : pearson id (default-teid)                           **/
/**   subtest   : Name of subtest for analysis         (required)     **/
/**   item      : subtest score variable list          (required)     **/
/**   grp       : group variable for analysis          (required)     **/
/**   normflg   : variable for normal population ='Y' (default-stdz) (required)     **/
/**   project   : project name in titles and filenames (required)     **/
/**   clinflg   : variable for clinical population (default-clingrp) (optional) **/
/**   clinval   : values of clinflg variable           (optional)     **/
/**   rawmax    : maximum raw score for frequency table(required)     **/
/**   oddtype   : type of oddlist used for split half analysis        **/
/**             : ITEMNO(default)=oddlist is odd numbered items       **/ 
/**             : ITEMMEAN =oddlist based on mean item scores         **/
/**             : ITEMLIST =oddlist will be inputed via macro         **/
/**   oddlist   : input oddlist here for oddtype=ITEMLIST             **/
/**             : based on IRT b Values or content analysis           **/
/**   report    : D for detailed (default=D includes univariate output), or B for brief  **/
/***********************************************************************/
/** Output:                                                           **/
/**    1:C:\temp\CTT_on_&SYSDATE9..xls                                **/
/**        [CTT.&subtest]                                             **/
/**        [Freq.&subtest]                                            **/
/**        [Moments.&subtest]                                         **/
/**        [Alpha]                                                    **/
/**        [Split-Half]                                               **/
/**    2:C:\temp\Schematic_Plots_for_&project._&subtest._by_&grp._&SYSDATE9..html  **/
/**         or                                                        **/
/**      C:\temp\Univariate_&subtest._&project._&SYSDATE9..html       **/
/**    3:C:\temp\Checking_Item_Responses_for_&project._&subtest._&SYSDATE9..txt    **/
/***********************************************************************/
/** Output Datasets: _rel, _alpha, _split, _tab, _data_ctt, _nonclin  **/
/***********************************************************************/
/**  V6 enhancements: (V5 to V6)                                      **/
/**       -fix length of NAME variable during merge                   **/
/**       -add RS=0 to frequency output                               **/
/**       -reduce number of steps so log doesnt get full              **/
/**       -reduce size of dataset used for analysis to increase speed **/
/**       -apply clinical labels to agegroups on moments output       **/
/**       -positional parameters converted to keyword parameters      **/
/**           -make all inputs through these parameter, no %let       **/
/**       -added oddtype options:                                     **/
/**           -ITEMNO  :itemlist is odd numbered items (default)      **/
/**           -ITEMMEAN:itemlist based on mean item scores            **/
/**           -ITEMLIST:itemlist must be part of input                **/
/**       -oddlist from MN0 as option                                 **/
/**       -Clinical groups have labels in plots                       **/
/**       -Turn on/off saved outputs based on "outpath" variable      **/
/**       -Option for Brief/Detailed Univariate                       **/
/***********************************************************************/
/**  CTTpkg_V6_Oneitem:                                               **/
/**     -setup so it works like main CTT to allow for                 **/
/**         normselected vs clinical cases                            **/
/**     -Clinical groups have labels in results                       **/
/**     -Univariate will export moments and frequencies to excel      **/
/***********************************************************************/
/** V7 enhancements:                                                  **/
/**       -all datasets used within macro start with "_"              **/
/**       -made input macro variables consistent with allowed list    **/
/**       -added &sysuserid and &SYSDATE9 to all displays             **/
/**       -added &SYSDATE9 to all output file names                   **/
/**       -added Checking_Item_Responses output to CTTpkg_V7_Oneitem  **/
/**       -made all imput macro variables keyword parameters          **/
/***********************************************************************/
proc datasets kill; quit;
dm 'output' clear;
dm 'log' clear;
options compress=binary ps=90 ls=160 noMPRINT noMLOGIC;
ods graphics off;

%LET day=%SYSFUNC(date(), date7.);

/**********************************************************/
/*                   Specify data file                    */
/**********************************************************/
/*libname k 'K:\Clinical Psychometrics\ongoing projects\WAIS5\stdz\data';*/
libname c 'C:\projects\WAIS5\data\_100pct_2024'; 
proc freq data=c.Wais5_stdz_final; table clingrp; run;
data wais5 ; set c.Wais5_stdz_final
(keep=teid testname agey agegrp stdz sex edl eth region clingrp badsub

wais5_si_s01-wais5_si_s18 		wais5_si_raw 
/*wais5_sia_s01-wais5_sia_s16     wais5_sia_raw */
/*wais5_sib_s01-wais5_sib_s16 	wais5_sib_raw */

wais5_bdn_s01-wais5_bdn_s14    wais5_bdn_raw
wais5_bd_s01-wais5_bd_s14      wais5_bd_raw
wais5_bdp_s01-wais5_bdp_s14 	wais5_bdp_raw 

wais5_mr_s01-wais5_mr_s26 		wais5_mr_raw

wais5_sa_s01-wais5_sa_s23		wais5_sa_raw 	

wais5_df_s01_1 wais5_df_s01_2 wais5_df_s02_1 wais5_df_s02_2 wais5_df_s03_1 wais5_df_s03_2 
wais5_df_s04_1 wais5_df_s04_2 wais5_df_s05_1 wais5_df_s05_2 wais5_df_s06_1 wais5_df_s06_2 
wais5_df_s07_1 wais5_df_s07_2 wais5_df_s08_1 wais5_df_s08_2 wais5_df_s09_1 wais5_df_s09_2  
wais5_df_s10_1 wais5_df_s10_2 
wais5_df_s01-wais5_df_s10	wais5_df_raw  

wais5_dq_s01_1 wais5_dq_s01_2  wais5_dq_s02_1 wais5_dq_s02_2  wais5_dq_s03_1 wais5_dq_s03_2  
wais5_dq_s04_1 wais5_dq_s04_2  wais5_dq_s05_1 wais5_dq_s05_2  wais5_dq_s06_1 wais5_dq_s06_2  
wais5_dq_s07_1 wais5_dq_s07_2  wais5_dq_s08_1 wais5_dq_s08_2   wais5_dq_s09_1 wais5_dq_s09_2   
wais5_dq_s10_1 wais5_dq_s10_2
wais5_dq_s01-wais5_dq_s10 	wais5_dq_raw  

wais5_db_s01_1 wais5_db_s01_2  wais5_db_s02_1 wais5_db_s02_2  wais5_db_s03_1 wais5_db_s03_2  
wais5_db_s04_1 wais5_db_s04_2  wais5_db_s05_1 wais5_db_s05_2  wais5_db_s06_1 wais5_db_s06_2  
wais5_db_s07_1 wais5_db_s07_2  wais5_db_s08_1 wais5_db_s08_2   wais5_db_s09_1 wais5_db_s09_2   
wais5_db_s10_1 wais5_db_s10_2
wais5_db_s01-wais5_db_s10 	wais5_db_raw  

wais5_cd_raw wais5_cd_a wais5_cd_i wais5_cd_sk

wais5_vc_s01-wais5_vc_s24 		wais5_vc_raw 
/*wais5_vca_s01-wais5_vca_s24 		wais5_vca_raw */
/*wais5_vcb_s01-wais5_vcb_s24 		wais5_vcb_raw */

wais5_fw_s01-wais5_fw_s28	 	wais5_fw_raw 
/*wais5_fwa_s01-wais5_fwa_s28	 	wais5_fwa_raw */
/*wais5_fwc_s01-wais5_fwc_s28	 	wais5_fwc_raw */

wais5_vp_s01-wais5_vp_s25 		wais5_vp_raw

wais5_rd_s01-wais5_rd_s10 	wais5_rd_raw 

wais5_ss_cr wais5_ss_a wais5_ss_i wais5_ss_raw wais5_ssre_raw wais5_ssse_raw 

wais5_in_s01-wais5_in_s24 		wais5_in_raw 

wais5_arnb_s01-wais5_arnb_s22 	wais5_arnb_raw
wais5_ar_s01-wais5_ar_s22 	wais5_ar_raw   

wais5_ssp_s01-wais5_ssp_s23 	wais5_ssp_raw

wais5_nsq_t01-wais5_nsq_t02 wais5_nsq_raw wais5_nsqe_raw

/*wais5_sra_s01-wais5_sra_s27 		wais5_sra_raw*/
wais5_sr_s01-wais5_sr_s27 		wais5_sr_raw

wais5_co_s01-wais5_co_s18 		wais5_co_raw
/*wais5_coa_s01-wais5_coa_s18 		wais5_coa_raw*/
/*wais5_cob_s01-wais5_cob_s18 		wais5_cob_raw*/

wais5_ln_s01_1 wais5_ln_s01_2 wais5_ln_s02_1 wais5_ln_s02_2 wais5_ln_s03_1 wais5_ln_s03_2 
wais5_ln_s04_1 wais5_ln_s04_2 wais5_ln_s05_1 wais5_ln_s05_2 wais5_ln_s06_1 wais5_ln_s06_2 
wais5_ln_s07_1 wais5_ln_s07_2 wais5_ln_s08_1 wais5_ln_s08_2 wais5_ln_s09_1 wais5_ln_s09_2  
wais5_ln_s10_1 wais5_ln_s10_2
wais5_ln_s01-wais5_ln_s10 	wais5_ln_raw  

wais5_topf_s01-wais5_topf_s68 	wais5_topf_raw
); 
   if (stdz='Y' or clingrp~='') and agegrp~=.; 
   if clingrp in ('wms_MCI' 'wms_TBI') then delete;
/*   if tryout='Y'; */
    array xx wais5_nsq_t01-wais5_nsq_t02;
    do over xx; if xx = -9 then xx=.; end;

array dsp wais5_dsp_s01-wais5_dsp_s30;
array ds wais5_df_s01-wais5_df_s10 wais5_db_s01-wais5_db_s10 wais5_dq_s01-wais5_dq_s10;
do i=1 to dim(ds);
  dsp(i)=ds(i);
end;
run;

proc freq data=wais5; tables wais5_dsp_s01-wais5_dsp_s30;run;

/* Per RD - add the PPE GTs to the GT group */
data wais5; set wais5;
/*  if clingrp='GT_PPE' then clingrp='GT';*/
run;

proc freq data=wais5; table clingrp;run;

*** check clingrp, agegpr, flag and bias variables for expected values ***;
proc freq data = wais5; 
   tables agegrp /*grp */testname stdz sex edl eth /list missing; 
   where stdz='Y';
   title 'freq of agegrps';
run;title;
proc freq data = wais5; 
   tables clingrp/list missing; 
   title2 'for clingrp, keep only groups with enough cases (<15 drop)';
run;title;
/*proc means data=wais5; class grp; var agey; run;*/
proc means data=wais5; class agegrp; var agey; run;


/**********************************************************/
/*                  Project Macros                        */
/**********************************************************/
%include "C:\projects\WAIS5\sas code\macros\CTTPkg_html.sas";

/*per Susie 20jun2016: Could you please reoutput the verbatims and the checking item responses files with ones that 
have the education level, sex, ethnicity, and region of the examinee*/
%macro items_w_demos(subtest=,item=);
%let project=WAIS5_stdz;
%let grp=agegrp;
/**%let grp=grp;*/
%let pid=teid;
data temp; set wais5;
   Subtest_Total=0;
   array xx &item; do over xx; Subtest_Total=Subtest_Total+xx; end;
   score_string=cats(of &item);
run;
proc sort data=temp; by agegrp subtest_total score_string; run;
/*data _null_; set temp;*/
/*      file "C:\temp\Checking_Item_Responses_for_&project._&subtest._&SYSDATE9..txt";*/
/*      if _n_ =1 then put @1 "ID"  @9 "agey" @14 "sex" @18 "edl" @22 "eth" @26 "region" @33 "&subtest Total" @45 " &item";*/
/*      put @1 &pid @11 agey 2. @16 sex $1. @20 edl 1. @23 eth $2. @28 region $2. @34 subtest_total  @39(&item)(1.);*/
/*run;*/
data temp; 
retain &pid agegrp agey sex edl eth region clingrp subtest_total score_string &item badsub;
set temp; 
keep &pid agegrp agey sex edl eth region clingrp subtest_total score_string &item badsub;
run;
PROC EXPORT DATA= WORK.temp 
            OUTFILE= "C:\temp\Checking_Item_Responses_for_&project._&SYSDATE9..xlsx" 
            DBMS=XLSX REPLACE;
     SHEET="&subtest"; 
RUN;
%mend;

*%CTTpkg(data=, pid=teid, subtest=, item=, rawmax=, oddtype=itemno, oddlist=);
%macro doit(one,two,three);
%CTTpkg(
data=wais5                     /* the name of input SAS data file */, 
normflg=stdz,
pid=teid                       /* id variable used in Checking_Item_Responses output */, 
project=WAIS5_stdz           /* project name WAIS5_p1dig_non_clin*/,
clinflg=clingrp,
clinval=GT IDMI IDMO LDR LDM ADHD TBI ASD MCI ALZ,
subtest=&one                   /* title of subtest to appear in filenames and titles */, 
grp=agegrp                     /* variable of norm groups */,
report=D                       /* detailed results */,
item=&two                      /* the item name list input */,  
rawmax=&three                  /* the maximum raw total score possible */
/* oddtype=ITEMNO (default) so type of oddlist=items 1 3 5 7 9 etc */
);
%items_w_demos(subtest=&one    ,item=&two  );
%mend;  
 
/*run in order from Table 1 of the analysis requests*/
%doit(SI    ,wais5_si_s01-wais5_si_s18      ,36);
/*%doit(SI011 ,wais5_sia_s01-wais5_sia_s16    ,16);*/
/*%doit(SI001 ,wais5_sib_s01-wais5_sib_s16    ,16);*/

%doit(VC    ,wais5_vc_s01-wais5_vc_s24      ,45);
/*%doit(VC011 ,wais5_vca_s01-wais5_vca_s24    ,24);*/
/*%doit(VC001 ,wais5_vcb_s01-wais5_vcb_s24    ,24);*/

%doit(IN    ,wais5_in_s01-wais5_in_s24      ,24);

%doit(CO    ,wais5_co_s01-wais5_co_s18      ,36);
/*%doit(CO011 ,wais5_coa_s01-wais5_coa_s18    ,18);*/
/*%doit(CO001 ,wais5_cob_s01-wais5_cob_s18    ,18);*/


%doit(BDn ,wais5_bdn_s01-wais5_bdn_s14  ,48);	/*no bonus*/
%doit(BD  ,wais5_bd_s01-wais5_bd_s14  ,66);  /*with time bonus*/
%doit(BDp ,wais5_bdp_s01-wais5_bdp_s14    ,97);  /*partial and time bonus*/

%doit(VP    ,wais5_vp_s01-wais5_vp_s25      ,25);

%doit(MR    ,wais5_mr_s01-wais5_mr_s26      ,26);

/*%doit(FWa   ,wais5_fwa_s01-wais5_fwa_s28    ,28); */
%doit(FW   ,wais5_fw_s01-wais5_fw_s28    ,40);  /* FWb iteration #2*/
/*%doit(FWc   ,wais5_fwb_s01-wais5_fwb_s28    ,65);*/

/*%doit(ARnb  ,wais5_arnb_s01-wais5_arnb_s22  ,22);*/ /*no bonus*/
%doit(AR  ,wais5_ar_s01-wais5_ar_s22  ,25); /*with time bonus*/

/*%doit(SRa    ,wais5_sra_s01-wais5_sra_s27      ,27); */
%doit(SR    ,wais5_sr_s01-wais5_sr_s27      ,32);


%doit(DF_trial,wais5_df_s01_1 wais5_df_s01_2 wais5_df_s02_1 wais5_df_s02_2 wais5_df_s03_1 wais5_df_s03_2 
wais5_df_s04_1 wais5_df_s04_2 wais5_df_s05_1 wais5_df_s05_2 wais5_df_s06_1 wais5_df_s06_2 
wais5_df_s07_1 wais5_df_s07_2 wais5_df_s08_1 wais5_df_s08_2 wais5_df_s09_1 wais5_df_s09_2  
wais5_df_s10_1 wais5_df_s10_2                ,24);
%doit(DF_item,wais5_df_s01-wais5_df_s10  ,24);


%doit(DQ_trial,wais5_dq_s01_1 wais5_dq_s01_2  wais5_dq_s02_1 wais5_dq_s02_2  wais5_dq_s03_1 wais5_dq_s03_2  
wais5_dq_s04_1 wais5_dq_s04_2  wais5_dq_s05_1 wais5_dq_s05_2  wais5_dq_s06_1 wais5_dq_s06_2  
wais5_dq_s07_1 wais5_dq_s07_2  wais5_dq_s08_1 wais5_dq_s08_2   wais5_dq_s09_1 wais5_dq_s09_2   
wais5_dq_s10_1 wais5_dq_s10_2                ,24);
%doit(DQ_item,wais5_dq_s01-wais5_dq_s10  ,24);


%doit(DB_trial,wais5_db_s01_1 wais5_db_s01_2  wais5_db_s02_1 wais5_db_s02_2  wais5_db_s03_1 wais5_db_s03_2  
wais5_db_s04_1 wais5_db_s04_2  wais5_db_s05_1 wais5_db_s05_2  wais5_db_s06_1 wais5_db_s06_2  
wais5_db_s07_1 wais5_db_s07_2  wais5_db_s08_1 wais5_db_s08_2   wais5_db_s09_1 wais5_db_s09_2   
wais5_db_s10_1 wais5_db_s10_2                  ,24);
%doit(DB_item,wais5_db_s01-wais5_db_s10   ,24);

%doit(DSp,wais5_dsp_s01-wais5_dsp_s30   ,72);

%doit(RD   ,wais5_rd_s01-wais5_rd_s10   ,49);

%doit(LN_trial,wais5_ln_s01_1 wais5_ln_s01_2 wais5_ln_s02_1 wais5_ln_s02_2 wais5_ln_s03_1 wais5_ln_s03_2 
wais5_ln_s04_1 wais5_ln_s04_2 wais5_ln_s05_1 wais5_ln_s05_2 wais5_ln_s06_1 wais5_ln_s06_2 
wais5_ln_s07_1 wais5_ln_s07_2 wais5_ln_s08_1 wais5_ln_s08_2 wais5_ln_s09_1 wais5_ln_s09_2  
wais5_ln_s10_1 wais5_ln_s10_2 ,24);
%doit(LN_item,wais5_ln_s01-wais5_ln_s10  ,24);

%doit(SSP   ,wais5_ssp_s01-wais5_ssp_s23  ,44);

%doit(NSQ01 ,wais5_nsq_t01  ,76);
%doit(NSQ02 ,wais5_nsq_t02  ,76);
%doit(NSQ   ,wais5_nsq_raw  ,152);
%doit(NSQe  ,wais5_nsqe_raw ,40);


%doit(TOPF ,wais5_topf_s01-wais5_topf_s68  ,68);

/******************************************************************************************************************/
/*HERE! make sure there are no digital cases, as analysis should be separated by paper/digital for CD, SS, and SA */
/******************************************************************************************************************/

%doit(SA    ,wais5_sa_s01-wais5_sa_s23    ,23);
/*%doit(SAred ,wais5_sa_red_raw             ,15);*/


%doit(CD    ,wais5_cd_raw,135);
/*%doit(CDsk  ,wais5_CD_sk ,135); ** # skipped **;*/
/*%doit(CDi   ,wais5_CD_i  ,135); ** # incorrect **;*/
/*%doit(CDa   ,wais5_CD_a  ,135); ** # attempted **;*/
/*%doit(SSc   ,wais5_ss_cr   ,60); ** # correct **;*/
/*%doit(SSa   ,wais5_ss_a    ,60); ** # attempted **;*/
/*%doit(SSi   ,wais5_ss_i    ,60); ** # incorrect **;*/
%doit(SS    ,wais5_ss_raw  ,60);
%doit(SSre  ,wais5_ssre_raw,30);
%doit(SSse  ,wais5_ssse_raw,30);

/*For the digital format of CD and SS, and SA, need separate outputs for the digital format*/
/*will do this in separate code*/

title; footnote;
*******************************
end of code
*******************************;
