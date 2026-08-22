/*used*/
%macro prepare ;
%let nn=0;
%do k=1 %to %length(&sublist); 
   %if %qsubstr(&sublist,&k,1)=%qsubstr(/,1,1) %then %let nn=%eval(&nn+1);
%end;

%global subtot subtest subss;
%let subtot =;
%let subtest=;
%let subss  =;
%do p= 1 %to &nn;
  %let pp=%scan (&sublist,&p,' ');
  %let sub=%scan(&pp,1,'/- ');
  %let subtot = &subtot wisc5_&sub._raw;
  %let subtest = &subtest &sub;
  %let subss   = &subss wisc5_&sub._ss;
  %global gb&sub ge&sub;
  %let gb&sub=%scan(&pp,2,'/- ');
  %let ge&sub=%scan(&pp,3,'/- ');
  %put &sub &group:    &&gb&sub--&&ge&sub;
%end;
%mend prepare;

/*used*/
%macro merge_sub(sub, var, gstart, gend);
*Merge norm and get SS*;
proc sort data=norm_data; by &var;
proc sort data=&sub;       by &var;
data norm_data; merge norm_data(in=a) &sub; by &var; if a;
   length wisc5_&sub._ss 3;
   %do i=&gstart %to &gend;
      if &group=&i then wisc5_&sub._ss=ss&i;
   %end;
   if wisc5_&sub._ss>19 then wisc5_&sub._ss=19;
   drop ss&gstart-ss&gend;
run;title;
proc means data=norm_data;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data; class agegrp;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data;
  var &var wisc5_&sub._ss;
run;
%mend;
%macro merge_sub155(sub, var, gstart, gend);
*Merge norm and get SS*;
proc sort data=norm_data; by &var;
proc sort data=&sub;       by &var;
data norm_data; merge norm_data(in=a) &sub; by &var; if a;
   length wisc5_&sub._ss 3;
   %do i=&gstart %to &gend;
      if &group=&i then wisc5_&sub._ss=ss&i;
   %end;
/*   if wisc5_&sub._ss>155 then wisc5_&sub._ss=155;*/
   drop ss&gstart-ss&gend;
run;title;
proc means data=norm_data;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data; class agegrp;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data;
  var &var wisc5_&sub._ss;
run;
%mend;
*%merge_contrast(&tt,wisc5_pad_ss,wisc5_pa1_ss,1,14);
%macro merge_contrast(sub, dvar, ivar, gend);
*Merge norm and get SS*;
proc sort data=norm_data; by &dvar;
proc sort data=&sub;      by &dvar;
data norm_data; merge norm_data(in=a) &sub; by &dvar; if a;
   wisc5_&sub._ag=.;
   %if &gend = 8 %then %do;
      if &ivar in (1  : 3 ) then wisc5_&sub._ag=1;
      if &ivar in (4  : 5 ) then wisc5_&sub._ag=2;
      if &ivar in (6  : 7 ) then wisc5_&sub._ag=3;
      if &ivar in (8  : 9 ) then wisc5_&sub._ag=4;
      if &ivar in (10 : 11) then wisc5_&sub._ag=5;
      if &ivar in (12 : 13) then wisc5_&sub._ag=6;
      if &ivar in (14 : 15) then wisc5_&sub._ag=7;
      if &ivar in (16 : 19) then wisc5_&sub._ag=8;
   %end;
   %if &gend = 14 %then %do;
      if &ivar in (1  : 3 ) then wisc5_&sub._ag=1;
      if &ivar in (45 : 69) then wisc5_&sub._ag=1;
      if &ivar in (70 : 74) then wisc5_&sub._ag=2;
      if &ivar in (75 : 79) then wisc5_&sub._ag=3;
      if &ivar in (80 : 84) then wisc5_&sub._ag=4;
      if &ivar in (85 : 89) then wisc5_&sub._ag=5;
      if &ivar in (90 : 94) then wisc5_&sub._ag=6;
      if &ivar in (95 : 99) then wisc5_&sub._ag=7;
      if &ivar in (100 : 104) then wisc5_&sub._ag=8;
      if &ivar in (105 : 109) then wisc5_&sub._ag=9;
      if &ivar in (110 : 114) then wisc5_&sub._ag=10;
      if &ivar in (115 : 119) then wisc5_&sub._ag=11;
      if &ivar in (120 : 124) then wisc5_&sub._ag=12;
      if &ivar in (125 : 129) then wisc5_&sub._ag=13;
      if &ivar in (130 : 155) then wisc5_&sub._ag=14;
   %end;
   
   length wisc5_&sub._ss 3;
   %do i=1 %to &gend;
      if wisc5_&sub._ag=&i then wisc5_&sub._ss=g&i;
   %end;
   drop g1-g&gend;
