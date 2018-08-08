LIBNAME EXAM 'C:\Users\liethomp\SASLIBRARY'; RUN;

PROC IMPORT 
	DATAFILE = 'C:\Users\liethomp\SASFILEEXAM\Intervention A.xls'
	OUT= EXAM.InterventionA
	DBMS= xls REPLACE;
	getnames=YES;
	sheet='A';
PROC IMPORT 
	DATAFILE = 'C:\Users\liethomp\SASFILEEXAM\Intervention B.xls'
	OUT= EXAM.InterventionB
	DBMS= xls REPLACE;
	getnames=YES;
	sheet='B';
PROC IMPORT 
	DATAFILE = 'C:\Users\liethomp\SASFILEEXAM\Diagnosis.xlsx'
	OUT= EXAM.DIAGNOSIS
	DBMS= xlsx REPLACE;
	getnames=YES;
	sheet='Diagnosis';
PROC IMPORT 
	DATAFILE = 'C:\Users\liethomp\SASFILEEXAM\Patient.xls'
	OUT= EXAM.PATIENT
	DBMS= xls REPLACE;
	getnames=YES;
	sheet='Patient';

DATA A; SET EXAM.InterventionA; 
OPTIONS LS = 120;
PROC SORT; BY ID;
RUN;

/*A has duplicates so remove them*/
PROC SORT DATA=A
	OUT=ANODUP
	NODUPKEY;
	BY ID;
RUN;

DATA ANODUP;
SET ANODUP; 
InterventionA = 'Y'; 
RUN;

DATA B; SET EXAM.InterventionB; 
OPTIONS LS = 120;
InterventionB = 'Y'; 
PROC SORT; BY ID;
RUN;

/*clean up diagnosis file*/
DATA DIAGNOSIS; SET EXAM.DIAGNOSIS; 
OPTIONS LS = 120;
IF DX IN('A02.1','A22.7','A26.7','A32.7','A40.0','A40.1','A40.3','A40.8','A40.9','A41.01','A41.02','A41.1','A41.2','A41.3','A41.4', 'A41.50', 'A41.51', 'A41.52',
'A41.53','A41.59', 'A41.81', 'A41.89','A41.9', 'A42.7', 'A54.86', 'B37.7', 'O03.37','O03.87', 'O04.87','O07.37','O08.82','O85','P36.0','P36.10', 'P36.19','P36.2', 'P36.30',
'P36.39','P36.4','P36.5','P36.8','P36.9', 'R65.20','R65.21') then sepsis = 'Y'; else sepsis='N';
/*remove duplicates from Diagnosis file*/
PROC SORT DATA=DIAGNOSIS
	OUT=DIAGNOSIS2
	NODUPKEY;
	BY ID SEPSIS;
RUN;

/*remove observations with duplicate IDs*/
data diagnosisnoduplicates;
set DIAGNOSIS2; by id sepsis;
if last.id; 
run;

DATA PATIENT ; SET EXAM.PATIENT; /*no duplicate IDs in this dataset*/
	OPTIONS LS = 120;
	/*delete patients discharged pre-12/01/2016 */
	if (DISCHARGE) < input('12/01/2016',mmddyy10.)
	then delete; 
	/*create outcome variables:*/
	If STATUS IN ('DEAD','dEATH','deceased','DIED','Died','Expire','Expired','Dead') then STATUS = 'DEAD';
	else STATUS='ALIVE';
	LengthOfStay=DISCHARGE-ADMIT;
PROC SORT; BY ID;
RUN;

/*merge patient diagnosis*/
DATA PATIENTDIAGNOSISNODUP; MERGE PATIENT DIAGNOSISNODUPLICATES; BY ID;
if DISCHARGE=' ' then delete;
RUN;

/*create InterventionA group */
DATA AMERGE; MERGE ANODUP PATIENTDIAGNOSISNODUP; BY ID;
If InterventionA not = 'Y' then delete;
RUN;

/*create control group by subtracting IDs in A/B from all IDs*/
DATA AB; MERGE ANODUP B; BY ID;
Intervention = 'Y'; 
run;

data NON_INTERVENTION; merge AB PATIENTDIAGNOSISNODUP; BY ID;
if Intervention ='Y' then delete; 
run;

/*Combine comparison groups*/
data FINALDATA; set AMERGE NON_INTERVENTION;
If InterventionA ='Y' then Intervention='Y';
else Intervention='N';
proc sort; by id;

/*Compare Length of Stay Outcome:*/
Proc NPar1way data=FINALDATA wilcoxon;
	class Intervention;
	var LengthOfStay;

/*Compare STATUS Outcome: */
Proc Freq; tables Intervention*STATUS; 
run;
*/
