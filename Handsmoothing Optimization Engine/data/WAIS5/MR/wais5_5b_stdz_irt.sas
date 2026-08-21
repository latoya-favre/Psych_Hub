/*******************************************************************/
/*                    Macro Running WINSTEPS                       */
/*******************************************************************/
/*                Code Started: Tianshu Pan 2012                   */
/*******************************************************************/
/*This macro runs WINSTEPS with SAS to do Rasch item analysis      */
/*******************************************************************/
/*Parameter Explanation:                                           */
/* DATA=, Required, name of dataset used                           */ 
/*  PID=, Optional, Person/Examinee ID, default using case sequence*/
/* ITEM=, Required, Variable List of Item Scores                   */
/*  MAP=, Optional, To request item map, default MAP=NO            */
/*  OUT=, Required, name of output files                           */
/*        and SAS data file name for item parameter                */
/*OUTPATH=, Required, Specify the output folder path               */
/*******************************************************************/
/*To succefully use the macro, you should make sure:               */
/*******************************************************************/
/*1. item scores should be one-digit numeric variables             */
/*2. invalid item scores should be set as missing values           */
/*3. WINSTEPS version may show output in different formats         */
/*   check txt-type output files directly if results seem wrong    */
/*******************************************************************/
/* Output files in the output folder after running:                */
/* xxx.ctrl: WINSTEPS control file                                 */
/* xxx.out:  WINSTEPS output  file (when item map is not requested)*/
/* xxx_map.txt: item map file(when item map is requested)          */
/* xxx_I.txt: item output file                                     */
/* xxx_P.txt: Person output file                                   */
/* xxx_S.txt: item score category output file(polytomous scores)   */
/* xxx_SC.txt: raw score to ability conversion table file          */
/* IF more output tables are needed, run comment-out TABLES code   */
/*******************************************************************/


%macro winsteps(data=, pid=_N_, item=, map=yes, out=, outpath=C:\temp);
data _name;
  set &data;
  if _N_=1;
  keep &item;
proc transpose data=_name out=_name;
  var &item;
data _&data;
 set &data;
 _id= &pid;
 keep _id &item;
proc sort; by _id;
proc transpose data=_&data out=__&data;
 var &item;
 by _id;
proc freq data=__&data noprint;
  tables col1 /out=_code(where=(not missing(col1)));
run;

proc sql noprint;
  select col1 into :code separated by '' from _code;
  select _NAME_ into: name separated by '" / "' from _name;
  select _NAME_ into: item separated by ' ' from _name;
  select count(*), max(length(_NAME_)) into :NI,
         :inw from _name;
quit;

data _null_; 
  file "&outpath\&out..ctrl" lrecl=5000;
  If _N_=1 then      
  put '&INST'/
     "TITLE=test"/
     "NI=&NI"/
     "NAME1=%eval(&NI+1)"/
/*     "NAMELEN="/*/
     "ITEM1=1"/
     'XWIDE=1'/
     "CODES=&code"/
%if %upcase(&map)=YES | %upcase(&map)=Y %then 
     'tfile=*'/
     '1.12'/
     '*'/;
/*   "STKEEP=NO"/*/
   'TABLES=1111111111111111111111'/
/*   "CUTLO =0"/ */
     "IFILE =&outpath\&out._I.txt"/
     "PFILE =&outpath\&out._P.txt"/
     "SCFILE =&outpath\&out._SC.txt"/
%if %substr(&code, %length(&code))>1 %then 
     "SFILE=&outpath\&out._S.txt"/;
     'GROUPS=0'/
     'UDECIM=4'/
     'PERSON=Person'/
     "ITEM=Item"/
     'USCALE=1'/
     'MODELS=R'/
   /*'UPMEAN=0'/*/
     '&END'/
     "&name " /
     "END NAMES"; 
  set _&data;
  put (&item) (1.0) @%eval(&NI+1) _ID; 
RUN;
options noxwait; 
  x 'cd C:\WINSTEPS\'; * Winsteps install folder;
  x "winsteps '&outpath\&out..ctrl' &out..out";
 
%if %upcase(&map)=YES | %upcase(&map)=Y %then 
  x "ren &outpath\&out..out &out._map.txt";;
