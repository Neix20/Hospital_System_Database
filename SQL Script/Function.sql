/*1. Determine If Staff is Junior Employee or Senior Employee (XP) */
CREATE OR REPLACE FUNCTION DETERMINE_STAFF_EXPERIENCE(current_stf_id IN varchar2)
RETURN varchar2
IS
staff_experience_txt varchar2(100);
hire_date date;
BEGIN
SELECT staff_hireDate INTO hire_date
FROM staff
WHERE staff_id = current_stf_id;
IF trunc((sysdate - hire_date) / 365.25) >= 3 THEN
staff_experience_txt := 'This Staff has more than 3 years experience and is a Senior Employee.';
ELSE
staff_experience_txt := 'This Staff has less than 3 years experience and is a Junior Employee.';
END IF;
RETURN staff_experience_txt;
END;

EXECUTE DBMS_OUTPUT.PUT_LINE(DETERMINE_STAFF_EXPERIENCE('S1015'));
EXECUTE DBMS_OUTPUT.PUT_LINE(DETERMINE_STAFF_EXPERIENCE('S1013'));
/*2. Consultation_Date_Info (XP) */
CREATE OR REPLACE FUNCTION GET_CONSULTATION_INFO(current_c_id IN varchar2)
RETURN varchar2
IS
consultation_info_txt varchar2(100);
BEGIN
select
    'Doctor Name: Dr.' || d.staff_lname || chr(10) || 'Patient Name: ' || p.patient_fname || ' ' || p.patient_lname || chr(10) || 'Date: ' || to_char(
        cast(cs.consultation_startDatetime as date),
        'DD-MM-YYYY'
    ) || chr(10) || 'Time: ' || to_char(cs.consultation_startDatetime, 'HH24:MI:SS') 
    INTO consultation_info_txt
from
    staff d,
    patient p,
    consultation cs
where
    d.staff_id = cs.staff_id
    and p.patient_id = cs.patient_id
    and cs.consultation_id = current_c_id;
RETURN consultation_info_txt;
END;

EXECUTE DBMS_OUTPUT.PUT_LINE(GET_CONSULTATION_INFO('C1001'));
/*3. Get Total Number of Staff Based on Department (XP) */
CREATE OR REPLACE FUNCTION GET_NUMBER_OF_EMPLOYEES(dept_name IN varchar2)
RETURN NUMBER
IS
num_of_stf NUMBER;
BEGIN
select count(staff_position) INTO num_of_stf
from staff
where staff_position = dept_name
group by staff_position;
RETURN num_of_stf;
END;

EXECUTE DBMS_OUTPUT.PUT_LINE(GET_NUMBER_OF_EMPLOYEES('Doctor'));

/*4. Get Total Working Hours of Staff (XP) */
CREATE OR REPLACE FUNCTION GET_WORKING_HOURS(current_stf_id IN varchar2)
RETURN NUMBER
IS
working_hour NUMBER;
BEGIN
select trunc((sysdate - staff_hireDate) / 7 * 5) * 8 "Total Working Hours" INTO working_hour
from staff
where staff_id = current_stf_id;
RETURN working_hour;
END;
/
 
EXECUTE DBMS_OUTPUT.PUT_LINE(GET_WORKING_HOURS('S1001'));

/*5. Get Total Expenses by Department So Far (XP) */
CREATE OR REPLACE FUNCTION GET_TOTAL_EXPENSES(dept_id IN varchar2)
RETURN NUMBER
IS
total_expenses NUMBER;
BEGIN
select sum(trunc((sysdate - staff_hireDate) / 30) * staff_salary) INTO total_expenses
from staff
where department_id = dept_id
group by department_id;
return total_expenses;
END;

EXECUTE DBMS_OUTPUT.PUT_LINE(GET_TOTAL_EXPENSES('D1002'));

/*6. Get Total Cost of Each Service with Facility */
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

/*7. Get New Salary based on hourly rates */
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
/*8. Report_Date_Info */
CREATE OR REPLACE FUNCTION GET_REPORT_INFO(p_id IN varchar2) 
RETURN VARCHAR2 
IS 
result_info_txt VARCHAR2(255);
BEGIN
Select
    'Report ID: ' || r.report_id || chr(10) || 'Patient Name: ' || p.patient_fname || ' ' || p.patient_lname || chr(10) || 'Doctor In Charge: Dr. ' || s.staff_lname || chr(10) || 'Consultation Date: ' || to_char(
        cast(cs.consultation_startDatetime as date),
        'DD-MM-YYYY'
    ) || chr(10) || 'Medical Disease: ' || r.medical_disease || chr(10) || 'Service Used: ' || ser.service_name || chr(10) || 'Medicine Prescribed: ' || m.medicine_name || chr(10) || 'Medicine Quantity: ' || md.patMed_quantity || chr(10) || 'Medicine Dosage: ' || m.medicine_dosage INTO result_info_txt
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

/*9. Total Hours Used by Service */
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
/*10. Get Total Cost of Medicine with Quantity */
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