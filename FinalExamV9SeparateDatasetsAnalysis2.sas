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

DATA B; SET EXAM.InterventionB; 
OPTIONS LS = 120;
PROC SORT; BY ID;
RUN;

DATA DIAGNOSIS; SET EXAM.DIAGNOSIS; 
OPTIONS LS = 120;

IF DX IN('A02.1','A22.7','A26.7','A32.7','A40.0','A40.1','A40.3','A40.8','A40.9','A41.01','A41.02','A41.1','A41.2','A41.3','A41.4', 'A41.50', 'A41.51', 'A41.52',
'A41.53','A41.59', 'A41.81', 'A41.89','A41.9', 'A42.7', 'A54.86', 'B37.7', 'O03.37','O03.87', 'O04.87','O07.37','O08.82','O85','P36.0','P36.10', 'P36.19','P36.2', 'P36.30',
'P36.39','P36.4','P36.5','P36.8','P36.9', 'R65.20','R65.21') then sepsis = 'Y'; else sepsis='N';

PROC SORT DATA=DIAGNOSIS
	OUT=DIAGNOSIS2
	NODUPKEY;
	BY ID SEPSIS;
RUN;

data diagnosisnoduplicates;
set DIAGNOSIS2; by id sepsis;
if last.id; 
run;

DATA PATIENT ; SET EXAM.PATIENT; 
OPTIONS LS = 120;

/*create outcome variables:*/
If STATUS IN ('DEAD','dEATH','deceased','DIED','Died','Expire','Expired','Dead') then STATUS = 'DEAD';
else STATUS='ALIVE';

/*check variable formats: 
	proc contents data=PATIENT out=PATIENT2; 
	proc print data=PATIENT2; 
*/

LengthOfStay=DISCHARGE-ADMIT;

PROC SORT; BY ID;
RUN;

DATA A;
SET A; 
InterventionType = 'A'; 
RUN;

DATA B; 
SET B; 
InterventionType = 'B'; 
RUN;

/*merge patient diagnosis*/
DATA PATIENTDIAGNOSISNODUP; MERGE PATIENT DIAGNOSISNODUPLICATES; BY ID;
RUN;

DATA BMERGE; MERGE B PATIENTDIAGNOSISNODUP; BY ID;

IF DX not IN('A02.1','A22.7','A26.7','A32.7','A40.0','A40.1','A40.3','A40.8','A40.9','A41.01','A41.02','A41.1','A41.2','A41.3','A41.4', 'A41.50', 'A41.51', 'A41.52',
'A41.53','A41.59', 'A41.81', 'A41.89','A41.9', 'A42.7', 'A54.86', 'B37.7', 'O03.37','O03.87', 'O04.87','O07.37','O08.82','O85','P36.0','P36.10', 'P36.19','P36.2', 'P36.30',
'P36.39','P36.4','P36.5','P36.8','P36.9', 'R65.20','R65.21') then sepsis = 'Y'; else sepsis='N';

/*delete patients discharged pre-12/01/2016 */
if (DISCHARGE) < input('12/01/2016',mmddyy10.)
then delete;

If InterventionType not = 'B' then delete;
RUN;

/*create non-intervention group by merging all datasets: */

DATA AB; MERGE A B; BY ID;
Intervention = 'Y'; 
run;

data NON_INTERVENTION; merge AB PATIENTDIAGNOSISNODUP; BY ID;
if intervention ='Y' then delete; 
run;

/*Compare Bmerge to Non-Intervention*/
data Bmerge; set BMERGE NON_INTERVENTION;
If InterventionType =' ' then InterventionType='N';
proc sort; by id;
run;

/*Compare Length of Stay Outcome:*/
Proc NPar1way data=BMerge wilcoxon;
	class InterventionType;
	var LengthOfStay;
run;
 
/*Compare STATUS Outcome (must transform STATUS to numeric format 1st): */
Proc Freq; tables InterventionType*STATUS; 
run;