run;
data &out; 
  infile "&outpath\&out._i.txt" firstobs = 3;
  length item $ &inw;
  input @147 item $ @7 b 9.6 @36 error @19 N 8.1 @29 ItemScore @43 IN_MSQ 6.2 @50 IN_zstd 6.2 
  	@57 OUT_MSQ 6.2 @ 64 OUT_zstd 6.2 @70 Displ 9.6 @79 Pb 6.2 @104 Discr @123 PValue;
  label in_msq = 'Infit MSQ' in_zstd = 'Infit Z-STD' out_msq = 'Outfit MSQ'
  out_zstd = 'Outfit Z-STD' Pb='Pb Item-Theta' Error='Std. Error'
  PValue='P-Value' displ=displacement  discr=discrimination;
proc print label;
 title2 "Rasch Item Analysis";
 title3 "Analyzed by &sysuserid";
data _null_;
 put "QA Checklist:";
 put ;
 put '  The sample is used for the analysis correctly?';
 put "   Valid Scores: &code";
 put "   Number of Items:&NI";
 put "   Item List: &item";
 put "&name";
 put "The code uses WINSTEPS 3.72.2";
 put "Different version may show output in different columns";
 put "If SAS does not show output correctly,";
 put "please check &out._I.txt file in output folder";
proc datasets nolist;
  delete _&data __&data _name _code;
run; quit;
title2; footnote;
%mend;

/*libname k 'K:\Clinical Psychometrics\ongoing projects\WAIS5\stdz\data';*/
libname c 'K:\ongoing projects\WAIS5\stdz\data\_100pct_2024';
%LET day=%SYSFUNC(date(), date7.);
proc datasets kill; run; quit;
proc freq data=c.wais5_stdz_scored_final_2024; table stdz/list missing; run;

data wais;
 set c.wais5_stdz_scored_final_2024
(keep=teid agey agegrp stdz sex edl eth region clingrp badsub
wais5_si_s01-wais5_si_s18 		wais5_si_raw 
/*wais5_sia_s01-wais5_sia_s16     wais5_sia_raw */
/*wais5_sib_s01-wais5_sib_s16 	wais5_sib_raw */

wais5_bdn_s01-wais5_bdn_s12    wais5_bdn_raw
wais5_bd_s01-wais5_bd_s12      wais5_bd_raw
wais5_bdp_s01-wais5_bdp_s12 	wais5_bdp_raw 

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

wais5_sys_s01-wais5_sys_s23 	wais5_sys_raw

wais5_nsq_t01-wais5_nsq_t02 wais5_nsq_raw wais5_nsqe_raw

/*wais5_sra_s01-wais5_sra_s27 		wais5_sra_raw*/
wais5_sr_s01-wais5_sr_s27 		wais5_sr_raw

wais5_co_s01-wais5_co_s18		wais5_co_raw
/*wais5_coa_s01-wais5_coa_s18 		wais5_coa_raw*/
/*wais5_cob_s01-wais5_cob_s18 		wais5_cob_raw*/

wais5_ln_s01_1 wais5_ln_s01_2 wais5_ln_s02_1 wais5_ln_s02_2 wais5_ln_s03_1 wais5_ln_s03_2 
wais5_ln_s04_1 wais5_ln_s04_2 wais5_ln_s05_1 wais5_ln_s05_2 wais5_ln_s06_1 wais5_ln_s06_2 
wais5_ln_s07_1 wais5_ln_s07_2 wais5_ln_s08_1 wais5_ln_s08_2 wais5_ln_s09_1 wais5_ln_s09_2  
wais5_ln_s10_1 wais5_ln_s10_2
wais5_ln_s01-wais5_ln_s10 	wais5_ln_raw  

wais5_topf_s01-wais5_topf_s68 	wais5_topf_raw);

 rename 
wais5_si_s01-wais5_si_s18    	 =si01-si18  
/*wais5_sia_s01-wais5_sia_s16    	=sia01-sia16  */
/*wais5_sib_s01-wais5_sib_s16    	=sib01-sib16  */

wais5_bdn_s01-wais5_bdn_s12	    =bdn01-bdn12
wais5_bd_s01-wais5_bd_s12  	    =bd01-bd12   /* with time bonus */
wais5_bdp_s01-wais5_bdp_s12  	=bdp01-bdp12 
wais5_mr_s01-wais5_mr_s26    	=mr01-mr26
wais5_sa_s01-wais5_sa_s23    	=sa01-sa23 

