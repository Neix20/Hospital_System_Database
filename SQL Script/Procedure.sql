/*1. Delete Staff based on staff id */
CREATE OR REPLACE PROCEDURE DELETE_STAFF(current_s_id IN varchar2) IS BEGIN
DELETE FROM
    staff
WHERE
    staff_id = current_s_id;
END;

/*2. Delete Department (and all staff!) */
CREATE OR REPLACE PROCEDURE DELETE_DEPARTMENT(current_dept_name IN varchar2) AS BEGIN 
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

/*3. Update Staff Salary (Bonus!) */
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

/*4. Update Department (and All Staff) */
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
) loop GIVE_BONUS_STAFF(staff_ptr.staff_id, bonus_salary);END loop;
END;

/*5. Delete Medicine Distribution */
CREATE OR REPLACE PROCEDURE DELETE_MEDICINE_DISTRIBUTION(
    current_med_id IN varchar2,
    current_rept_id IN varchar2
) IS BEGIN
DELETE FROM
    Medicine_Distribution
WHERE
    report_id = current_rept_id
    AND medicine_id = current_med_id;
END;

/*6. Delete Medicine */
CREATE OR REPLACE PROCEDURE DELETE_MEDICINE(current_med_id IN varchar2) IS BEGIN
DELETE FROM
    Medicine_Distribution
WHERE
    medicine_id = current_med_id;
DELETE FROM
    Medicine
WHERE
    medicine_id = current_med_id;
END;

/*7. Insert Staff */
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
SELECT regexp_substr(address, '[^,]+', 1) INTO addressline FROM dual;
SELECT regexp_substr(substr(address, LENGTH(addressline) + 3), '[^,]+', 1) INTO city FROM dual;
SELECT regexp_substr(substr(address, LENGTH(addressline) + LENGTH(city) + 3), '[^,]+', 1) INTO postcode FROM dual;
SELECT regexp_substr(substr(address, LENGTH(addressline) + LENGTH(city) + LENGTH(postcode) + 6), '[^,]+', 1) INTO state FROM dual;
SELECT substr(address, LENGTH(addressline) + LENGTH(city) + LENGTH(postcode) + LENGTH(state) + 8) INTO country FROM dual;
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
INSERT INTO Staff values ('S' || staff_idseq.nextval, stf_fname, stf_lname, stf_ssn, to_date(stf_dob,'MM/DD/YYYY'), stf_gender, stf_phoneNo, stf_email, sysdate, stf_position, addressline, city, to_number(postcode), state, country, salary, dept_id);
END;

/*8. Insert Medicine (Write Sequence) */
CREATE OR REPLACE PROCEDURE INSERT_MEDICINE(
    med_name IN VARCHAR2,
    med_desc IN VARCHAR2,
    med_manu IN VARCHAR2,
    med_dosage IN VARCHAR2,
    med_quantity IN NUMBER,
    med_Unitprice IN DECIMAL
) IS BEGIN
INSERT INTO medicine values ('M' || med_idseq.nextval, med_name, med_desc, med_manu, med_dosage, med_quantity, med_Unitprice);
END;

EXECUTE INSERT_MEDICINE('Med_name', 'med_desc', 'med_manu', 'med_dosage', 1, 1);

/*9. Delete Facilities & Service */
CREATE OR REPLACE PROCEDURE DELETE_FACILITY(current_fac_id IN varchar2) IS BEGIN
DELETE FROM
    Service
WHERE
    facility_id = current_fac_id;
DELETE FROM
    Facility
WHERE
    facility_id = current_fac_id;
END;

/*10. Update Medicine Fee */
CREATE OR REPLACE PROCEDURE UPDATE_MEDICINE_FEE(
    current_med_id IN varchar2,
    current_med_fee IN varchar2
) IS BEGIN 
UPDATE Medicine
SET medicine_unitprice = current_med_fee
WHERE medicine_id = current_med_id;
END;

EXECUTE DELETE_STAFF('S1016');
EXECUTE DELETE_DEPARTMENT('Admission');
EXECUTE GIVE_BONUS_STAFF('S1013', 500.00);
EXECUTE GIVE_BONUS_DEPARTMENT('Admission', 500.00);
EXECUTE DELETE_MEDICINE_DISTRIBUTION('M1001', 'R1005');
EXECUTE DELETE_MEDICINE('M1002');
EXECUTE DELETE_FACILITY('F1005');
EXECUTE UPDATE_MEDICINE_FEE('M1001', 25.00);
EXECUTE INSERT_STAFF('Justin', 'Tan', '000818-14-0799', '08/18/2000', 'Male', '0166489466', 'txen2000@gmail.com', 'Doctor', 'No.12 Jalan Tasik Damai 6, Sungai Besi, 57100, Kuala Lumpur, Malaysia');
EXECUTE INSERT_MEDICINE('Med_name', 'med_desc', 'med_manu', 'med_dosage', 1, 1);


