* ===================================================== 
 	3_merge_norm (wais5).sas

		Data input: 	wais5_stdz_final
		Norm input:		xx norms.xlsx
		Sample:			stdz= Y / normgrp=agegrp=13 / N= 2020

	Haijiang 2/16/2023	
======================================================== ; 
options FORMCHAR= "|----|+|---+=|-/\<>*" nolabel nodate nonumber spool
 compress=binary ls=96 ps=600  nocenter; title; 
 
proc datasets kill nolist; quit;
dm 'log' clear; dm 'output' clear;  ;

/* ------------------------------------------------------------ */
/*			   		Modify --> Macro Below 						*/
/* ------------------------------------------------------------ */

%let test = wais5	; 					* test name			;
* ========================== ;

/*%let sub  = bd	;*/
/*%let max_score= 66	; 					* max raw score 	;*/
*--------------------- ;
/*%let sub  = vp	;*/
/*%let max_score= 25	; 					* max raw score 	;*/
*--------------------- ;

/*%let sub  = mr	;*/
/*%let max_score= 26	; 					* max raw score 	;*/
*--------------------- ;

/*%let sub  = fw	;*/
/*%let max_score= 40	; 					* max raw score 	;*/
*--------------------- ;

/*%let sub  = ar	;*/
/*%let max_score= 25	; 					* max raw score 	;*/
*--------------------- ;

%let sub  = sr	;
%let max_score= 32	; 					* max raw score 	;
*--------------------- ;

* ========================== ;
%let max_grp =  13	;					* max norm grp		; 
%let norm_file= &sub. norms.xlsx	;

%let pa = C:\Data\wais5\norm ; 		* norm file folder		;
libname x "C:\Data\wais5\data";		* data file folder		;


/* ------------------------------------------------------------ */
/*			   			No Change Below 						*/
/* ------------------------------------------------------------ */

 
%let idat = &test._stdz_final;			* input SAS data name 	;
 
data age ;  set x.&idat.  ; 
	if stdz = 'Y' ;
	keep teid agey agegrp ageband  normgrp &test._&sub._raw   ;
data dis; length stdz $8; set age; stdz='    ';	stdz=' stdz'; run;
proc sort ; by teid; run;

			* ====== Add clingrp cases ====== ;
		data cln; length stdz $8; set x.&idat.(drop=stdz)  ; 

		if clingrp='GT_PPE' then clingrp='GT';
		if clingrp in ('GT','IDMI', 'IDMO','ADHD'); 
		stdz=lowcase(compress(clingrp)); teid=10000000+teid;

			keep teid agey agegrp ageband  normgrp &test._&sub._raw  stdz clingrp;
		proc sort ; by teid; run;

data dis; merge dis cln; by teid; run;

 	
/*	proc freq data= dis; table agegrp* ageband* normgrp stdz clingrp/list; where stdz=' stdz'; run;	 */
/* 	proc means data=dis  maxdec=2 ;   var &test._&sub._raw ;	  class stdz; 	 run;*/
 

%macro merg(norm , tot , ss , stgrp , etgrp );

	proc import out=aa datafile= "&pa.\&norm_file."  dbms=xlsx replace; sheet="out"; run;

	data norm; set aa;
		if not missing(&tot);
	    keep &tot ss&stgrp-ss&etgrp;
	proc sort data=norm; by &tot;

	data tmp; set dis;
	proc sort data=tmp; by &tot;
	data tmp; merge tmp(in=a) norm; by &tot; if a;
	data tmp; set tmp;
	    ag=normgrp;
	    &ss=.;
	    %do i=&stgrp %to &etgrp;
	        if ag=&i then &ss=ss&i;
	    %end;
	    drop ag;

	* ======= Set for clingrp cases ======= ;
	data tmp; set tmp;
		if clingrp~=' ' then do;
				 if clingrp='IDMI' then do; agegrp=14; ageband=compress(clingrp); end;
			else if clingrp='IDMO' then do; agegrp=15; ageband=compress(clingrp); end;
			else if clingrp='ADHD' then do; agegrp=16; ageband=compress(clingrp); end;
			else if clingrp='GT'   then do; agegrp=17; ageband=compress(clingrp); end;
		end;
	run;

	proc sort data=tmp; by normgrp;

	/*  =======  Overall ========= */

	proc means data=tmp  maxdec=2  noobs; 
	  var &ss;
	  class stdz;
		where stdz=' stdz';

	  title "Overall mean";

	proc univariate data=tmp noprint ;
	  	var &ss; class stdz; 
		where stdz=' stdz';
	  	output out=jj1 pctlpre=P pctlpts=2 16 50 84 98 pctlname=_02 _16 _50 _84 _98;

	proc print data=jj1 noobs; 
		title "&norm overall pct"; run;

	/*  ========= Normgrp/Agegrp ========= */

	proc means data=tmp maxdec=2  noobs; 
		class agegrp ageband;
	  	var &ss; 
/*		where stdz=' stdz';*/
	  	title "Group mean by agegrp";

	proc univariate data=tmp noprint ;
	  	var &ss; class agegrp  ageband; 
	  	output out=jj2 pctlpre=P pctlpts=2 16 50 84 98 pctlname=_02 _16 _50 _84 _98;
		where stdz =' stdz';

	proc print data=jj2 noobs ; 
		title "&norm pct by agegrp: Age Norm"; run;
	run;
 
%mend;
 
%merg(&test., &test._&sub._raw, &test._&sub._ss,  1,  &max_grp.); 

 

/* - End - */