wais5_df_s01_1=dft01 	wais5_df_s01_2=dft02 	wais5_df_s02_1=dft03 	wais5_df_s02_2=dft04 
wais5_df_s03_1=dft05 	wais5_df_s03_2=dft06 	wais5_df_s04_1=dft07 	wais5_df_s04_2=dft08 
wais5_df_s05_1=dft09 	wais5_df_s05_2=dft10 	wais5_df_s06_1=dft11 	wais5_df_s06_2=dft12 
wais5_df_s07_1=dft13 	wais5_df_s07_2=dft14 	wais5_df_s08_1=dft15 	wais5_df_s08_2=dft16 
wais5_df_s09_1=dft17 	wais5_df_s09_2=dft18 	wais5_df_s10_1=dft19 	wais5_df_s10_2=dft20 
wais5_df_s01-wais5_df_s10=dsfi01-dsfi10 

wais5_dq_s01_1=dqt01 wais5_dq_s01_2=dqt02 wais5_dq_s02_1=dqt03 wais5_dq_s02_2=dqt04 
wais5_dq_s03_1=dqt05 wais5_dq_s03_2=dqt06 wais5_dq_s04_1=dqt07 wais5_dq_s04_2=dqt08 
wais5_dq_s05_1=dqt09 wais5_dq_s05_2=dqt10 wais5_dq_s06_1=dqt11 wais5_dq_s06_2=dqt12 
wais5_dq_s07_1=dqt13 wais5_dq_s07_2=dqt14 wais5_dq_s08_1=dqt15 wais5_dq_s08_2=dqt16 
wais5_dq_s09_1=dqt17 wais5_dq_s09_2=dqt18 wais5_dq_s10_1=dqt19 wais5_dq_s10_2=dqt20 
wais5_dq_s01-wais5_dq_s10=dqi01-dqi10 

wais5_db_s01_1=dbt01 wais5_db_s01_2=dbt02 wais5_db_s02_1=dbt03 wais5_db_s02_2=dbt04 
wais5_db_s03_1=dbt05 wais5_db_s03_2=dbt06 wais5_db_s04_1=dbt07 wais5_db_s04_2=dbt08 
wais5_db_s05_1=dbt09 wais5_db_s05_2=dbt10 wais5_db_s06_1=dbt11 wais5_db_s06_2=dbt12 
wais5_db_s07_1=dbt13 wais5_db_s07_2=dbt14 wais5_db_s08_1=dbt15 wais5_db_s08_2=dbt16 
wais5_db_s09_1=dbt17 wais5_db_s09_2=dbt18 wais5_db_s10_1=dbt19 wais5_db_s10_2=dbt20 
wais5_db_s01-wais5_db_s10  =dbi01-dbi10 

wais5_vc_s01-wais5_vc_s24    	=vc01-vc24
/*wais5_vca_s01-wais5_vca_s24    	=vca01-vca24*/
/*wais5_vcb_s01-wais5_vcb_s24    	=vcb01-vcb24*/

/*wais5_fwa_s01-wais5_fwa_s28    	=fwa01-fwa28  */
wais5_fw_s01-wais5_fw_s28    	=fw01-fw28 
/*wais5_fwc_s01-wais5_fwc_s28    	=fwc01-fwc28 */

wais5_vp_s01-wais5_vp_s25    	=vp01-vp25   

wais5_rd_s01-wais5_rd_s10  	    =rd01-rd10 
/*wais5_rds_pf01-wais5_rds_pf10	=rdspf01-rdspf10 */

wais5_in_s01-wais5_in_s24    	=in01-in24 
 
wais5_arnb_s01-wais5_arnb_s22  	=arnb01-arnb22 
wais5_ar_s01-wais5_ar_s22  	    =ar01-ar22   /* with time bonus */

wais5_sys_s01-wais5_sys_s23  	=sys01-sys23

/*wais5_sra_s01-wais5_sra_s27    	=sra01-sra27*/
wais5_sr_s01-wais5_sr_s27    	=sr01-sr27
 
wais5_co_s01-wais5_co_s18    	=co01-co18
/*wais5_coa_s01-wais5_coa_s18    	=coa01-coa18*/
/*wais5_cob_s01-wais5_cob_s18    	=cob01-cob18*/

