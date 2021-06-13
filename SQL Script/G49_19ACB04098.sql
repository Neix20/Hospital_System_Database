/*
INDIVIDUAL ASSIGNMENT SUBMISSION
GROUP NUMBER : 49
PROGRAMME : CS
STUDENT ID : 1904098
STUDENT NAME : Tan Xi En
Submission date and time: 27-03-2021 7.55P.M.
*/

SET pagesize 70
SET linesize 200
SET serveroutput ON

/* Query 1 */
select
    staff_id "ID",
    staff_lname || ' ' || staff_fname "Name",
    staff_position "Job Title"
from
    staff
where
    staff_position in ('Doctor', 'Nurse', 'Admission Staff');

/* Query 2 */
SELECT
    s.staff_id "ID",
    s.staff_lname || ' ' || s.staff_fname "Name",
    s.staff_position "Job Title",
    s.staff_salary "Salary",
    d.department_name "Department"
FROM
    staff s,
    department d
WHERE
    s.department_id = d.department_id
    AND TRUNC((sysdate - staff_hiredate) / 365.25) < 3;

/* Query 3 */
SELECT
    s.staff_lname || ' ' || s.staff_fname "Doctor",
    p.patient_lname || ' ' || p.patient_fname "Patient",
    TO_CHAR(
        CAST(cs.consultation_startdatetime AS DATE),
        'DD/MM/YYYY'
    ) "Date",
    TO_CHAR(cs.consultation_startdatetime, 'HH24:MI:SS') "Start",
    TO_CHAR(cs.consultation_enddatetime, 'HH24:MI:SS') "End",
    r.medical_disease "Illness"
FROM
    consultation cs,
    staff s,
    patient p,
    report r
WHERE
    s.staff_id = cs.staff_id
    AND cs.patient_id = p.patient_id
    AND cs.consultation_id = r.consultation_id
    AND TRIM(
        TO_CHAR(
            CAST(cs.consultation_startdatetime AS DATE),
            'DAY'
        )
    ) = UPPER('tuesday')
ORDER BY
    cs.consultation_startdatetime;

/* Query 4 */
col "List of Doctors" format a80 
col "Total Expenses" format a20
SELECT
    department.department_id "ID",
    department.department_name "Name",
    tmp.num_of_employees "Number of employees",
    tmp.names "List of Doctors",
    'RM' || ' ' || tmp.total_expenses "Total Expenses"
FROM
    department,
    (
        SELECT
            department_id,
            TO_CHAR(SUM(staff_salary), '999,999.99') total_expenses,
            COUNT(department_id) num_of_employees,
            LISTAGG(staff_lname || ' ' || staff_fname, ', ') WITHIN GROUP (
                ORDER BY
                    staff_lname
            ) names
        FROM
            staff
        GROUP BY
            department_id
    ) tmp
WHERE
    tmp.department_id = department.department_id;

/* Query 5 */
CREATE OR replace VIEW nurse_view AS
SELECT
    *
FROM
    staff
WHERE
    staff_position = 'Nurse' 
WITH CHECK OPTION;

SELECT
    *
FROM
    nurse_view;

/*Debugging*/
/*This is Allowed*/
INSERT INTO
    nurse_view
VALUES
    (
        'S1016', 'Ying Qian 23', 'Kang234', '900224-08-3434',
        TO_DATE('02/24/1990', 'MM/DD/YYYY'), 'Female', '0124567833', 'yqian@gmail.com',
        TO_DATE('12/31/2020', 'MM/DD/YYYY'), 'Nurse', '26, Taman Baru', 'Parit Buntar',
        34200, 'Perak', 'Malaysia', 4500.00, 'D1001'
    );
rollback;

/* Query 6 */
CREATE OR replace VIEW patient_medicine_view AS
SELECT
    p.patient_lname || ' ' || p.patient_fname "Name",
    r.medical_disease "Illness",
    m.medicine_name "Medicine Name",
    md.patmed_quantity "Quantity",
    'RM ' || TO_CHAR(
        md.patmed_quantity * m.medicine_unitprice,
        '9,999.99'
    ) "Medicine Fee"
