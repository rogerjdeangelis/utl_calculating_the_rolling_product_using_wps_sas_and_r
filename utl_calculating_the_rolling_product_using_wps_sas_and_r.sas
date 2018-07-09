Calculating the rolling PRODUCT using wps sas and r

Same Results in SAS/ETS, Base WPS(ETS part of base) and WPS/ProcR or IML/R


see
https://tinyurl.com/yccfeyk9
https://communities.sas.com/t5/General-SAS-Programming/Calculating-the-PRODUCT-for-a-rolling-time-period/m-p/476405

inspired by
https://stackoverflow.com/questions/50402807/moving-variance-with-aggregation

Compute product of rrents for a rolling window of three

INPUT
=====
                         |    RULES
  SD1.HAVE total obs=12  |
                         |
    BLDG    RENT         |   Rolling Product
                         |
     A        1          |    .    not enough info for average
     A        2          |    .    not enough info for average
     A        3          |   6 = 1*2*3
     A        3          |  18 = 2*3*3
     A        2          |  18 = 3*3*2
     A        1          |   6 - 3*2*1
                         |
     A        2          |    .    not enough info for average
     B        4          |    .    not enough info for average
     B        6          |  48 = 2*4*6
     B        6          | 144 = 4*6*6
     B        4          | 144 = 6*6*4
     B        2          |  48 = 6*4*2



PROCESS
=======

 Base WPS and SAS (proc expand is in base WPS)

  proc expand data=sd1.have out=want(drop=time) method=none;
    by bldg;
    convert rent = rent_movprod /transformin=(movprod 3 trimleft 2);
  run;quit;

 WPS Proc R  (working code)

  myfun = function(x) rollmean(x, k = 3, fill = NA, align = "right");
  have %>% group_by(BLDG) %>% mutate_each(funs(myfun), RENT) -> wantwps;



OUTPUT
=====

 WANTSAS total obs=12

                          RENT_
  Obs    BLDG    RENT    MOVPROD

    1     A        1         .
    2     A        2         .
    3     A        3         6
    4     A        3        18
    5     A        2        18
    6     A        1         6

    7     B        2         .
    8     B        4         .
    9     B        6        48
   10     B        6       144
   11     B        4       144
   12     B        2        48


*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
input bldg$ rent;
cards4;
A 1
A 2
A 3
A 3
A 2
A 1
B 2
B 4
B 6
B 6
B 4
B 2
;;;;
run;quit;


SAS/ETS
=======

proc expand data=sd1.have out=wantsas(drop=time) method=none;
  by bldg;
   convert rent = rent_movprod/transformin=(movprod  3 trimleft 2);
run;quit;

title "Transformed Series";
proc print data=wantsas;
var bldg  rent rent_movprod;
run;quit;

BASE WPS
========

%utl_submit_wps64('
libname wrk  sas7bdat "%sysfunc(pathname(work))";
libname sd1 "d:/sd1";
proc expand data=sd1.have out=wrk.wantwps(drop=time) method=none;
by bldg;
convert rent = rent_movprod /transformin=(movprod 3 trimleft 2);
run;quit;
');

proc print data=wantwps;
var bldg  rent rent_movprod;
run;quit;

WPS PROC R
==========

options ls=171;
%utl_submit_wps64('
libname sd1 "d:/sd1";
options set=R_HOME "C:/Program Files/R/R-3.3.2";
libname wrk  sas7bdat "%sysfunc(pathname(work))";
proc r;
submit;
source("C:/Program Files/R/R-3.3.2/etc/Rprofile.site", echo=T);
library(haven);
have<-read_sas("d:/sd1/have.sas7bdat");
library(dplyr);
library(zoo);
myfun = function(x) rollsum(log(x), k = 3, fill = NA, align = "right");
have %>% group_by(BLDG) %>% mutate_each(funs(myfun), RENT) -> wantwps;
wantwps$RENT=exp(wantwps$RENT);
endsubmit;
import r=wantwps   data=wrk.want;
run;quit;
proc print data=wrk.want;
run;quit;
');