wais5_ln_s01_1=lnt01 wais5_ln_s01_2=lnt02 wais5_ln_s02_1=lnt03 wais5_ln_s02_2=lnt04 
wais5_ln_s03_1=lnt05 wais5_ln_s03_2=lnt06 wais5_ln_s04_1=lnt07 wais5_ln_s04_2=lnt08 
wais5_ln_s05_1=lnt09 wais5_ln_s05_2=lnt10 wais5_ln_s06_1=lnt11 wais5_ln_s06_2=lnt12 
wais5_ln_s07_1=lnt13 wais5_ln_s07_2=lnt14 wais5_ln_s08_1=lnt15 wais5_ln_s08_2=lnt16 
wais5_ln_s09_1=lnt17 wais5_ln_s09_2=lnt18 wais5_ln_s10_1=lnt19 wais5_ln_s10_2=lnt20 
wais5_ln_s01-wais5_ln_s10=lni01-lni10 

wais5_topf_s01-wais5_topf_s68 =topf01-topf68
;
   if stdz='Y';
run;
/*proc freq; table stdz*clingrp/list missing; run;*/

/*data waisD;*/
/* set c.wais5_stdz_scored_dc_13sep23*/
/*(keep=teid agey agegrp stdz_all stdz_all_dig stdz sex edl eth region clingrp */
/*wais5_si_s01-wais5_si_s16     	wais5_si_raw */
/*wais5_bdnb_s01-wais5_bdnb_s12 	wais5_bdnb_raw*/
/*wais5_bdbn_s01-wais5_bdbn_s12   wais5_bdbn_raw */
/*wais5_bdp_s01-wais5_bdp_s12 	wais5_bdp_raw */
/*wais5_mr_s01-wais5_mr_s26 		wais5_mr_raw*/
/*wais5_sa_s01-wais5_sa_s23 		wais5_sa_raw */
/**/
/*/*trial*/*/
/*wais5_dsf_s01_1 wais5_dsf_s01_2 wais5_dsf_s02_1 wais5_dsf_s02_2 wais5_dsf_s03_1 wais5_dsf_s03_2 */
/*wais5_dsf_s04_1 wais5_dsf_s04_2 wais5_dsf_s05_1 wais5_dsf_s05_2 wais5_dsf_s06_1 wais5_dsf_s06_2 */
/*wais5_dsf_s07_1 wais5_dsf_s07_2 wais5_dsf_s08_1 wais5_dsf_s08_2 wais5_dsf_s09_1 wais5_dsf_s09_2  */
/*wais5_dsf_s10_1 wais5_dsf_s10_2 */
/*/*item*/*/
/*wais5_dsf_s01-wais5_dsf_s10 	wais5_dsf_raw  */
/**/
/*/*trial*/*/
/*wais5_dss_s01_1 wais5_dss_s01_2  wais5_dss_s02_1 wais5_dss_s02_2  wais5_dss_s03_1 wais5_dss_s03_2  */
/*wais5_dss_s04_1 wais5_dss_s04_2  wais5_dss_s05_1 wais5_dss_s05_2  wais5_dss_s06_1 wais5_dss_s06_2  */
/*wais5_dss_s07_1 wais5_dss_s07_2  wais5_dss_s08_1 wais5_dss_s08_2   wais5_dss_s09_1 wais5_dss_s09_2   */
/*wais5_dss_s10_1 wais5_dss_s10_2*/
/*/*item*/*/
/*wais5_dss_s01-wais5_dss_s10 	wais5_dss_raw  */
/**/
/*/*trial*/*/
/*wais5_dsb_s01_1 wais5_dsb_s01_2  wais5_dsb_s02_1 wais5_dsb_s02_2  wais5_dsb_s03_1 wais5_dsb_s03_2  */
/*wais5_dsb_s04_1 wais5_dsb_s04_2  wais5_dsb_s05_1 wais5_dsb_s05_2  wais5_dsb_s06_1 wais5_dsb_s06_2  */
/*wais5_dsb_s07_1 wais5_dsb_s07_2  wais5_dsb_s08_1 wais5_dsb_s08_2  wais5_dsb_s09_1 wais5_dsb_s09_2   */
/*wais5_dsb_s10_1 wais5_dsb_s10_2*/
/*/*item*/*/
/*wais5_dsb_s01-wais5_dsb_s10 	wais5_dsb_raw  */
/**/
/*wais5_vc_s01-wais5_vc_s24 		wais5_vc_raw 	*/
/*wais5_fwa_s01-wais5_fwa_s28		wais5_fw_raw */
/*wais5_fwb_s01-wais5_fwb_s28 	wais5_fw_raw */
/*wais5_vp_s01-wais5_vp_s25 		wais5_vp_raw*/
/*wais5_rds_s01-wais5_rds_s10 	wais5_rds_raw */
/*wais5_rds_pf01-wais5_rds_pf10 	wais5_rdspf_raw*/
/*wais5_in_s01-wais5_in_s24 		wais5_in_raw */
/*wais5_arnb_s01-wais5_arnb_s22	wais5_arnb_raw*/
/*wais5_arbn_s01-wais5_arbn_s22	wais5_arbn_raw*/
/*wais5_ssp_s01-wais5_ssp_s26 	wais5_ssp_raw*/
/*wais5_sr_s01-wais5_sr_s28 		wais5_sr_raw*/
/*wais5_co_s01-wais5_co_s18 		wais5_co_raw*/
/**/
/*/*trial*/*/
/*wais5_lns_s01_1 wais5_lns_s01_2 wais5_lns_s02_1 wais5_lns_s02_2 wais5_lns_s03_1 wais5_lns_s03_2 */
/*wais5_lns_s04_1 wais5_lns_s04_2 wais5_lns_s05_1 wais5_lns_s05_2 wais5_lns_s06_1 wais5_lns_s06_2 */
/*wais5_lns_s07_1 wais5_lns_s07_2 wais5_lns_s08_1 wais5_lns_s08_2 wais5_lns_s09_1 wais5_lns_s09_2  */
/*wais5_lns_s10_1 wais5_lns_s10_2*/
/*/*item*/*/
/*wais5_lns_s01-wais5_lns_s10 	wais5_lns_raw */
/**/
/*wais5_topf_s01-wais5_topf_s68 	wais5_topf_raw);*/
/**/
/* rename */
/*wais5_si_s01-wais5_si_s16    	=si01-si16  */
/*wais5_bdnb_s01-wais5_bdnb_s12	=bdnb01-bdnb12*/
/*wais5_bdbn_s01-wais5_bdbn_s12  	=bdbn01-bdbn12 */
/*wais5_bdp_s01-wais5_bdp_s12  	=bdp01-bdp12 */
/*wais5_mr_s01-wais5_mr_s26    	=mr01-mr26*/
/*wais5_sa_s01-wais5_sa_s23    	=sa01-sa23 */
/**/
/*wais5_dsf_s01_1=dsft01 	wais5_dsf_s01_2=dsft02 	wais5_dsf_s02_1=dsft03 	wais5_dsf_s02_2=dsft04 */
/*wais5_dsf_s03_1=dsft05 	wais5_dsf_s03_2=dsft06 	wais5_dsf_s04_1=dsft07 	wais5_dsf_s04_2=dsft08 */
/*wais5_dsf_s05_1=dsft09 	wais5_dsf_s05_2=dsft10 	wais5_dsf_s06_1=dsft11 	wais5_dsf_s06_2=dsft12 */
/*wais5_dsf_s07_1=dsft13 	wais5_dsf_s07_2=dsft14 	wais5_dsf_s08_1=dsft15 	wais5_dsf_s08_2=dsft16 */
/*wais5_dsf_s09_1=dsft17 	wais5_dsf_s09_2=dsft18 	wais5_dsf_s10_1=dsft19 	wais5_dsf_s10_2=dsft20 */
/*wais5_dsf_s01-wais5_dsf_s10=dsfi01-dsfi10 */
/**/
/*wais5_dss_s01_1=dsst01 wais5_dss_s01_2=dsst02 wais5_dss_s02_1=dsst03 wais5_dss_s02_2=dsst04 */
/*wais5_dss_s03_1=dsst05 wais5_dss_s03_2=dsst06 wais5_dss_s04_1=dsst07 wais5_dss_s04_2=dsst08 */
/*wais5_dss_s05_1=dsst09 wais5_dss_s05_2=dsst10 wais5_dss_s06_1=dsst11 wais5_dss_s06_2=dsst12 */
/*wais5_dss_s07_1=dsst13 wais5_dss_s07_2=dsst14 wais5_dss_s08_1=dsst15 wais5_dss_s08_2=dsst16 */
/*wais5_dss_s09_1=dsst17 wais5_dss_s09_2=dsst18 wais5_dss_s10_1=dsst19 wais5_dss_s10_2=dsst20 */
/*wais5_dss_s01-wais5_dss_s10=dssi01-dssi10 */
/**/
/*wais5_dsb_s01_1=dsbt01 wais5_dsb_s01_2=dsbt02 wais5_dsb_s02_1=dsbt03 wais5_dsb_s02_2=dsbt04 */
/*wais5_dsb_s03_1=dsbt05 wais5_dsb_s03_2=dsbt06 wais5_dsb_s04_1=dsbt07 wais5_dsb_s04_2=dsbt08 */
/*wais5_dsb_s05_1=dsbt09 wais5_dsb_s05_2=dsbt10 wais5_dsb_s06_1=dsbt11 wais5_dsb_s06_2=dsbt12 */
/*wais5_dsb_s07_1=dsbt13 wais5_dsb_s07_2=dsbt14 wais5_dsb_s08_1=dsbt15 wais5_dsb_s08_2=dsbt16 */
/*wais5_dsb_s09_1=dsbt17 wais5_dsb_s09_2=dsbt18 wais5_dsb_s10_1=dsbt19 wais5_dsb_s10_2=dsbt20 */
/*wais5_dsb_s01-wais5_dsb_s10  =dsbi01-dsbi10 */
/**/
/*wais5_vc_s01-wais5_vc_s24    	=vc01-vc24*/
/*wais5_fwa_s01-wais5_fwa_s28    	=fwa01-fwa28  */
/*wais5_fwb_s01-wais5_fwb_s28    	=fwb01-fwb28  */
/*wais5_vp_s01-wais5_vp_s25    	=vp01-vp25   */
/**/
/*wais5_rds_s01-wais5_rds_s10  	=rds01-rds10 */
/*wais5_rds_pf01-wais5_rds_pf10	=rdspf01-rdspf10 */
/**/
/*wais5_in_s01-wais5_in_s24    	=in01-in24  */
/*wais5_arnb_s01-wais5_arnb_s22  	=arnb01-arnb22 */
/*wais5_arbn_s01-wais5_arbn_s22  	=arbn01-arbn22 */
/*wais5_ssp_s01-wais5_ssp_s26  	=ssp01-ssp26*/
/*wais5_sr_s01-wais5_sr_s28    	=sr01-sr28 */
/*wais5_co_s01-wais5_co_s18    	=co01-co18*/
/**/
/*wais5_lns_s01_1=lnst01 wais5_lns_s01_2=lnst02 wais5_lns_s02_1=lnst03 wais5_lns_s02_2=lnst04 */
/*wais5_lns_s03_1=lnst05 wais5_lns_s03_2=lnst06 wais5_lns_s04_1=lnst07 wais5_lns_s04_2=lnst08 */
/*wais5_lns_s05_1=lnst09 wais5_lns_s05_2=lnst10 wais5_lns_s06_1=lnst11 wais5_lns_s06_2=lnst12 */
/*wais5_lns_s07_1=lnst13 wais5_lns_s07_2=lnst14 wais5_lns_s08_1=lnst15 wais5_lns_s08_2=lnst16 */
/*wais5_lns_s09_1=lnst17 wais5_lns_s09_2=lnst18 wais5_lns_s10_1=lnst19 wais5_lns_s10_2=lnst20 */
/*wais5_lns_s01-wais5_lns_s10=lnsi01-lnsi10 */
/**/
/*wais5_topf_s01-wais5_topf_s68 =topf01-topf68*/
/*;*/
/*   if stdz_all_dig='Y';*/
/*run;*/
;
%macro doit(one,two);
%winsteps(DATA=wais,       /* name of dataset used */ 
           PID=teid,      /* Person/Examinee ID default _N_ */
          ITEM=&one ,/* Variable List of Item Scores */
           MAP=YES,      /* request Item map */
           OUT=&two ,       /* name of output files*/
OUTPATH=C:\projects\WAIS5\results\_100pct_analysis_2024\IRT /* output folder path*/
); quit;
%mend;

