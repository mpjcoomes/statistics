LIBNAME SASBMI 'C:\SASBMI';
OPTIONS NOCENTER PAGESIZE=150 LINESIZE=256;
*Reading in raw data from text file and adding labels;
DATA SASBMI.BODYFAT;
INFILE 'C:\SASBMI\bodyfatdata.TXT';
ID=_N_;
INPUT FAT_DENSITY SIRI_BFPER AGE_YEARS WEIGHT_LBS HEIGHT_INCH NECKCIR_CM
CHESTCIR_CM ABDOMENCIR_CM HIPCIR_CM THIGHCIR_CM KNEECIR_CM ANKLECIR_CM
EXTBICIR_CM FOREARMCIR_CM WRISTCIR_CM;
LABEL ID='Case Number'
FAT_DENSITY='Body density determined by underwater weighing'
SIRI_BFPER="Siri's Equation (1956) for body fat percent"
AGE_YEARS='Years old'
WEIGHT_LBS='Weight (lbs)'
HEIGHT_INCH='Height (inches)'
NECKCIR_CM='Neck circumference (cm)'
CHESTCIR_CM='Chest circumference (cm)'
ABDOMENCIR_CM='Abdomen 2 circumference (cm)'
HIPCIR_CM='Hip circumference (cm)'
THIGHCIR_CM='Thigh circumference (cm)'
KNEECIR_CM='Knee circumference (cm)'
ANKLECIR_CM='Ankle circumference (cm)'
EXTBICIR_CM='Biceps (extended) circumference (cm)'
FOREARMCIR_CM='Forearm circumference (cm)'
WRISTCIR_CM='Wrist circumference (cm)';
RUN;
*Checking that raw data was read in correctly;
PROC CONTENTS DATA=SASBMI.BODYFAT; RUN;
PROC PRINT DATA=SASBMI.BODYFAT; RUN;
*Creating custom style, 'MYWAY1', with preferred font for later RTF export;
PROC TEMPLATE;
DEFINE STYLE Styles.MYWAY1;   
PARENT = styles.JOURNAL;
style fonts /   
 'docFont' = ('<serif>, Times Roman',2)  
 'headingFont' = ('<serif>, Times Roman',2,italic)   
 'headingEmphasisFont' = ('<serif>, Times Roman',2,bold italic)  
 'FixedFont' = ('<serif>, Times Roman',2)
 'FixedHeadingFont' = ('<serif>, Times Roman',2,italic)  
 'FixedStrongFont' = ('<serif>, Times Roman',2,bold) 
 'FixedEmphasisFont' = ('<serif>, Times Roman',2,bold italic)
 'EmphasisFont' = ('<serif>, Times Roman',2,italic)  
 'StrongFont' = ('<serif>, Times Roman',2,bold italic)   
 'TitleFont' = ('<serif>, Times Roman',2,bold italic)
 'TitleFont2' = ('<serif>, Times Roman',2,bold italic)   
 'SASTitleFont' = ('<serif>, Times Roman',2,bold italic);
style GraphFonts /  
 'GraphTitleFont' = ('<serif>, Times Roman',11pt) 
 'GraphFootnoteFont' = ('<serif>, Times Roman',10pt)  
 'GraphLabelFont' = ('<serif>, Times Roman',10pt) 
 'GraphUnicodeFont' = ('<serif>, Times Roman',9pt)  
 'GraphValueFont' = ('<serif>, Times Roman',9pt)  
 'GraphDataFont' = ('<serif>, Times Roman',7pt)   
 'GraphAnnoFont' = ('<serif>, Times Roman',10pt);
END; RUN;
*Invoke B&W printing and presentation style and RTF export;
ODS RTF FILE='C:\SASBMI\MYFILE.rtf' STYLE=Styles.MYWAY1;
ODS GRAPHICS ON / RESET border=off HEIGHT=10CM;

