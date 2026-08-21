/***********************************************************************/
/**  wais5_stdz_3cleanup_totscore.sas                                 **/
/** Project Name        : WAIS-5 Stdz   (ckphaseid = 387)             **/
/** Brief Describtion   : 21 subtests                                 **/
/** Phase               : Standardization (digital + paper)           **/
/** Purpose of this code: print cases with missing/0 total score      **/
/** Data file used      :(K:\Clinical Psychometrics\ongoing projects\WAIS5\stdz\data\wais5_to_final)    **/
/** Written by          : Andrea Olson                                **/               
/** Department          : Psychometrics                               **/               
/** Company             : Pearson                                     **/
/** Date                : 10apr2018 for Tryout                        **/
/** Date                : 21may2019 for STDZ                          **/

/*  WL 25Apr2023: add export for Additional Data check - per Cliff's request on 4/21/2023:                                     */
/* adding an additional data check of whether the sum of the completion times for items in a subtest 
   are significantly greater than the total administration time for that subtest                    */
/* The affected subtests would be:                                                                  */
/*   Block Design                                                                                   */
/*   Set Relations                                                                                  */
/*   Figure Weights                                                                                 */
/*   Visual Puzzles                                                                                 */
/*   Arithmetic                                                                                     */

/***********************************************************************/

dm 'log' clear;
proc datasets kill;quit;
OPTIONS CENTER COMPRESS=YES nodate nonumber mprint /*mlogic */pagesize=32767/* source2 linesize=132 pagesize=32767*/;

libname c 'C:\projects\WAIS5\data'; /*change the path to your local drive*/
libname temp "\\ICDWPCOREFIL27\Tpccomn\ClinicalSampling\SASdatasets\WAIS5Stdz\cleanup\result";
libname h '\\ICDWPCOREFIL27\Tpccomn\ClinicalSampling\SASdatasets\WAIS5Stdz'; /*data directory*/

%let day = %sysfunc(date(),date7.);
%let daytime=%sysfunc(date(),date7.) %sysfunc(time(),hhmm);
%let path = \\ICDWPCOREFIL27\Tpccomn\ClinicalSampling\SASdatasets\WAIS5Stdz\cleanup\result; /*report dirctory*/
/*%let path = C:\Projects\wais5\tryout\data; */

options ls=100 ps=500 nonumber nodate;


**************************************************************
         macros here
**************************************************************;
%macro numobs(dsn,var);
    %global &var;
    %let dsid = %sysfunc(open(&dsn));
    %let &var = %sysfunc(attrn(&dsid,nobs));
    %let rc   = %sysfunc(close(&dsid));
%mend numobs;

%macro stringcheck2 (dd,form,sub,var,range,test);
  data t1; set &dd; keep teid id agegrp &var &sub.all stname; run;
  proc transpose data=t1 out=t2; by teid id agegrp &var stname; var &sub.all;
  data t2; set t2; keep teid id agegrp &var stname _name_ col1;
  data t2; set t2; out_range=0;
    if &var notin (&range) /*and stname in (&form)*/ then out_range+1;
/*    if &var notin (.) and stname notin (&form) then out_range+1;run;*/
  data t3; set t2; if out_range ne 0;
    format subtest $50.; format value $70.;
    subtest="&test"; value=col1;
  data t3; set t3; value = compress(value);
  data t3; set t3; drop col1 out_range;
      raw=&var;
  data outrange; set outrange t3;run;
%mend stringcheck2;

%macro time_check (dd,sub,var,test);
  data t1; set &dd; keep teid id agegrp &var &test; run;
  proc transpose data=t1 out=t2; by teid id agegrp &var; var &test;
  data t2; set t2; keep teid id agegrp &var _name_ col1;
  data t2; set t2; out_range=0;
    if &var >=2 then out_range+1;
  data t3; set t2; if out_range ne 0;
	format subtest $50.;
	format value $5.;
	subtest=col1;
    value=compress(&var);
  data t3; set t3;
	  drop &var col1 out_range;
  data outrange; set outrange t3;run;
%mend time_check;


**************************************************************
         Check for Out-of-Range Values
**************************************************************;
data xx; set c.wais5_stdz_final_&day; 
    where phasename='Standardization';