run;title;
proc means data=norm_data;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data; class wisc5_&sub._ag;
  var wisc5_&sub._ss;
  where stdz="Y";
proc means data=norm_data;
  var wisc5_&sub._ss;
run;
%mend;


/*used to flip norm table to tscore - rsrange1 rsrange2...
Range: use en-dash
Missing: use em-dashes
*/
* en dash - ascii 150 - use for numeric ranges byte(150);
* em dash - ascii 151 - use for blank cells    byte(151);
%macro raw_trans(sub, var, gstart, gend);
   %do i = &gstart %to &gend;
       %let ss = &group.&i;
   
      data temp1; set &sub (keep= &var &ss);
      proc sort;  by &ss;
      data temp1; set temp1;  by &ss ;
        if (first.&ss=1 or last.&ss=1) and &ss ne .;

      proc sort data=temp1; by &ss;
      proc transpose data = temp1 out=temp1out;
      var &var; by &ss;
      
       data temp1out; set temp1out;
/*        if col1 ne . and col2 ne .         then &var=compress (col1||"-"||col2);*/
        if col1 ne . and col2 ne .         then &var=compress (col1||byte(150)||col2);** en-dash **;
        else if col1 ne .  and col2 = .  then &var=compress (col1||" ");

      data n_&sub&i(keep=sscr &sub._&i); set temp1out(rename=(ss&i=sscr &var=&sub._&i)); 
      run;
   %end;
   data N_&sub; merge n_&sub&gstart-n_&sub&gend;by sscr;
      array scrs &sub._&gstart-&sub._&gend;
      do over scrs; if scrs='' then scrs=byte(151); end;** em-dash **;
   run;
title;
proc datasets nolist;delete temp1 temp1out n_&sub&gstart-n_&sub&gend;quit;run;
run;
%mend;

/*used*/
%macro com_trans(cvlist);
    data _null_; array vv(*) &cvlist;
      call symput('nv',trim(left(put(dim(vv),4.))));run;
   %do i = 1 %to &nv;
      %let var = wisc5_%scan(&cvlist,&i)_sum;
      %let ss =  wisc5_%scan(&cvlist,&i)_ss;
      data temp1; set %scan(&cvlist,&i)(keep= &var &ss);
      proc sort;  by &ss;     
       data temp1; set temp1;  by &ss ;
       if first.&ss=1 or last.&ss=1;*keeping only the first and last occurrence of a std score;

      proc transpose data = temp1 out=temp1out;*creates a data set with: ss lowsum-highsum;
      var &var; by &ss;
      data temp1; set temp1;   by &ss;
      proc sort data=temp1out; by &ss;

      data temp1out; set temp1out;
        if col1 ne . and col2 ne .       then %scan(&cvlist,&i)=compress (col1||"-"||col2);
        else if col1 ne .  and col2 = .  then %scan(&cvlist,&i)=compress (col1||" ");
        else if col1 =  .  and col2 = .  then %scan(&cvlist,&i)="-";
        
      data trans&i; set temp1out; keep &ss %scan(&cvlist,&i);
      data trans&i; set trans&i; 
         if %scan(&cvlist,&i) = ' ' then %scan(&cvlist,&i) = "-";
         rename &ss = standss;
      
      proc sort; by standss;
   %end;
   data x.com_norm; merge %do i = 1 %to &nv; trans&i %end; ;*save the data set with: ss lowsum-highsum;
   by standss;
   proc print data = x.com_norm;
   id standss;
   title "Composite norm";
   run;
title;

%mend;

/*not used, only have one composite... don't need*/
%macro com_merge(clist);
    data _null_; array vv(*) &clist;
      call symput('ncom',trim(left(put(dim(vv),4.))));run;

   %do i = 1 %to &ncom;
      %let comvar = %scan(&clist, &i);
      proc sort data = norm_data; by wisc5_&comvar._sum;
      proc sort data = &comvar;   by wisc5_&comvar._sum;
      data tt; merge norm_data(in=a) &comvar ; by wisc5_&comvar._sum; if a;run;
      data norm_data; set tt;
      proc means data=norm_data;
         var wisc5_&comvar._sum wisc5_&comvar._ss;
         where stdz="Y";
      proc means data=norm_data;
         var wisc5_&comvar._sum wisc5_&comvar._ss;
      run;
   %end;