**********PART 1: Exploring the dataset for outliers**********;
PROC UNIVARIATE DATA=SASBMI.BODYFAT NOTABCONTENTS NOVARCONTENTS;
VAR FAT_DENSITY SIRI_BFPER AGE_YEARS WEIGHT_LBS HEIGHT_INCH NECKCIR_CM
CHESTCIR_CM ABDOMENCIR_CM HIPCIR_CM THIGHCIR_CM KNEECIR_CM ANKLECIR_CM
EXTBICIR_CM FOREARMCIR_CM WRISTCIR_CM;
RUN;
*cleaning outliers;
DATA CLEANED;
SET SASBMI.BODYFAT;
IF SIRI_BFPER<2.9 OR SIRI_BFPER>41 OR WEIGHT_LBS>300 OR HEIGHT_INCH<60
OR ANKLECIR_CM>33 THEN DELETE;
RUN;
*exporting and plotting skewness and kurtosis;
PROC UNIVARIATE DATA=CLEANED OUTTABLE=OUTTABLE1;
VAR FAT_DENSITY SIRI_BFPER AGE_YEARS WEIGHT_LBS HEIGHT_INCH NECKCIR_CM
CHESTCIR_CM ABDOMENCIR_CM HIPCIR_CM THIGHCIR_CM KNEECIR_CM ANKLECIR_CM
EXTBICIR_CM FOREARMCIR_CM WRISTCIR_CM ;
RUN;
PROC SGPLOT DATA=OUTTABLE1;
REFLINE -1 1 / AXIS=Y LINEATTRS=(COLOR=BLACK PATTERN=2);
VBAR _VAR_ / RESPONSE=_KURT_;
VBAR _VAR_ / RESPONSE=_SKEW_ BARWIDTH=0.5 TRANSPARENCY=0.2;
YAXIS LABEL='Degree of asymmetry & kurtos' VALUES=(-2 TO 2) ;
XAXIS LABEL='Variables';
KEYLEGEND  / NOBORDER LOCATION=INSIDE POSITION=TOPRIGHT;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 1: Measures of asymmetry & kurtosis';
RUN; FOOTNOTE;
*creating new categorical variables and checking frequencies;
PROC FORMAT;
   VALUE BFcustom 0='Underweight' 1='Normal' 2='Obese';
   VALUE BMIcustom 0='Underweight' 1='Normal' 2='Obese';
RUN;
DATA BODYFAT;
SET CLEANED;
FORMAT PER_HEALTH BFcustom. BMI_HEALTH BMIcustom.;
IF SIRI_BFPER<5 THEN PER_HEALTH=0;
ELSE IF SIRI_BFPER>25 THEN PER_HEALTH=2;
ELSE PER_HEALTH=1;
BMI=ROUND((WEIGHT_LBS*703)/(HEIGHT_INCH**2),.01);
IF BMI<18.5 THEN BMI_HEALTH=0;
ELSE IF BMI>25 THEN BMI_HEALTH=2;
ELSE BMI_HEALTH=1;
LABEL PER_HEALTH='Bodyfat% Health Rating' BMI='Body Mass Index' BMI_HEALTH='BMI Health Rating';
RUN;
PROC UNIVARIATE DATA=BODYFAT;
VAR BMI;
RUN;
DATA BODYFAT2;
SET BODYFAT;
IF BMI>39 THEN DELETE;
RUN;
PROC TABULATE DATA=BODYFAT2  format=10.0; 
*VAR PER_HEALTH; 
CLASS PER_HEALTH BMI_HEALTH; 
TABLE PER_HEALTH='' ALL='Total', BMI_HEALTH*(N='') ALL='Total'*(N='') / RTS=25 box='BODY FAT %';
RUN;