FROM
    patient p,
    consultation cs,
    report r,
    medicine_distribution md,
    medicine m
WHERE
    p.patient_id = cs.patient_id
    AND cs.consultation_id = r.consultation_id
    AND r.report_id = md.report_id
    AND md.medicine_id = m.medicine_id 
WITH READ only;

SELECT
    *
FROM
    patient_medicine_view;

/* Query 7 */
CREATE OR replace VIEW doctor_patient_view AS
SELECT
    p.patient_lname || ' ' || p.patient_fname patient_name,
    s.staff_lname || ' ' || s.staff_fname doctor_name,
    d.doctor_specialty job_specific,
    r.medical_disease illness
FROM
    staff s,
    doctor d,
    consultation cs,
    report r,
    patient p
WHERE
    s.staff_id = d.staff_id
    AND d.staff_id = cs.staff_id
    AND cs.patient_id = p.patient_id
    AND r.consultation_id = cs.consultation_id 
WITH READ only;

SELECT
    *
FROM
    doctor_patient_view;

/* Query 8 */
col "Patients" format a50
SELECT
    tmp.doctor_name "Doctor Name",
    LISTAGG(patient_name, ', ') WITHIN GROUP (
        ORDER BY
            patient_name
    ) "Patients",
    COUNT(patient_name) "Number of Patients"
FROM
    doctor_patient_view tmp
GROUP BY
    tmp.doctor_name;

/* Query 9 */
col "Date Consultation" format a20 
col "Consultations" format a30
SELECT
    TRUNC(CAST(consultation_startdatetime AS DATE)) "Date Consultation",
    LISTAGG(consultation_id, ', ') WITHIN GROUP (
        ORDER BY
            consultation_id
    ) "Consultations",
    COUNT(TRUNC(CAST(consultation_startdatetime AS DATE))) "Number of Consultation"
FROM
    consultation
GROUP BY
    TRUNC(CAST(consultation_startdatetime AS DATE))
ORDER BY
    1;

/* Query 10 */
col "Name" format a50;
SELECT
    TRIM(to_char(staff_dob, 'Month')) birthday,
    LISTAGG(staff_lname || ' ' || staff_fname, ', ') WITHIN GROUP (
        ORDER BY
            staff_lname
    ) "Name"
FROM
    staff
GROUP BY
    trim(to_char(staff_dob, 'Month'))
ORDER BY
    to_char(to_date(birthday, 'Month'), 'mm');

/* Stored Procedure 1 */
CREATE OR REPLACE PROCEDURE DELETE_STAFF(
    current_s_id IN varchar2
) IS BEGIN
DELETE FROM
    staff
WHERE
    staff_id = current_s_id;
END;
/
EXECUTE DELETE_STAFF('S1013');
rollback;

/* Stored Procedure 2 */
CREATE OR REPLACE PROCEDURE DELETE_DEPARTMENT(
    current_dept_name IN varchar2
) AS BEGIN 
FOR staff_ptr IN (
    SELECT
        s.staff_id
    FROM
        staff s,
        department d
    WHERE
        s.department_id = d.department_id
        AND d.department_name = current_dept_name
) loop DELETE_STAFF(staff_ptr.staff_id);END loop;
DELETE FROM
    department
WHERE
    department_name = current_dept_name;
END;
/
EXECUTE DELETE_DEPARTMENT('Admission');
rollback;

/* Stored Procedure 3 */
CREATE OR REPLACE PROCEDURE GIVE_BONUS_STAFF(
    current_s_id IN varchar2,
    bonus_salary IN decimal
) IS BEGIN
UPDATE
    staff
SET
    staff_salary = staff_salary + bonus_salary
WHERE
    staff_id = current_s_id;
END;
/
EXECUTE GIVE_BONUS_STAFF('S1013', 500.00);
rollback;

