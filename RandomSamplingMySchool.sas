OPTIONS NOCENTER PAGESIZE=150 LINESIZE=256  formdlim='-';
DATA SRS;
LENGTH school_type $20;
INPUT school_type $ percap_income langperc_GT20;
LABEL school_type = 'School Type'
percap_income = 'Income Per Student ($)'
langperc_GT20 = 'Greater than 20% non-English Background';
DATALINES;
Catholic264310
Catholic70561
Government 103961
Independent172660
Government 107030
Government76790
Government 124500
Independent189121
Government90761
Catholic71250
Government100451
Government86101
Independent101111
Independent47141
Government 125720
Government120801
Government103460
Catholic155940
Catholic72351
Government 107681
Independent127461
Government79910
Government188380
Catholic70901
Government 128520
Government80731
Catholic62221
Government 96671
;
RUN;
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
ODS RTF FILE='C:\RSMS\MYFILE.rtf' STYLE=Styles.MYWAY1 STARTPAGE=NO;
ODS GRAPHICS ON / RESET border=off HEIGHT=10CM;
PROC SURVEYMEANS DATA=SRS MEAN STDERR CLM;
VAR percap_income langperc_GT20;
RUN;
PROC SURVEYMEANS DATA=SRS MEAN STDERR CLM TOTAL=933;
VAR percap_income langperc_GT20;
RUN;
PROC SURVEYMEANS DATA=SRS MEAN STDERR CLM ALPHA=.1;
VAR percap_income langperc_GT20;
RUN;
PROC SURVEYMEANS DATA=SRS MEAN STDERR CLM ALPHA=.1 TOTAL=933;
VAR percap_income langperc_GT20;
RUN;
PROC SURVEYMEANS DATA=SRS NOBS MEAN STDERR CLM TOTAL=933;
DOMAIN school_type;
VAR percap_income;
ODS OUTPUT DOMAIN(MATCH_ALL)=DOMAIN;
RUN;
PROC SGPLOT DATA=DOMAIN;
YAXIS GRID TYPE=DISCRETE;
YAXIS LABEL='Funding per student ($)' OFFSETMIN=.1 OFFSETMAX=.1;
XAXIS OFFSETMIN=.1 OFFSETMAX=.1;
BAND UPPER=UpperCLMean LOWER=LowerCLMean X=school_type  / TRANSPARENCY=.7 LEGENDLABEL='95% CL' NAME='BAND';
SCATTER Y=Mean x=school_type /   markerattrs=(symbol=circlefilled) Yerrorlower=LowerCLMean Yerrorupper=UpperCLMean;
KEYLEGEND 'BAND' / NOBORDER LOCATION=INSIDE POSITION=TOP;
FOOTNOTE ITALIC JUSTIFY=LEFT 'Sample Average Funding and Estimated Population Funding Range';
RUN; FOOTNOTE;
ODS RTF CLOSE; ODS GRAPHICS OFF;