**********PART 2: Analysing relationships**********;
*comparing siri with bmi with a scatter plot;
PROC SGPLOT DATA=BODYFAT2;
FOOTNOTE JUSTIFY=LEFT ITALIC "Figure 2. Comparison of measures: Siri's body fat percent vs. BMI";
SCATTER X=BMI Y=SIRI_BFPER / GROUP=PER_HEALTH NAME='SCAT';
REFLINE 25 /  AXIS=X LABEL=('BMI-OBESE') LINEATTRS=(COLOR=BLACK PATTERN=2);
REFLINE 5 25 /  AXIS=Y LABEL=('SIRI-THIN' 'SIRI-OBESE') LINEATTRS=(COLOR=BLACK PATTERN=2);
BAND X=BMI UPPER=42 LOWER=25 / FILLATTRS=(COLOR=GREY) FILL TRANSPARENCY=.9 LEGENDLABEL='OBESE' NAME='BAND';
BAND Y=BMI UPPER=35 LOWER=25 / FILLATTRS=(COLOR=GREY) FILL TRANSPARENCY=.9 LEGENDLABEL='OBESE' ;
YAXIS OFFSETMAX=0;
XAXIS OFFSETMAX=0;
REG X=BMI Y=SIRI_BFPER / NOMARKERS LINEATTRS=(COLOR=BLACK THICKNESS=.01PCT);
KEYLEGEND 'SCAT'/ DOWN=4 TITLE='Siri Rating:' NOBORDER LOCATION=INSIDE POSITION=TOPLEFT;
RUN; FOOTNOTE;
ODS OUTPUT PearsonCorr=ODSCORROUT;
PROC CORR DATA=BODYFAT2 PLOTS(ONLY)=(MATRIX)   NOSIMPLE; *OUT=CORRS;
VAR SIRI_BFPER;
WITH BMI FAT_DENSITY AGE_YEARS WEIGHT_LBS HEIGHT_INCH NECKCIR_CM
CHESTCIR_CM ABDOMENCIR_CM HIPCIR_CM THIGHCIR_CM KNEECIR_CM ANKLECIR_CM
EXTBICIR_CM FOREARMCIR_CM WRISTCIR_CM;
RUN; ODS GRAPHICS OFF;
PROC SORT DATA=ODSCORROUT;
BY SIRI_BFPER;
RUN;
PROC SGPLOT DATA=ODSCORROUT NOAUTOLEGEND;
NEEDLE X=Variable Y=SIRI_BFPER / MARKERATTRS=(COLOR=BLACK SYMBOL=CIRCLEFILLED);
SERIES X=Variable Y=SIRI_BFPER / MARKERS LINEATTRS=(COLOR=WHITE) MARKERATTRS=(SIZE=15 SYMBOL=CIRCLEFILLED);
SERIES X=Variable Y=SIRI_BFPER / MARKERS LINEATTRS=(COLOR=WHITE) MARKERATTRS=(COLOR=WHITE SIZE=10 SYMBOL=CIRCLEFILLED);
YAXIS LABEL='Correllation with Siri body fat percentage' VALUES=(-1 TO 1);
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 3. Correlation with Siri's body fat percent';
RUN; FOOTNOTE;

**********PART 3: Group differences**********;
*using dot plots and CLM bars to see differences;
PROC SGPLOT DATA=BODYFAT2;
DOT PER_HEALTH / RESPONSE=AGE_YEARS STAT=MEAN LIMITSTAT=CLM LIMITATTRS=(COLOR=BLACK THICKNESS=2) MARKERATTRS=(COLOR=BLACK SIZE=13) NAME='DOT';
DOT PER_HEALTH / RESPONSE=AGE_YEARS STAT=MEAN MARKERATTRS=(COLOR=WHITE SIZE=10 SYMBOL=CIRCLEFILLED) NAME='LEAVEoffLEGEND';
YAXIS OFFSETMAX=.2 OFFSETMIN=.2 LABEL='Siri body fat categories';
XAXIS OFFSETMAX=0 OFFSETMIN=0 VALUES=(20 TO 60);
KEYLEGEND 'DOT' / NOBORDER LOCATION=INSIDE POSITION=BOTTOM;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 4. Age comparisons across Siri weight categories';
RUN; FOOTNOTE;
PROC SGPLOT DATA=BODYFAT2;
DOT BMI_HEALTH / RESPONSE=AGE_YEARS STAT=MEAN LIMITSTAT=CLM LIMITATTRS=(COLOR=BLACK THICKNESS=2) MARKERATTRS=(COLOR=BLACK SIZE=13) NAME='DOT';
DOT BMI_HEALTH / RESPONSE=AGE_YEARS STAT=MEAN MARKERATTRS=(COLOR=WHITE SIZE=10 SYMBOL=CIRCLEFILLED) NAME='LEAVEoffLEGEND';
YAXIS OFFSETMAX=.3 OFFSETMIN=.3 LABEL='BMI weight categories';
XAXIS OFFSETMAX=0 OFFSETMIN=0 VALUES=(40 TO 50);
KEYLEGEND 'DOT' / NOBORDER LOCATION=INSIDE POSITION=BOTTOM;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 5. Age comparisons across BMI weight categories';
RUN; FOOTNOTE;