/* Stored Procedure 4 */
CREATE OR REPLACE PROCEDURE GIVE_BONUS_DEPARTMENT(
    current_dept_name IN varchar2,
    bonus_salary IN decimal
) AS BEGIN FOR staff_ptr IN (
    SELECT
        s.staff_id
    FROM
        staff s,
        department d
    WHERE
        s.department_id = d.department_id
        AND d.department_name = current_dept_name
) 
loop 
GIVE_BONUS_STAFF(staff_ptr.staff_id, bonus_salary);
END loop;
END;
/
EXECUTE GIVE_BONUS_DEPARTMENT('Admission', 500.00);
rollback;

/* Stored Procedure 5 */
CREATE OR REPLACE PROCEDURE INSERT_STAFF(
    stf_fname IN VARCHAR2,
    stf_lname IN VARCHAR2,
    stf_ssn IN VARCHAR2,
    stf_dob IN VARCHAR2,
    stf_gender IN VARCHAR2,
    stf_phoneNo IN VARCHAR2,
    stf_email IN VARCHAR2,
    stf_position IN VARCHAR2,
    address IN VARCHAR2
) IS 
addressline VARCHAR2(100);
city VARCHAR2(100);
postcode VARCHAR2(100);
state VARCHAR2(100);
country VARCHAR2(100);
salary DECIMAL;
dept_id VARCHAR2(100);
BEGIN
SELECT regexp_substr(
    address, 
    '[^,]+', 
    1
) INTO addressline 
FROM dual;
SELECT regexp_substr(
    substr(address, LENGTH(addressline) + 3), 
    '[^,]+', 
    1
) INTO city 
FROM dual;
SELECT regexp_substr(
    substr(address, LENGTH(addressline) + LENGTH(city) + 3), 
    '[^,]+', 
    1
) INTO postcode 
FROM dual;
SELECT regexp_substr(
    substr(address, LENGTH(addressline) + LENGTH(city) + LENGTH(postcode) + 6), 
    '[^,]+', 
    1
) INTO state 
FROM dual;
SELECT substr(
    address, 
    LENGTH(addressline) + LENGTH(city) + LENGTH(postcode) + LENGTH(state) + 8
) INTO country 
FROM dual;
IF stf_position = 'Doctor' THEN
    salary := 3000;
    dept_id := 'D1003';
ELSIF stf_position = 'Nurse' THEN
    salary := 1500;
    dept_id := 'D1001';
ELSIF stf_position = 'Pharmacist' THEN
    salary := 2300;
    dept_id := 'D1002';
ELSIF stf_position = 'Finance Staff' THEN
    salary := 2325;
    dept_id := 'D1004';
ELSE
    salary := 1600;
    dept_id := 'D1005';
END IF;
INSERT INTO Staff 
values (
    'S' || staff_idseq.nextval, stf_fname, stf_lname, stf_ssn, 
    to_date(stf_dob,'MM/DD/YYYY'), stf_gender, stf_phoneNo, stf_email, 
    sysdate, stf_position, addressline, city, 
    to_number(postcode), state, country, salary, dept_id
);
END;
/
EXECUTE INSERT_STAFF('Justin', 'Tan', '000818-14-0799', '08/18/2000', 'Male', '0166489466', 'txen2000@gmail.com', 'Doctor', 'No.12 Jalan Tasik Damai 6, Sungai Besi, 57100, Kuala Lumpur, Malaysia');
rollback;

/* Function 1 */
CREATE OR REPLACE FUNCTION CALC_FAC_EXPENSES(
    fac_id IN varchar2, 
    quantity IN NUMBER
) 
RETURN NUMBER 
IS total_expenses NUMBER;
BEGIN
select
    ser.service_charge INTO total_expenses
from
    service ser,
    facility fac
where
    ser.facility_id = fac.facility_id
    AND ser.facility_id = fac_id;