/*   where clingrp='';  */
/*   where clingrp~=''; */
run;
data outrange; teid=10000; eeid=200000; 
format _name_ $30.; 
format value  $70.; 
format subtest $50.; 
value='123456789012345678901234567890123456789012345678901234567890';
subtest='string to help id item data';
run;

data tt; set xx; 
   id=catt('teid=',teid,' age=',agey,' clin=',clingrp);
   if clingrp='' then id=catt('teid=',teid,' age=',agey);

   siall = cats(of wais5_si_s01-wais5_si_s25);
   bdnball= cats(of wais5_bdnb_s01-wais5_bdnb_s14);
   bdaall = cats(of wais5_bda_s01-wais5_bda_s14);
   bdball = cats(of wais5_bdb_s01-wais5_bdb_s14);
   bdcall = cats(of wais5_bdc_s01-wais5_bdc_s14);
   mrall = cats(of wais5_mr_s01-wais5_mr_s33);
   saall = cats(of wais5_sa_s01-wais5_sa_s28);
   dsfall= cats(of wais5_dsf_s01-wais5_dsf_s10);
   dssall= cats(of wais5_dss_s01-wais5_dss_s10);
   dsball= cats(of wais5_dsb_s01-wais5_dsb_s10);
   cdall = cats(wais5_cd_a,"-(",wais5_cd_i,"+",wais5_cd_sk,") ct=",wais5_cd_ct);
   vcall = cats(of wais5_vc_s01-wais5_vc_s33);
   fwall = cats(of wais5_fw_s01-wais5_fw_s37);
   vpall = cats(of wais5_vp_s01-wais5_vp_s29);
   rdsall= cats(of wais5_rds_s01-wais5_rds_s10);
   ssall = cats(of wais5_ss_s01-wais5_ss_s60);
   ssall= cats(wais5_ss_raw,"=",wais5_ss_cr,"-",wais5_ss_i,"ct=",wais5_ss_ct);
   inall = cats(of wais5_in_s01-wais5_in_s28);
   arall = cats(of wais5_ar_s01-wais5_ar_s26);
   sspall= cats(of wais5_ssp_s01-wais5_ssp_s26);
   nsqall = cats(wais5_nsq_t01,"+",wais5_nsq_t02);
   srall = cats(of wais5_sr_s01-wais5_sr_s26);
   coall = cats(of wais5_co_s01-wais5_co_s18);
   lnsall= cats(of wais5_lns_s01-wais5_lns_s10);
   topfall = cats(of wais5_topf_s01-wais5_topf_s68);

   bd_time_check=catt('bd_complition_time=',bd_complition_time,' vs',' wais5_bd_time=',wais5_bd_time);
   sr_time_check=catt('sr_complition_time=',sr_complition_time,' vs',' wais5_sr_time=',wais5_sr_time);
   fw_time_check=catt('fw_complition_time=',fw_complition_time,' vs',' wais5_fw_time=',wais5_fw_time);
   vp_time_check=catt('vp_complition_time=',vp_complition_time,' vs',' wais5_vp_time=',wais5_vp_time);
   ar_time_check=catt('ar_complition_time=',ar_complition_time,' vs',' wais5_ar_time=',wais5_ar_time);
run;