%doit(si, si01-si18       ,si   );
/*%doit(sia01-sia16      ,sia   );*/
/*%doit(sib01-sib16      ,sib   );*/

%doit(vc01-vc24      ,vc   );
/*%doit(vca01-vca24      ,vca   );*/
/*%doit(vcb01-vcb24      ,vcb   );*/

%doit(in01-in24      ,in   );

%doit(co01-co18      ,co   );
/*%doit(coa01-coa18      ,coa   );*/
/*%doit(cob01-cob18      ,cob   );*/

%doit(bdn01-bdn12  ,bdn );
%doit(bd01-bd12    ,bd );
%doit(bdp01-bdp12  ,bdp  );
%doit(vp01-vp25      ,vp   );
%doit(mr01-mr26      ,mr   );

/*%doit(fwa01-fwa28    ,fwa  );*/
%doit(fw01-fw28    ,fw  );
/*%doit(fwc01-fwc28    ,fwc  );*/

%doit(arnb01-arnb22  ,arnb );
%doit(ar01-ar22      ,ar );

/*%doit(sra01-sra27      ,sra   );*/
%doit(sr01-sr27      ,sr   );

/*per JJ and SR July 2019 only run Digit Span by trial. */
%doit(dft01-dft20  ,dft ); /*%doit(dsfi01-dsfi10  ,dsfi );*/
%doit(dqt01-dqt20  ,dqt ); /*%doit(dssi01-dssi10  ,dssi );*/
%doit(dbt01-dbt20  ,dbt ); /*%doit(dsbi01-dsbi10  ,dsbi );*/
%doit(dft01-dft20 dqt01-dqt20 dbt01-dbt20 ,ds_allt );
%doit(lnt01-lnt20  ,lnt ); /*%doit(lnsi01-lnsi10  ,lnsi );*/