total_expenses := total_expenses * quantity;
return total_expenses;
END;
/
EXECUTE DBMS_OUTPUT.PUT_LINE(CALC_FAC_EXPENSES('F1001', 3));

/* Function 2 */
CREATE OR REPLACE FUNCTION CALC_SALARY_HOUR_RATES(
    stf_id IN varchar2, 
    rates IN DECIMAL
) 
RETURN DECIMAL 
IS 
final_salary DECIMAL;
BEGIN
select round((staff_salary / 28 / 8), 2) into final_salary
from staff
where staff_id = stf_id;
final_salary := final_salary * (1 + rates) * 8 * 28;
return final_salary;
END;
/
EXECUTE DBMS_OUTPUT.PUT_LINE(CALC_SALARY_HOUR_RATES('S1002', 0.12));

/* Function 3 */
CREATE OR REPLACE FUNCTION GET_REPORT_INFO(
    p_id IN varchar2
) 
RETURN VARCHAR2 
IS 
result_info_txt VARCHAR2(255);
BEGIN
Select
    'Report ID: ' || r.report_id || chr(10) 
    || 'Patient Name: ' || p.patient_fname || ' ' || p.patient_lname || chr(10) 
    || 'Doctor In Charge: Dr. ' || s.staff_lname || chr(10) 
    || 'Consultation Date: ' || to_char(
        cast(cs.consultation_startDatetime as date),
        'DD-MM-YYYY'
    ) || chr(10) 
    || 'Medical Disease: ' || r.medical_disease || chr(10) 
    || 'Service Used: ' || ser.service_name || chr(10) 
    || 'Medicine Prescribed: ' || m.medicine_name || chr(10) 
    || 'Medicine Quantity: ' || md.patMed_quantity || chr(10) 
    || 'Medicine Dosage: ' || m.medicine_dosage 
INTO result_info_txt
from
    staff s,
    report r,
    patient p,
    consultation cs,
    service ser,
    medicine m,
    Medicine_Distribution md
where
    s.staff_id = cs.staff_id
    and p.patient_id = cs.patient_id
    and r.consultation_id = cs.consultation_id
    and r.service_id = ser.service_id
    and r.report_id = md.report_id
    and md.medicine_id = m.medicine_id
    and p.patient_id = p_id;
return result_info_txt;
END;
/
EXECUTE DBMS_OUTPUT.PUT_LINE(GET_REPORT_INFO('P1002'));

/* Function 4 */
CREATE OR REPLACE FUNCTION CALC_TOTAL_HOURS_SERVICE(
    ser_id IN varchar2
) 
RETURN DECIMAL
IS 
total_hours DECIMAL(8,2);
BEGIN
select
    SUM(
        round(
            (
                EXTRACT(
                    MINUTE
                    FROM
                        cs.consultation_endDatetime - cs.consultation_startDatetime
                ) + EXTRACT(
                    HOUR
                    FROM
                        cs.consultation_endDatetime - cs.consultation_startDatetime
                ) * 60
            ) / 60,
            2
        )
    ) INTO total_hours
from
    service ser,
    consultation cs,
    report r
where
    ser.service_id = r.service_id
    and cs.consultation_id = r.consultation_id
    and ser.service_id = ser_id
group by
    ser.service_id;
return total_hours;
END;
/
EXECUTE DBMS_OUTPUT.PUT_LINE(CALC_TOTAL_HOURS_SERVICE('SE1002'));

/* Function 5 */
CREATE OR REPLACE FUNCTION CALC_TOTAL_MEDICINE_EXPENSES(
    med_id IN varchar2,
    quantity IN NUMBER
) 
RETURN DECIMAL 
IS 
total_expenses DECIMAL;
BEGIN
select medicine_Unitprice INTO total_expenses
from medicine
where medicine_id = med_id;
total_expenses := total_expenses * quantity;
return total_expenses;
END;
/
EXECUTE DBMS_OUTPUT.PUT_LINE(CALC_TOTAL_MEDICINE_EXPENSES('M1002', 23));