proc sort data=tt; by teid; run;
data temp; set tt; run;** all ages **;
data tempc; set tt; if CSS_extrct_status='Completed'; run;** all ages, CSS complete (SI VC IN CO) **;
/*        if testid=4149 and testname='WAIS 5 Tryout - Digital'          then do; stname='WAIS5_D';    data_type='digital'; end;*/
/*   else if testid=4171 and testname='WAIS 5 Tryout - Paper'            then do; stname='WAIS5_P';    data_type='paper'; end;*/
/*   else if testid=4193 and testname='WAIS 5 Tryout Oversample - Paper' then do; stname='WAIS5_OS_P'; data_type='paper'; end;*/
/*   else if testid=4171 and testname='WAIS 5'                           then do; stname='WAIS5_P';    data_type='paper'; end;*/
/*   else if testid=4933 and testname='WAIS 5 Research Edition  (Q-interactive)' then do; stname='WAIS5_D';    data_type='digital'; end;*/
/*   else if testid=4955 and testname='Retest WAIS 5 Research Edition'   then do; stname='R_WAIS5_P';  data_type='paper'; end;*/
/*   else if testid=5023 and testname='WAIS 5 Research Edition'          then do; stname='WAIS5_P';    data_type='paper'; end;*/
/*   else if testid=5045 and testname='Retest WAIS 5 Research Edition'   then do; stname='R_WAIS5_D'; */
 %stringcheck2(tempc,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , si  ,wais5_si_raw  , 1:50 , si calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , bdnb,wais5_bdnb_raw, 1:48 , bdnb calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , mr  ,wais5_mr_raw  , 1:33 , mr calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , sa  ,wais5_sa_raw  , 1:28 , sa calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , dsf ,wais5_dsf_raw , 1:20 , dsf calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , dss ,wais5_dss_raw , 1:20 , dss calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , dsb ,wais5_dsb_raw , 1:20 , dsb calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , cd  ,wais5_cd_raw  , 1:135, cd calculated RAW score + score string);
 %stringcheck2(tempc,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , vc  ,wais5_vc_raw  , 1:63 , vc calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , fw  ,wais5_fw_raw  , 1:37 , fw calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , vp  ,wais5_vp_raw  , 1:29 , vp calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , rds ,wais5_rds_raw , 1:49 , rds calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , ss  ,wais5_ss_raw  , 1:60 , ss calculated RAW score + score string);
 %stringcheck2(tempc,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , in  ,wais5_in_raw  , 1:28 , in calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , ar  ,wais5_ar_raw  , 1:26 , ar calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , ssp ,wais5_ssp_raw , 1:50 , ssp calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , nsq ,wais5_nsq_raw , 1:150, nsq calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , sr  ,wais5_sr_raw  , 1:26 , sr calculated RAW score + score string);
 %stringcheck2(tempc,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , co  ,wais5_co_raw  , 1:36 , co calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , lns ,wais5_lns_raw , 1:20 , lns calculated RAW score + score string);
 %stringcheck2(temp ,'WAIS5_D' 'WAIS5_P' 'R_WAIS5_D' 'R_WAIS5_P' , topf,wais5_topf_raw, 1:68 , topf calculated RAW score + score string);

 %time_check(temp,bd,bd_time_dif, bd_time_check);
 %time_check(temp,sr,sr_time_dif, sr_time_check);
 %time_check(temp,fw,fw_time_dif, fw_time_check);
 %time_check(temp,vp,vp_time_dif, vp_time_check);
 %time_check(temp,ar,ar_time_dif, ar_time_check);

options ls=120 ps=200 nocenter nonumber;
proc sort data=outrange; by teid;run;
proc sort data=xx; by teid; run; 

/*get cleanup date*/
proc sort data=temp.Wais5stdz out=cdate; by teid; run;
data cdate; set cdate; by teid;
    sc=catx(' ',source, checkdate);
    retain date_list; 
    length date_list $50;
    if first.teid then date_list=sc; 
    else date_list=catx(', ',date_list,sc); 
    if last.teid; 
run;

data outrang;  merge    outrange(in=a) xx (in=b keep=teid /*teid_rb*/ assessmentid badsub) cdate(keep=teid date_list);
by teid;
if a;
if teid=10000 then badsub='perKathleen';
label = cat(subtest);
run;

proc sql;
   create table work.xltemp as
      select
         id,teid/*_rb*/,assessmentid,_name_,badsub,raw,value,label,date_list
      from outrang;
quit;

*%numobs(outrang,tout);
/*numobs(dsn,var);*/
    %global tout;
    %let dsid = %sysfunc(open(outrang));
    %let tout = %sysfunc(attrn(&dsid,nobs));
    %let rc   = %sysfunc(close(&dsid));
%macro getcount;
%if &tout > 0 %then %do;
data _null_; 
   true_N=&tout - 1;
   call symput('tout', left(trim(put(true_N,4.))));run;
%end;
%put tout=&tout;
%mend getcount;
%getcount;