**********PART 4: Predictive power**********;
*simple linear regression of SIRI_BFPER with BMI;
PROC REG DATA=BODYFAT2 PLOTS(ONLY)=(DIAGNOSTICS(STATS=ALL) OBSERVEDBYPREDICTED RSTUDENTBYPREDICTED QQPLOT RESIDUALHISTOGRAM COOKSD RESIDUALS);
MODEL SIRI_BFPER = BMI;
OUTPUT OUT=BMI_REG RESIDUAL=REG_RES PREDICTED=REG_PRED;
RUN; QUIT;
PROC SGPLOT DATA=BMI_REG;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 6. BMI linear regression: Prediction against original';
LOESS X=SIRI_BFPER Y=REG_PRED / DEGREE=1 SMOOTH=.2 MARKERATTRS=(COLOR=BLACK) LINEATTRS=(COLOR=BLACK) ALPHA=.05 CLM  LEGENDLABEL='Model fit (LOESS)' NAME='LINE1';
YAXIS GRID OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Model predicted body fat percentage';
XAXIS GRID OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Actual Siri body fat percentage';
REG X=SIRI_BFPER Y=SIRI_BFPER / NOMARKERS LEGENDLABEL='Perfect fit guide' NAME='LINE2';
KEYLEGEND 'LINE2' 'LINE1' / DOWN=3 NOBORDER LOCATION=INSIDE POSITION=BOTTOMRIGHT;
RUN; FOOTNOTE;
*multiple linear regression of SIRI_BFPER with dimension variables;
PROC REG DATA=BODYFAT2 PLOTS(ONLY)=(DIAGNOSTICS(STATS=ALL) OBSERVEDBYPREDICTED RSTUDENTBYPREDICTED QQPLOT RESIDUALHISTOGRAM COOKSD RESIDUALS);
MODEL SIRI_BFPER = AGE_YEARS /*WEIGHT_LBS*/ NECKCIR_CM CHESTCIR_CM ABDOMENCIR_CM HIPCIR_CM THIGHCIR_CM KNEECIR_CM ANKLECIR_CM
EXTBICIR_CM FOREARMCIR_CM WRISTCIR_CM / SELECTION=STEPWISE TOL VIF CP;
OUTPUT OUT=MULTIVAR_REG RESIDUAL=MREG_RES PREDICTED=MREG_PRED;
RUN; QUIT;
PROC SGPLOT DATA=MULTIVAR_REG;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 7. Multiple regression: Prediction against original';
LOESS X=SIRI_BFPER Y=MREG_PRED / DEGREE=1 SMOOTH=.2  MARKERATTRS=(COLOR=BLACK) LINEATTRS=(COLOR=BLACK) ALPHA=.05 CLM LEGENDLABEL='Model fit (LOESS)' NAME='LINE1';
YAXIS GRID OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Model predicted body fat percentage';
XAXIS GRID OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Actual body fat percentage';
REG X=SIRI_BFPER Y=SIRI_BFPER / NOMARKERS LEGENDLABEL='Perfect fit guide' NAME='LINE2';
KEYLEGEND 'LINE2' 'LINE1' / DOWN=3 NOBORDER LOCATION=INSIDE POSITION=BOTTOMRIGHT;
RUN; FOOTNOTE;
*final plotted comparison of models;
DATA REG_COMPARE;
MERGE BMI_REG MULTIVAR_REG;
BY ID;
RUN;
PROC SGPLOT DATA=REG_COMPARE;
FOOTNOTE JUSTIFY=LEFT ITALIC 'Figure 8. Final model comparison';
REG X=SIRI_BFPER Y=REG_PRED / NOMARKERS LINEATTRS=(COLOR=BLACK) ALPHA=.05 CLM CLMTRANSPARENCY=.5 LEGENDLABEL='BMI Model' NAME='LINE1' NOLEGCLM;
REG X=SIRI_BFPER Y=MREG_PRED / NOMARKERS LINEATTRS=(COLOR=BLACK) ALPHA=.05 CLM CLMTRANSPARENCY=.5 LEGENDLABEL='Mutlivariate Model' NAME='LINE2';
YAXIS OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Model predicted body fat percentage';
XAXIS OFFSETMAX=0 OFFSETMIN=0 VALUES=(5 TO 40 by 5) LABEL='Actual body fat percentage';
KEYLEGEND 'LINE1' 'LINE2' / DOWN=5 NOBORDER LOCATION=INSIDE POSITION=BOTTOMRIGHT;
RUN; FOOTNOTE;
*Closing RTF export so SAS produces the RTF file for write-up;
ODS RTF CLOSE; ODS GRAPHICS OFF;