%doit(sys01-sys23    ,sys  );

%doit(sa01-sa23      ,sa   );
%doit(rd01-rd10     ,rd  );
/*%doit(rdspf01-rdspf10,rdspf);*/
%doit(topf01-topf68  ,topf );

/*Digital format separately for SA. */
/*%winsteps(DATA=waisD,     */
/*           PID=teid,      */
/*          ITEM=sa01-sa28 ,*/
/*           MAP=YES,      */
/*           OUT=dig_sa ,*/
/*OUTPATH=C:\temp */
/*); quit;*/








%macro exprt(dat=);
proc export data=&dat 
    outfile="C:\projects\WAIS5\results\_100pct_analysis_2024\IRT\Wais5_stdz_Winsteps_&day..xlsx" dbms=xlsx replace; 
    sheet="&dat"; 
run;
%mend;
data readme; 
length column label $40;
    column='item';      label='item'; output;
    column='b';         label='b'; output;
    column='Error';     label='Std. Error'; output;
    column='N';         label='N'; output;
    column='ItemScore'; label='ItemScore'; output;
    column='in_msq';    label='Infit MSQ'; output;
    column='in_zstd';   label='Infit Z-STD'; output;
    column='out_msq';   label='Outfit MSQ'; output;
    column='out_zstd';  label='Outfit Z-STD'; output;
    column='displ';     label='displacement'; output;
    column='Pb';        label='Pb Item-Theta'; output;
    column='discr';     label='discrimination'; output;
    column='PValue';    label='P-Value'; output;