%macro drop_unusable;
 data unusable; set h.Wais5stdz_demo(keep=teid unusable_subs);
  if unusable_subs~=" ";
  sub_1=lowcase(scan(unusable_subs,1,","));
  sub_2=lowcase(scan(unusable_subs,2, ","));
 run;

 data sub_1; set unusable(keep=teid sub_1);
  rename sub_1=unusable_subs;
 run;
 data sub_2; set unusable(keep=teid sub_2);
  where sub_2~=" ";
  rename sub_2=unusable_subs;
 run;

data unusable; set sub_1 sub_2;
  if unusable_subs not in ('si' 'bd' 'mr' 'sa' 'dsf' 'dss' 'dsb' 'cd' 'vc' 'fw' 'vp' 'rds' 'ss' 'in' 'ar' 'nsq' 'sr' 'co' 'lns' 'topf2') then delete;
  if unusable_subs='topf2' then unusable_subs='topf';
run;

proc sql;
  select teid into: tid separated by "|" from Unusable;
  select unusable_subs into: sub separated by "|" from Unusable;
  select count (teid) into: num from Unusable;
quit;

data xltemp; set xltemp; 
  %do i=1 %to &num;
    %let td=%scan(&tid,&i,"|");
    %let sb=%scan(&sub,&i,"|");

	if teid=&td & find(_name_,"&sb")>0 then delete;
  %end;
run;
%mend;

%drop_unusable;

data xltemp zero time; set xltemp;
   if raw=0 or teid=10000 then output zero;
   if teid=10000 or scan(_name_,3,'_')="check" then output time;
   if raw=. & scan(_name_,3,'_')~="check" then output xltemp;
run;
/*data _null_; set outrang;   by teid;*/
/*file "&path/wais5_p1dig_TotalScore(%sysfunc(date(),date7.) &tout Cases).txt";*/
/*if _n_=1 then */
/* put "The Following TEIDs have Total Score Missing "/"(%sysfunc(date(),date7.))"//*/
/*    "ID Info"    @21 "Variable"   @31 "Score" @38"Score String" @99 "Note";*/
/*    put  id    @21 _name_    @31 raw @38 value   @99 label ;*/
/*if last.teid then put " ";*/
/*run;*/
   proc export data=xltemp(drop=teid)
      outfile="&path\Wais5_stdz_cleanup_(%sysfunc(date(),date7.)).xlsx" 
      dbms=xlsx replace; 
      sheet="MissTotScr"; 
   run;

   proc export data=zero(drop=teid)
      outfile="&path\Wais5_stdz_cleanup_(%sysfunc(date(),date7.)).xlsx" 
      dbms=xlsx replace; 
      sheet="Zero"; 
   run;

   proc export data=time(drop=teid raw)
      outfile="&path\Wais5_stdz_cleanup_(%sysfunc(date(),date7.)).xlsx" 
      dbms=xlsx replace; 
      sheet="TimeCheck"; 
   run;
