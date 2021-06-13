SET pagesize 70
SET linesize 200
SET severoutput ON

/*Slect Like Statemet*/
select
    staff_id "ID",
    staff_lname || ' ' || staff_fname "Name",
    staff_position "Job Title"
from
    staff
where
    staff_position in ('Doctor', 'Nurse', 'Admission Staff');

/*Select Staff with less than 3 years experience*/
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

/*Select Staff with more than or equals to 3 years experience*/
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
    AND TRUNC((sysdate - staff_hiredate) / 365.25) >= 3;

/*Select Consultation based on Same Month (XP)*/
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
    AND TO_CHAR(consultation_startdatetime, 'Mon') = 'Feb'
ORDER BY
    cs.consultation_startdatetime;
    
/*Select Consultation based on Week of the day*/
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

/*Group Functions*/
/*1. Total Expenses by Each Department - Sum Function of Staff in Department*/

col "List of Doctors" format a60 
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

/*3.Number of Times Service Is Used, Left Join */
SELECT
    s.service_id "ID",
    s.service_name "Name",
    tmp.num_of_times "Number of Times Used",
    'RM ' || TO_CHAR(tmp.num_of_times * s.service_charge, '9,999.99') "Total Expenses Earned"
FROM
    service s,
    (
        SELECT
            s.service_id,
            COUNT(r.service_id) num_of_times
        FROM
            service s,
            report r
        WHERE
            s.service_id = R.SERVICE_ID(+)
        GROUP BY
            s.service_id
    ) tmp
WHERE
    tmp.service_id = s.service_id
ORDER BY
    1;
    
/*4. Get Patient Count from Doctor */
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
    
/*5.Total Number of facilities each floor have */
col "Floor Plan" format a30
SELECT
    facility_floor "Floor Number",
    LISTAGG(facility_name, ', ') WITHIN GROUP (
        ORDER BY
            facility_name
    ) "Floor Plan"
FROM
    facility
GROUP BY
    facility_floor;
    
/*6.Group Consultation Based on Date */
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

/*7. Group Consultation Based on Month */
col "Month Consultation" format a20 
col "Consultations" format a40
SELECT
    TRIM(
        TO_CHAR(
            CAST(consultation_startdatetime AS DATE),
            'Month'
        )
    ) "Month Consultation",
    LISTAGG(consultation_id, ', ') WITHIN GROUP (
        ORDER BY
            consultation_id
    ) "Consultations",
    COUNT(
        TRIM(
            TO_CHAR(
                CAST(consultation_startdatetime AS DATE),
                'Month'
            )
        )
    ) "Number of Consultation"
FROM
    consultation
GROUP BY
    TRIM(
        TO_CHAR(
            CAST(consultation_startdatetime AS DATE),
            'Month'
        )
    );

/*8. Group Staff by Birthday Month*/
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
    
/*Views 
1. View With Check option for inserting Doctor based on Department */
DROP VIEW doctor_view;
CREATE OR replace VIEW doctor_view AS
SELECT
    *
FROM
    staff
WHERE
    staff_position = 'Doctor' 
WITH CHECK OPTION;
    
/*Debugging*/
INSERT INTO
    doctor_view
VALUES
    (
        'S1016',
        'Ying Qian 23',
        'Kang234',
        '900224-08-3434',
        TO_DATE('02/24/1990', 'MM/DD/YYYY'),
        'Female',
        '0124567833',
        'yqian@gmail.com',
        TO_DATE('12/31/2020', 'MM/DD/YYYY'),
        'Nurse',
        '26, Taman Baru',
        'Parit Buntar',
        34200,
        'Perak',
        'Malaysia',
        4500.00,
        'D1001'
    );
INSERT INTO
    nurse_view
VALUES
    (
        'S1016', 'Ying Qian 23', 'Kang234', '900224-08-3434',
        TO_DATE('02/24/1990', 'MM/DD/YYYY'), 'Female', '0124567833', 'yqian@gmail.com',
        TO_DATE('12/31/2020', 'MM/DD/YYYY'), 'Nurse', '26, Taman Baru', 'Parit Buntar',
        34200, 'Perak', 'Malaysia', 4500.00, 'D1001'
    );
INSERT INTO
    doctor_view
VALUES
    (
        'S1017',
        'Ying Qian 23234',
        'Kang234234',
        '900224-08-3434',
        TO_DATE('02/24/1990', 'MM/DD/YYYY'),
        'Female',
        '0124567833',
        'yqian@gmail.com',
        TO_DATE('12/31/2020', 'MM/DD/YYYY'),
        'Doctor',
        '26, Taman Baru',
        'Parit Buntar',
        34200,
        'Perak',
        'Malaysia',
        4500.00,
        'D1003'
    );
INSERT INTO
    nurse_view
VALUES
    (
        'S1017', 'Ying Qian 23234', 'Kang234234', '900224-08-3434',
        TO_DATE('02/24/1990', 'MM/DD/YYYY'), 'Female', '0124567833', 'yqian@gmail.com',
        TO_DATE('12/31/2020', 'MM/DD/YYYY'), 'Doctor', '26, Taman Baru', 'Parit Buntar',
        34200, 'Perak', 'Malaysia', 4500.00, 'D1003'
    );
    
/*2.View With Check Option for inserting Nurse based on Department */

DROP VIEW nurse_view;
CREATE OR replace VIEW nurse_view AS
SELECT
    *
FROM
    staff
WHERE
    staff_position = 'Nurse' 
WITH CHECK OPTION;
    
/*3.View To Link Patient, Medical Report, Medicine and Medicine_Distribution */
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
    
/*4.View To Link Patient, Medical Report, Service and Facility */
CREATE OR replace VIEW patient_service_view AS
SELECT
    p.patient_lname || ' ' || p.patient_fname "Name",
    r.medical_disease "Illness",
    s.service_name "Service Name",
    f.facility_name "Facility Name"
FROM
    patient p,
    consultation cs,
    report r,
    medicine_distribution md,
    service s,
    facility f
WHERE
    p.patient_id = cs.patient_id
    AND cs.consultation_id = r.consultation_id
    AND r.report_id = md.report_id
    AND s.service_id = r.service_id
    AND f.facility_id = s.facility_id WITH READ only;
    
/*5.View to Link Staff, Doctor, Consultation, Medical Report and Patient */
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
    
/*6.View To Link Facility,Service, Medicine and Medical Report */
CREATE OR replace VIEW disease_treatment_view AS
SELECT
    r.medical_disease "Disease",
    s.service_name "Service",
    f.facility_name "Facility",
    m.medicine_name "Medicine",
    'RM' || TO_CHAR(
        m.medicine_unitprice + s.service_charge,
        '999.99'
    ) "Fee"
FROM
    report r,
    service s,
    facility f,
    medicine_distribution md,
    medicine m
WHERE
    r.report_id = md.report_id
    AND m.medicine_id = md.medicine_id
    AND s.service_id = r.service_id
    AND f.facility_id = s.facility_id 
WITH READ only;

SELECT
    *
FROM
    disease_treatment_view;