run;
%exprt(dat=readme   );
%exprt(dat=si   );/*%exprt(dat=sia   );%exprt(dat=sib   );*/
%exprt(dat=vc   );/*%exprt(dat=vca   );%exprt(dat=vcb   );*/
%exprt(dat=in   );
%exprt(dat=co   );/*%exprt(dat=coa   );%exprt(dat=cob   );*/
%exprt(dat=bdn );
%exprt(dat=bd );
%exprt(dat=bdp  );
%exprt(dat=vp   );
%exprt(dat=mr   );
/*%exprt(dat=fwa  );*/
%exprt(dat=fw  );
/*%exprt(dat=fwc  );*/

%exprt(dat=arnb );
%exprt(dat=ar );
/*%exprt(dat=sra  );*/
%exprt(dat=sr );
%exprt(dat=dft );
/*%exprt(dat=dsfi );*/
%exprt(dat=dqt );
/*%exprt(dat=dssi );*/
%exprt(dat=dbt );
/*%exprt(dat=dsbi );*/
%exprt(dat=ds_allt );
%exprt(dat=rd  );
/*%exprt(dat=rdspf);*/
%exprt(dat=lnt );
/*%exprt(dat=lnsi );*/
%exprt(dat=sys  );
%exprt(dat=sa   );
/*%exprt(dat=dig_sa);*/
%exprt(dat=topf );



title; footnote; 
*******************************
end of code
*******************************;
