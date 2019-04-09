*data import as movie;
PROC IMPORT OUT= WORK.movie 
            DATAFILE= "C:\Users\A08399\Desktop\movie.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
*descriptive statistic analysis for each variable;
proc univariate data=movie;
var num_critic_for_reviews duration director_facebook_likes actor_1_facebook_likes actor_2_facebook_likes actor_3_facebook_likes;
run; 
*delete movie with few review numbers;
data movie1;
set movie;
if num_critic_for_reviews>=128;
three_actors_facebook_likes=actor_1_facebook_likes+actor_2_facebook_likes+actor_3_facebook_likes;
run;
*transform facebook likes of directors and actors to star ranging from 1 to 5;
proc univariate data=movie1;
var director_facebook_likes;
output pctlpts=50 70 85 95 pctlpre=pwid;
run;
proc univariate data=movie1;
var three_actors_facebook_likes;
output pctlpts=50 70 85 95 pctlpre=pwid;
run;
data movie2;
set movie1;
if director_facebook_likes<=157 then director_star=1;
else if director_facebook_likes>157 and director_facebook_likes<=350 then director_star=2;
else if director_facebook_likes>350 and director_facebook_likes<=670 then director_star=3;
else if director_facebook_likes>670 and director_facebook_likes<=14000 then director_star=4;
else director_star=5;
run;
data movie3;
set movie2;
if three_actors_facebook_likes<=6101 then actors_star=1;
else if three_actors_facebook_likes>6101 and three_actors_facebook_likes<=15974 then actors_star=2;
else if three_actors_facebook_likes>15974 and three_actors_facebook_likes<=26722 then actors_star=3;
else if three_actors_facebook_likes>26722 and three_actors_facebook_likes<=44000 then actors_star=4;
else actors_star=5;
run;
*principal components analysis for genres of movies;
proc factor data=movie3 preplot plot scree nfactors=6 rotate=varimax out=movie4;
title "Factor Analysis for Catagory";
var Action Adventure Family	Animation Comedy Drama
Biography Mystery Horror Musical Crime Documentary
Fantasy	Sci_Fi Romance Western Thriller;
run;
*divide population into 4 subsets for cross validation;
proc surveyselect data=movie4 method =srs n=390 out=test1 seed = 25070419;
run ;
proc sql ;
     create table movie5 as
     select *
     from movie4
    where movie4.movie_title not in(select test1.movie_title from test1);
quit;
proc surveyselect data=movie5 method =srs n=390 out=test2 seed = 25070419;
run ;
proc sql ;
     create table movie6 as
     select *
     from movie5
    where movie5.movie_title not in(select test2.movie_title from test2);
quit;
proc surveyselect data=movie6 method =srs n=389 out=test3 seed = 25070419;
run ;
proc sql ;
     create table test4 as
     select *
     from movie6
    where movie6.movie_title not in(select test3.movie_title from test3);
quit;
data train1;
set test2 test3 test4;
data train2;
set test1 test3 test4;
data train3;
set test1 test2 test3;
data train4;
set test1 test2 test3;
run;
*conduct regression model for rating for each training set;
proc reg data=train1 outest=regout1;
title "regression model for movie score (test1)";
model imdb_score=duration director_star title_year actors_star budget/vif stb;
run;
quit;
proc score data=test1 score=regout1 out=testout1
type=parms;
var  duration director_star title_year actors_star budget;
run;
data testout1;
set testout1;
deviation=model1-imdb_score;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/390)**1/2 as mse1
from testout1;
quit;
proc reg data=train2 outest=regout2;
title "regression model for movie score (test2)";
model imdb_score=duration director_star title_year actors_star budget/vif stb;
run;
quit;
proc score data=test2 score=regout2 out=testout2
type=parms;
var  duration director_star title_year actors_star budget;
run;
data testout2;
set testout2;
deviation=model1-imdb_score;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/390)**1/2 as mse2
from testout2;
quit;
proc reg data=train3 outest=regout3;
title "regression model for movie score (test3)";
model imdb_score=duration director_star title_year actors_star budget/vif stb;
run;
quit;
proc score data=test3 score=regout3 out=testout3
type=parms;
var  duration director_star title_year actors_star budget;
run;
data testout3;
set testout3;
deviation=model1-imdb_score;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/389)**1/2 as mse3
from testout3;
quit;
proc reg data=train4 outest=regout4;
title "regression model for movie score (test4)";
model imdb_score=duration director_star title_year actors_star budget/vif stb;
run;
quit;
proc score data=test4 score=regout4 out=testout4
type=parms;
var  duration director_star title_year actors_star budget;
run;
data testout4;
set testout4;
deviation=model1-imdb_score;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/389)**1/2 as mse4
from testout4;
quit;
proc reg data=movie4;
title "regression model for movie score (all)";
model gross=factor1 factor2 factor3 factor4 factor5 factor6 duration director_star actors_star budget title_year/selection=stepwise vif stb;
run;
quit;
proc score data=movie4 score=regout out=testout
type=parms;
var factor1 factor2 factor3 factor4 factor5 factor6 duration director_star actors_star budget title_year;
run;
*conduct regression model for gross for each training set;
proc reg data=train1 outest=regout5;
title "regression model for movie gross (test1)";
model gross=factor1 factor2 factor3 factor5 duration director_star actors_star budget/ vif stb;
run;
quit;
proc score data=test1 score=regout5 out=testout5
type=parms;
var factor1 factor2 factor3 factor5 duration director_star actors_star budget;
run;
data testout5;
set testout5;
deviation=model1-gross;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/390)**1/2 as mse1
from testout5;
quit;
proc reg data=train2 outest=regout6;
title "regression model for movie gross (test2)";
model gross=factor1 factor2 factor3 factor5 duration director_star actors_star budget/vif stb;
run;
quit;
proc score data=test2 score=regout6 out=testout6
type=parms;
var factor1 factor2 factor3 factor5 duration director_star actors_star budget;
run;
data testout6;
set testout6;
deviation=model1-gross;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/390)**1/2 as mse2
from testout6;
quit;
proc reg data=train3 outest=regout7;
title "regression model for movie gross (test3)";
model gross=factor1 factor2 factor3 factor5 duration director_star actors_star budget/vif stb;
run;
quit;
proc score data=test3 score=regout7 out=testout7
type=parms;
var factor1 factor2 factor3 factor5 duration director_star actors_star budget;
run;
data testout7;
set testout7;
deviation=model1-gross;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/389)**1/2 as mse3
from testout7;
quit;
proc reg data=train4 outest=regout8;
title "regression model for movie gross (test4)";
model gross=factor1 factor2 factor3  factor5 duration director_star actors_star budget/ vif stb;
run;
quit;
proc score data=test4 score=regout8 out=testout8
type=parms;
var factor1 factor2 factor3 factor5 duration director_star actors_star budget;
run;
data testout8;
set testout8;
deviation=model1-gross;
deviation_square=deviation*deviation;
run;
proc sql;
select (sum(deviation_square)/389)**1/2 as mse4
from testout8;
quit;
proc reg data=movie4;
title "regression model for movie gross (all)";
model gross=factor1 factor2 factor3 factor4 factor5 factor6 duration director_star actors_star budget title_year/selection=stepwise vif stb;
run;
quit;
proc score data=movie4 score=regout out=testout
type=parms;
var factor1 factor2 factor3 factor4 factor5 factor6 duration director_star actors_star budget title_year;
run;
