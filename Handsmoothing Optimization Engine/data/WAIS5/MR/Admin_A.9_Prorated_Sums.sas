/**********************************
Admin_A9.sas  WAIS5 STDZ

Admin A.9	Prorated Sums of Scaled Scores for Deriving the FSIQ and the NMI                 
Based on FSIQ which contains 7 subtests and a sum of 6 subtests
Based on NMI which contains 7 subtests and a sum of 6 subtests

Wendy Li 3/7/2024
**********************************/
options ps=max; 
%let outpath=C:\project\WAIS5 Australia\tables\in sas;
libname t "C:\project\WAIS5 Australia\tables\in sas";

data a9; 
   do sum6=6 to 114;
      prosum=round(sum6*7/6,1);
      output;
   end;
run;
proc print noobs; run;

data t.appa9_prorated_sums_fsiq_nmi; set a9; run;
proc export data=t.Admin_A9_prorated_sums
   outfile="&outpath\Admin_A9_Prorated_Sums_fsiq_nmi.xlsx" replace; 
run;

title; footnote; 
*******************************
end of code
*******************************;