run;
%mend;

/*used*/
%macro print_norm(sub);
   proc printto print = "&printpath\&sub..doc";run;
   proc print data = &sub; id &sub.tot;
   title2 "(Norm for &group)";
   run;
   title2;
   proc printto; run;

%mend;

/*used*/
%macro sub_norm(sub,type);
    data _null_; array vv(*) &sub;
      call symput('nsub',trim(left(put(dim(vv),4.))));run;

   data x.&type._norm;
     merge 
     %do i = 1 %to &nsub;%scan(&sub,&i)page %end; ;
     by standss;
     proc print;
   run;
%mend;

/*used, creates excel file with tab for each subtest, rs --> ss w/ CI and %I*/
%macro subnormtab(tab,reli_dat,p1,p2,mean,std);
  %let sub1 = bd;
  %let sub2 = vc;
  %let sub3 = mr;
  %let sub4 = si;

  %do gr = 1 %to 45;
      %do s = 1 %to 4;
      proc sql noprint;*grabs the split half reliability by agegroup for each subtest;
      select pb&gr into: reliab
      from &reli_dat
      where name = "&&sub&s";
      quit;
      %put &reliab;

      %let ss = &group.&gr;
      %let var = &&sub&s..tot;
      data temp1; set &&sub&s (keep= &var &ss);
      proc sort;  by &ss;
      data temp1; set temp1;  by &ss ;
        if (first.&ss=1 or last.&ss=1) and &ss ne .;*keeps only the first and last rs for each ss;

      proc sort data=temp1; by &ss;
      proc transpose data = temp1 out=temp1out;
      var &var; by &ss;
      
       data temp1out; set temp1out;
        if col1 ne . and col2 ne .         then &var=compress (col1||"-"||col2);*creates ss and lowrs-highrs;
        else if col1 ne .  and col2 = .  then &var=compress (col1||" ");

     data &&sub&s..&gr; set temp1out; keep &var &ss;*saves ss: lowrs-highrs for each subtest agegroup;
     data &&sub&s..&gr; set &&sub&s..&gr;
         length rawscore $8.; 
         rawscore = &&sub&s..tot;
          &&sub&s..ss&gr = &group&gr;
         drop &group&gr &&sub&s..tot;
       data  &&sub&s..&gr; set &&sub&s..&gr; 
           length conf_&p1 $8.;
         length conf_&p2 $8.;
         
          pr=round(cdf('NORMAL',&&sub&s..ss&gr ,&mean,&std)*100,1);*gets percentile rank based on a normal curve;
          if pr <1 and missing(pr) ne 1 then pr=1;*coding for pr <1 and >99;
             if pr>99 then pr=99;

          length con_pr_&p1 $8.;
          length con_pr_&p2 $8.;
         *confidence interval centered on estimated true score;
         c11=round((100+&reliab*(&&sub&s..ss&gr-100))-(round(probit(1-(1-&p1/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c12=round((100+&reliab*(&&sub&s..ss&gr-100))+(round(probit(1-(1-&p1/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c21=round((100+&reliab*(&&sub&s..ss&gr-100))-(round(probit(1-(1-&p2/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c22=round((100+&reliab*(&&sub&s..ss&gr-100))+(round(probit(1-(1-&p2/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         pr11=round(cdf('NORMAL',c11 ,&mean,&std)*100,1);
         pr12=round(cdf('NORMAL',c12 ,&mean,&std)*100,1);
         pr21=round(cdf('NORMAL',c21 ,&mean,&std)*100,1);
         pr22=round(cdf('NORMAL',c22 ,&mean,&std)*100,1);


      data &&sub&s..&gr; set &&sub&s..&gr ; 
         array con(*) conf_&p1 conf_&p2 con_pr_&p1 con_pr_&p2;
         array c1(*) c11 c21 pr11 pr21;
         array c2(*) c12 c22 pr12 pr22;
         array prlist  pr pr11 pr12 pr21 pr22;

         do over prlist; 
            if prlist <1 and missing(prlist) ne 1 then prlist=1;
               if prlist>99 then prlist=99;
         end;


         do i = 1 to dim(con);
            con(i) = compress(c1(i)||"-"||c2(i));
            if i < 3 then do; *do this loop for Conf Interval only not PR Interval;
               if c1(i) < 50 and c2(i) < 151 then con(i) = compress(50||"*-"||c2(i));
               else if 50 <= c1(i) < 151 and c2(i) > 150 then con(i) = compress(c1(i)||"-"||150||"*");
               else if c1(i) > 150 and c2(i)> 150 then con(i) = compress(50||"*-"||150||"*");
            end;
            end; drop i c11 c12 c21 c22 pr11 pr12 pr21 pr22;
         rename &&sub&s..ss&gr = standss;

    proc print;
    title "Norm for &&sub&s  &group &gr";
    id rawscore;
    proc export
       data    = &&sub&s..&gr
       outfile = "&normpath\&tab..xls"
       DBMS    = EXCEL2000 REPLACE;
       sheet   = "&group._&&sub&s..&gr";
   run;
   %end;
%end;
run;
quit;
%mend;

/*used, creates excel file with tab for each composite, sum --> ss w/ %ile, child CI and adult CI*/
%macro comnormtab(tab,reli_dat,p1,p2, mean,std,comlist);
   data _null_; array cc (*) &comlist;
    call symput('ncom',trim(left(put(dim(cc),4.))));run;

      %do s = 1 %to &ncom;
      %let com = %scan(&comlist,&s,' ');

      data temp1; set &com (keep= &com.sum &com.ss);
      proc sort;  by &com.ss;
      data temp1; set temp1;  by &com.ss ;
        if (first.&com.ss=1 or last.&com.ss=1) and &com.ss ne .;

      proc sort data=temp1; by &com.ss;
      proc transpose data = temp1 out=temp1out;
      var &com.sum; by &com.ss;
      
       data temp1out; set temp1out;
        if col1 ne . and col2 ne .         then &com.sum=compress (col1||"-"||col2);
        else if col1 ne .  and col2 = .  then &com.sum=compress (col1||" ");
      proc sql noprint;
      select reliab into: reliab
      from &reli_dat
      where name = "&com";
      quit;
      %put &reliab;
     data temp1out (keep= &com.sum &com.ss);
     set temp1out;
       data  data &com&s; set temp1out;
           length conf_&p1 $8.;
         length conf_&p2 $8.;
         
          pr=round(cdf('NORMAL', &com.ss,&mean,&std)*100,1);
      
          length con_pr_&p1 $8.;
          length con_pr_&p2 $8.;

         c11=round((100+&reliab*(&com.ss-100))-(round(probit(1-(1-&p1/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c12=round((100+&reliab*(&com.ss-100))+(round(probit(1-(1-&p1/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c21=round((100+&reliab*(&com.ss-100))-(round(probit(1-(1-&p2/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
         c22=round((100+&reliab*(&com.ss-100))+(round(probit(1-(1-&p2/100)/2),.01)*(&std*&reliab*sqrt(1-&reliab))),1);
      
         pr11=round(cdf('NORMAL',c11 ,&mean,&std)*100,1);
         pr12=round(cdf('NORMAL',c12 ,&mean,&std)*100,1);
         pr21=round(cdf('NORMAL',c21 ,&mean,&std)*100,1);
         pr22=round(cdf('NORMAL',c22 ,&mean,&std)*100,1); 
      data &com.&s; set &com.&s ; 
         array con(*) conf_&p1 conf_&p2 con_pr_&p1 con_pr_&p2;
         array c1(*) c11 c21 pr11 pr21;
         array c2(*) c12 c22 pr12 pr22;
         array prlist  pr pr11 pr12 pr21 pr22;

         do over prlist; 
            if prlist <1 and missing(prlist) ne 1 then prlist=1;
               if prlist>99 then prlist=99;
         end;

         do i = 1 to dim(con);
            con(i) = compress(c1(i)||"-"||c2(i));
            if i < 3 then do;
               if c1(i) < 50 and c2(i) < 151 then con(i) = compress(50||"*-"||c2(i));
               else if 50 <= c1(i) < 151 and c2(i) > 150 then con(i) = compress(c1(i)||"-"||150||"*");
               else if c1(i) > 150 and c2(i)> 150 then con(i) = compress(50||"*-"||150||"*");
            end;
            end; drop i;

    data &com.&s; retain &com.sum &com.ss conf_&p1 conf_&p2 pr con_pr_&p1 con_pr_&p2 ; 
    set &com.&s; keep &com.sum &com.ss conf_&p1 pr conf_&p2 con_pr_&p1 con_pr_&p2;
    proc print;
    title "Norm for Composite &com";
    id &com.sum;
    proc export
       data    = &com.&s
       outfile = "&normpath\&tab..xls"
       DBMS    = EXCEL2000 REPLACE;
       sheet   = "&com";
   run;
%end;
run;
quit;
%mend;

/*not used, plain composite table w/o ci or pr*/
%macro com_exporttab(subcol,type,norm);
  data _null_; array vv(*) &subcol;
      call symput('ncol',trim(left(put(dim(vv),4.))));run;
  data com (keep=standss %do i = 1 %to &ncol;%scan(&subcol,&i) %end;);
  set x.com_norm;

  data com; set com;
  array new(*) $ v1-v&ncol;
  array old(*) $ %do i = 1 %to &ncol;%scan(&subcol,&i) %end;;
     do i=1 to &ncol;
      new(i)=old(i);
      if new(i) = " " then new(i) = "-";
     end;

  data com; set com; drop %do i = 1 %to &ncol;%scan(&subcol,&i)%end; i ;
  data com; set com;
   %do i = 1 %to &ncol;rename v&i=%scan(&subcol,&i)sum; %end;

 proc print;
 title "Composite Norm of &type";

 proc export
    data    = com
    outfile = "&normpath\&norm..xls"
    DBMS    = EXCEL2000 REPLACE;
    sheet   = "&type";
run;
quit;
%mend;

/*not used, drops temp ss from the file for any listed subtests/composites */
%macro del_tss(subl);
    data _null_; array tss(*) &subl;
    call symput('nts',trim(left(put(dim(tss),4.))));run;
    %put &nts;
   data wms4; set wms4_all;
    drop %do j = 1 %to &nts; %scan(&subl,&j)tot_tss %end;;
    run;
%mend;

/*not used, creates mean/sd for listed subtests/composites by agegrp*/
%macro mean_ss(dat,subl);
 data _null_; array ss(*) &subl;
 call symput('nss',trim(left(put(dim(ss),4.))));
proc tabulate data = &dat; where stdz = 'Y';
class agegrp;
var %do j = 1 %to &nss; %scan(&subl,&j) %end;;
tables %do j = 1 %to &nss; %scan(&subl,&j) %end;,(agegrp=' ' all='Overall')*((mean std)*f=6.1 n*f=6.0);
title "Mean, Std for WASI-II Stdz Sample, By Agegrp";
run;
%mend;

/*not sure what this does*/
%macro merge_cum_data(dat,norm,grp_start, grp_end);
   data &norm; set &norm; level=_n_; drop pr;
   data &norm; set &norm;
   array xx(*) &norm&grp_start.-&norm&grp_end;
   format max&grp_start.-max&grp_end  min&grp_start.-min&grp_end $8.;
   array mx(*) max&grp_start.-max&grp_end ;
   array mn(*) min&grp_start.-min&grp_end ;
    do i=1 to dim(xx);
     if substr(left(xx(i)),1,1) = '>' then mx(i)='999999';
     mn(i)=scan(xx(i),1,'->=');
     if mx(i) =' ' then do;  
       mx(i)=scan(xx(i),2,'-');
       if mx(i)=' ' then mx(i)=mn(i);
     end;
     if mx(i)=' ' and mn(i)=' ' then do; mx(i)='999999'; mn(i)='999999';end;
    end;
   proc print;run;

   proc transpose data=&norm out=max  prefix=max;
   id level;
   var max&grp_start-max&grp_end;
   proc transpose data=&norm out=min  prefix=min;
   id level;
   var min&grp_start-min&grp_end;

   data &norm; merge max min;
   data &norm; set &norm; 
    format agegrp f8.0;
    agegrp=substr(_name_,4);
   proc print;title "QA"; run;title;

   proc sort; by &group;
   

   data all; merge &dat(in=a) &norm; by &group; if a;run;

   data all; set all;
   array mx(*) max1-max7;
   array mn(*) min1-min7;
    do i=1 to dim(mx);
    if &norm.tot>=mn(i) and &norm.tot<=mx(i) then &norm._pr=i;
    if &norm.tot = . then &norm._pr = .;
   end;
   data all; set all; drop i max1-max7 min1-min7 _name_ ;

   data &dat; set all;run;  
%mend;
