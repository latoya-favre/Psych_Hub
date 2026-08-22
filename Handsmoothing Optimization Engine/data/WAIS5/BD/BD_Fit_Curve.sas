proc datasets kill;run;quit;

libname x 'C:\ongoing projects\WAIS5\stdz\data';
data pal2 (keep=teid agegrp agedec stdz bdtot);
	set x.wais5_stdz_final;
		if stdz='Y';
		bdtot=wais5_bd_raw;
run;


%let data_in=pal2;
%let normgrp=agegrp;  /*Initial group used to obtain sample moments */

/*Name and label for variable on the X-axis*/
%let fitby=agedec; %let lbl=Age in year with decimal;
%let grd=1:13/*Observed Norming Group range*/;

%let function=plot /*plot save print*/;

%let var=bd /*Variable name without tot*/;
%let moment=mean /*mean stddev skew kurt*/;
%let grdnorm=1:13/*Theoretical Norming Group range*/;

/*Print and Save Options*/
%let power= /*specify only when save and print*/;
libname savepath 'C:\temp' /*Where a single graph will be saved. Specify only when save*/;

/**Adjustment to plot options. Leave as blank if no adjustment is needed**/
%let adjsize=-7 /*Adjust font size for printed predicted values on plot. */
                          /*Enter +# (e.g., +.5) to enlarge; Enter -# (e.g., -.5) to reduce.*/;
%let adjscale=-1 /*Adjust plot vertical scale.*/
                                 /*Enter +# (e.g., +1) to enlarge; Enter -# (e.g., -1) to reduce*/;
%let adjx=+1 /*Adjust title position.*/
                        /*Enter +# (e.g., +1) to move to right;Enter -# (e.g., -1) to move to left */;
%let adjy=+4/*Adjust title position.*/
                   /*Enter +# (e.g., +1) to move up; Enter -# (e.g., -1) to move down*/;

/*Type in prediction points after dataline. Do not change anything else.*/
data ppred; input &normgrp &fitby._norm;
datalines;
1 17
2 19
3 22.5
4 27.5
5 32.5
6 40
7 50
8 60
9 67.5
10 72.5
11 77.5
12 82.5
13 88
;
run;



/****************************************************************/
/*Do not change anything below this line*************************/
/****************************************************************/
options ls=80 ps=100 nonumber nodate;
symbol2 value=plus i=spline l=1 color=black;
symbol1 value=dot height=.8 i=none color=black;

/*Position the four plots*/
proc greplay tc=work.newt nofs;
tdef temp4 des='four in one'
4/llx=48  lly=0
  lrx=98 lry=0
  ulx=48  uly=50
  urx=98 ury=50
3/llx=0  lly=0
  lrx=50 lry=0
  ulx=0  uly=50
  urx=50 ury=50
1/llx=0  lly=48
  lrx=50 lry=48
  ulx=0  uly=98
  urx=50 ury=98
2/llx=48  lly=48
  lrx=98 lry=48
  ulx=48  uly=98
  urx=98 ury=98
;run;quit;

%global time;
%let time=%sysfunc(time(),mmss4.);%put &time;


%macro fitcurve;
/*Calculate observed schooling in days for each grade*/
ods graphics off;
proc means data=&data_in  mean std min max;
        title1 "Observed &fitby by &normgrp";
        class &normgrp;
        label &fitby="&lbl";
        var &fitby;
        ods output summary=m1;title1; title2;
data m1; set m1; keep &normgrp &fitby._mean;
data m1; set m1; rename &fitby._mean=&fitby._obs;

/*Calculate observed moments for each group*/
proc means data=&data_in &moment;
        class &normgrp;
        var &var.tot;
        ods output summary=tt;
run;
proc sort data=tt; by &normgrp;
data pobs; merge tt m1; by &normgrp;run;
data pobs; set pobs; type='Obs '; rename &fitby._obs=&fitby.1;

data ppred; set ppred; type='Pred'; rename &fitby._norm=&fitby.1;
data plot; set pobs ppred;
        &fitby.2=&fitby.1**2;
        &fitby.3=&fitby.1**3;
        &fitby.4=&fitby.1**4;
run;