/*get missing scores that correspond to the raw total score*/
/*data miss; set tt; */
/*    array cc(*) wais5_si_c01-wais5_si_c25*/
/*wais5_mr_r01-wais5_mr_r33*/
/*wais5_sa_r01-wais5_sa_r06 wais5_sa_r07-wais5_sa_r28*/
/*wais5_vc_c01-wais5_vc_c33*/
/*wais5_fw_r01-wais5_fw_r37*/
/*wais5_vp_r01-wais5_vp_r29*/
/*wais5_rds_r01-wais5_rds_r10*/
/*wais5_in_c01-wais5_in_c28*/
/*wais5_ssp_r01-wais5_ssp_r26*/
/*;*/
/*    array nn(*) wais5_bd_os01_1-wais5_bd_os01_2 wais5_bd_os02_1-wais5_bd_os02_2 wais5_bd_os03_1-wais5_bd_os03_2 wais5_bd_os04_1-wais5_bd_os04_2*/
/*wais5_bd_os01-wais5_bd_os04*/
/*wais5_bd_os05-wais5_bd_os14*/
/*wais5_DSF_os01_1 wais5_DSF_os01_2 wais5_DSF_os06_1 wais5_DSF_os06_2 */
/*wais5_DSF_os02_1 wais5_DSF_os02_2 wais5_DSF_os07_1 wais5_DSF_os07_2 */
/*wais5_DSF_os03_1 wais5_DSF_os03_2 wais5_DSF_os08_1 wais5_DSF_os08_2 */
/*wais5_DSF_os04_1 wais5_DSF_os04_2 wais5_DSF_os09_1 wais5_DSF_os09_2 */
/*wais5_DSF_os05_1 wais5_DSF_os05_2 wais5_DSF_os10_1 wais5_DSF_os10_2*/
/*wais5_dss_os01_1 wais5_dss_os01_2  */
/*wais5_dss_os02_1 wais5_dss_os02_2 */
/*wais5_dss_os03_1 wais5_dss_os03_2 */
/*wais5_dss_os04_1 wais5_dss_os04_2 */
/*wais5_dss_os05_1 wais5_dss_os05_2 */
/*wais5_dss_os06_1 wais5_dss_os06_2 */
/*wais5_dss_os07_1 wais5_dss_os07_2 */
/*wais5_dss_os08_1 wais5_dss_os08_2 */
/*wais5_dss_os09_1 wais5_dss_os09_2 */
/*wais5_dss_os10_1 wais5_dss_os10_2*/
/*wais5_dsb_os01_1 wais5_dsb_os01_2  */
/*wais5_dsb_os02_1 wais5_dsb_os02_2 */
/*wais5_dsb_os03_1 wais5_dsb_os03_2 */
/*wais5_dsb_os04_1 wais5_dsb_os04_2 */
/*wais5_dsb_os05_1 wais5_dsb_os05_2 */
/*wais5_dsb_os06_1 wais5_dsb_os06_2 */
/*wais5_dsb_os07_1 wais5_dsb_os07_2 */
/*wais5_dsb_os08_1 wais5_dsb_os08_2 */
/*wais5_dsb_os09_1 wais5_dsb_os09_2 */
/*wais5_dsb_os10_1 wais5_dsb_os10_2*/
/*wais5_cd_i wais5_cd_sk wais5_cd_a*/
/*wais5_ss_cr wais5_ss_i wais5_ss_a*/
/*wais5_ar_os01-wais5_ar_os26*/
/*wais5_nsq_t01-wais5_nsq_t02*/
/*wais5_sr_r01-wais5_sr_r26*/
/*wais5_co_cs01-wais5_co_cs18*/
/*wais5_lns_os01_1 wais5_lns_os02_1 wais5_lns_os03_1 wais5_lns_os04_1 wais5_lns_os05_1 */
/*wais5_lns_os06_1 wais5_lns_os07_1 wais5_lns_os08_1 wais5_lns_os09_1 wais5_lns_os10_1 */
/*wais5_lns_os01_2 wais5_lns_os02_2 wais5_lns_os03_2 wais5_lns_os04_2 wais5_lns_os05_2 */
/*wais5_lns_os06_2 wais5_lns_os07_2 wais5_lns_os08_2 wais5_lns_os09_2 wais5_lns_os10_2*/
/*wais5_topf_os01-wais5_topf_os68*/
/*;*/
/**/
/*    do i=1 to dim(cc);*/
/*        if cc{i} in ('-9' '') then do;*/
/*        variable=vname(cc{i});*/
/*        output;*/
/*    end;*/
/*    do i=1 to dim(nn);*/
/*        if nn{i} in (-9 .) then do;*/
/*        variable=vname(nn{i});*/
/*        output;*/
/*    end;*/
/*    keep teid agey clingrp assessmentid badsub variable ;*/
/*run;*/
/*   proc export data=miss*/
/*      outfile="&path\Wais5_to_cleanup_(%sysfunc(date(),date7.)).xlsx" */
/*      dbms=xlsx replace; */
/*      sheet="Missing"; */
/*   run;*/



title; footnote; 

/****************************************************************************************************/
/* add Additional Data Cleanup check - per Cliff's request in email 4/21/2023                       */
/* adding an additional data check of whether the sum of the completion times for items in a subtest 
   are significantly greater than the total administration time for that subtest                    */
/* The affected subtests would be:                                                                  */
/*   Block Design                                                                                   */
/*   Set Relations                                                                                  */
/*   Figure Weights                                                                                 */
/*   Visual Puzzles                                                                                 */
/*   Arithmetic                                                                                     */
/****************************************************************************************************/


*******************************
end of code
*******************************;