%do i=1 %to 4;
        %let intercept=0;%let &fitby.2=0;%let &fitby.3=0; %let &fitby.4=0;%let &fitby.1=0;
        data tt; set plot;keep &var.tot_&moment &fitby.1-&fitby.4 type &normgrp;
                if &normgrp in (&grd);
        run;
        proc reg data=tt;  where type='Obs ';
                model &var.tot_&moment=%do j=1 %to &i; &fitby&j %end;;
                ods output parameterestimates=pp fitstatistics=ff;
        run;quit;
        data pp; set pp;
                call symput (variable,estimate);run;

        data ff; set ff;
                if label2='Adj R-Sq' then do;
                if cvalue2=. then do; %let ra&i=overfit;end;
                else do; call symput ("Ra&i",cvalue2);end;
                                end;

                                if label2='R-Square' then do;
                if cvalue2=. then do; %let r&i=overfit;end;
                else do; call symput ("R&i",cvalue2);end;
                        end;
        run;
        %put &var.tot_&moment=&intercept+&fitby.1*&&&fitby.1+&fitby.1**2*&&&fitby.2+&fitby.1**3*&&&fitby.3+&fitby.1**4*&&&fitby.4;

                data tt; set tt; if type='Obs ';run;
        data pp; set plot; if type='Pred' and &normgrp in (&grdnorm);
                  &var.tot_&moment=&intercept+&fitby.1*&&&fitby.1+&fitby.1**2*&&&fitby.2+&fitby.1**3*&&&fitby.3+&fitby.1**4*&&&fitby.4;
                              &var.tot_&moment=round(&var.tot_&moment,.0001);
        run;
                data tt; set tt pp;

        data tt&i; set tt; keep &normgrp &var.tot_&moment &fitby.1 type;
        data tt&i; set tt&i;
                order=&i;

        data ann&i; set tt&i;
                if type='Pred' ;format text $10.;
                rename &fitby.1=x; rename &var.tot_&moment=y;
                xsys='2'; ysys='2'; hsys='3';function='label';position='8'; style='SIMPLEX';size=3.5&adjsize;
        data ann&i; set ann&i; text=round(y,.01);run;

        data aa; set tt&i;
                if type='Pred' ;format text $10.;
                rename &fitby.1=x; rename &var.tot_&moment=y;
                xsys='2'; ysys='2'; hsys='3';function='label';position='1'; style='SIMPLEX';size=3.5&adjsize-.5;
        data aa; set aa; text=&normgrp;run;

        data ann&i; set ann&i aa;run;
%end;

 %if &function=print %then %do;
        data rr; set tt1 tt2 tt3 tt4;  keep &var.tot_&moment order type &normgrp;
        proc sort data=rr; by type order &normgrp;
        proc transpose data=rr out=pp;
                by type order;
                id &normgrp;
                var &var.tot_&moment;
        data pp; set pp; drop _label_ _name_; if type='Obs ' and order ne 1 then delete;
        data pp; set pp; if type='Obs ' then order=.;
        ods html style=xstyle;
        proc print data=pp label; where type='Obs ' or order=&power;
                title "Observed and Predicted &moment for &var.tot";
                label order='Power';
                id type;
        run;title;
        ods html close;
  %end;

    data rr; set tt1 tt2 tt3 tt4; keep &normgrp &var.tot_&moment;
        proc sort; by &var.tot_&moment;
        data rr; set rr;
         if _n_=1 then do; call symput('low',&var.tot_&moment);end;
        proc sort; by descending &var.tot_&moment;
        data rr; set rr;
          if _n_=1 then do; call symput('high',&var.tot_&moment);end;
        run;
        %let bb=%scan(%sysevalf((&high-&low)/5),1,'.');%if &bb=0 %then %let bb=1;
        %let low2=%scan(%eval(%scan(%sysevalf((&high+&low)/2),1,'.')-&bb*(6&adjscale)),1,'.');
        %let high2=%scan(%eval(%scan(%sysevalf((&high+&low)/2),1,'.')+&bb*(6&adjscale)),1,'.');

    axis1  length=80pct minor=none label=none order=(&low2 to &high2 by &bb);
        axis2  length=80pct label=(font=swiss height=1.2);

  %if &function=plot %then %do;
  %let tx=%eval(20&adjx);%let ty=%eval(37&adjy);
        %do j=1 %to 4;
                proc gplot data=tt&j gout=work.&var&moment&time;
                  label &fitby.1="&lbl";
                  label type='Score';
                  title move=(&tx,&ty) height=1.5 "Fit &var.tot &moment: &normgrp &grd (Power=&j: R2=&&r&j; AdjR2=&&ra&j)";
                  plot &var.tot_&moment*&fitby.1=type/annotate=ann&j vaxis=axis1 haxis=axis2 nolegend name="p&j";
                run;title;quit;
        %end;
        proc greplay igout=work.&var&moment&time tc=work.newt gout=work.&var&moment&time nofs;
                template temp4;
                treplay
                1: p1
                2: p2
                3: p3
                4: p4
                ;
        run;quit;
 %end;

 %if &function=save %then %do;
        %if &moment=mean %then %do; %let mm=mn;%end;
        %if &moment=stddev %then %do; %let mm=sd; %end;
        %if &moment=skew %then %do; %let mm=sk; %end;
        %if &moment=kurt %then %do; %let mm=kt; %end;
                proc gplot data=tt&power gout=savepath.save;
                  label &fitby.1="&lbl";
                  label type='Score';
                  title move=(25,39) height=1.5 "Fit &var.tot &moment: Grade &grd (Power=&power: R2=&&r&power AdjR2=&&ra&power)";
                  plot &var.tot_&moment*&fitby.1=type/annotate=ann&power vaxis=axis1 haxis=axis2 nolegend name="&var&mm&power";
                run;title;quit;
 %end;
proc datasets;
        save ppred (memtype=data) &data_in(memtype=data) sasgopt(memtype=catalog) sasmacr(memtype=catalog)
                %if &function=plot %then %do; &var&moment&time (memtype=catalog) %end;;
run;quit;
%mend;
%fitcurve;
ods graphics on;
