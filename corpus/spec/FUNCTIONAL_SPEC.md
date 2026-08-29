# Company System — Functional Specification

**Document Reference:** COSYS-FS-001  
**Version:** 1.0  
**Date:** 1998  
**Status:** Baseline

---

## 1. Purpose and Scope

The Company System is an interactive maintenance application running on the IBM AS/400 (IBM i) platform. It is designed to support the Human Resources department in managing the organisation's departmental structure and employee population. The system provides a set of enquiry and maintenance screens through which authorised users may view departments, review the employees assigned to each department, and add new employees to the system.

The scope of this specification covers three interactive screens: the Department Enquiry screen, the Employee List screen, and the New Employee screen. It also covers the rules governing employee identifier assignment, the stored routines used to seed the database with initial reference data, and all cross-cutting constraints that apply throughout the application.

This specification describes the intended behaviour of the system as it shall be presented to and experienced by the end user. It is the authoritative statement of what the system must do and forms the basis for system testing and acceptance.

---

## 2. Data Dictionary

The system stores its data in two tables. Column names and types are given as they exist in the database.

### 2.1 DEPARTMENT

Holds one row for each department recognised by the organisation.

| Column | Type | Max Length | Mandatory | Notes |
|---|---|---|---|---|
| DEPTNO | Fixed character | 3 | Yes | Primary key. Uniquely identifies the department. |
| DEPTNAME | Variable character | 36 | Yes | The department's full name as displayed to users. |
| MGRNO | Fixed character | 6 | Yes | The employee number of the department manager. |
| ADMRDEPT | Fixed character | 3 | Yes | The department number of the administering department. References DEPTNO in this same table. |
| LOCATION | Fixed character | 16 | Yes | The physical or organisational location of the department. |

The ADMRDEPT column references the DEPTNO column of the same table. When a department is deleted, all departments that administered by it are deleted as well.

### 2.2 EMPLOYEE

Holds one row for each employee on record.

| Column | Type | Max Length / Precision | Mandatory | Notes |
|---|---|---|---|---|
| EMPNO | Fixed character | 6 | Yes | Primary key. Uniquely identifies the employee. |
| FIRSTNME | Variable character | 12 | Yes | Employee's given name. |
| MIDINIT | Fixed character | 1 | Yes | Middle initial. |
| LASTNAME | Variable character | 15 | Yes | Employee's family name. |
| WORKDEPT | Fixed character | 3 | No | The department to which the employee is assigned. |
| PHONENO | Fixed character | 4 | No | Internal telephone extension. Must be a digit string from 0000 to 9998 inclusive. |
| HIREDATE | Date | — | No | The date on which the employee was hired. |
| JOB | Fixed character | 8 | No | The employee's job code. |
| EDLEVEL | Small integer | — | Yes | The employee's highest education level. |
| SEX | Fixed character | 1 | No | The employee's sex. |
| BIRTHDATE | Date | — | No | The employee's date of birth. |
| SALARY | Decimal | 9 digits, 2 decimal places | No | Base salary. |
| BONUS | Decimal | 9 digits, 2 decimal places | No | Bonus payment. |
| COMM | Decimal | 9 digits, 2 decimal places | No | Commission payment. |

**BR-001.** The PHONENO column is subject to a database-level constraint. The system must not permit any employee record whose telephone number, when stored, falls outside the range 0000 to 9998 inclusive.

---

## 3. Department Enquiry Screen

### 3.1 Description

The Department Enquiry screen is the entry point to the application. It presents the user with a scrollable list of all departments currently held on the system, together with options to navigate to employees within a department or to create a new employee.

The screen title is **Departments**.

### 3.2 Content and Layout

**BR-002.** When the Department Enquiry screen is displayed, the system shall retrieve all departments from the department table and present them in the scrollable list. Each row in the list shall display the department's identifier in the **ID** column and its name in the **Name** column.

**BR-003.** The list shall display up to fourteen rows of department data on screen at one time. The user may scroll the list to view additional departments beyond the first fourteen.

**BR-004.** The list shall support a maximum of 9,999 entries.

**BR-005.** The screen shall display a selection column labelled **Opt** to the left of the ID column. The user enters a single-character option code into this column against any department row in order to act upon that department.

### 3.3 Available Options

**BR-006.** Entering the option **5** against a department row and pressing Enter shall cause the system to open the Employee List screen for that department.

**BR-007.** Entering the option **8** against a department row and pressing Enter shall cause the system to open the New Employee screen with that department pre-selected.

**BR-008.** After the system has processed a selected option, the selection field for that row shall be cleared so that it no longer shows the option code the user entered.

### 3.4 Function Keys

**BR-009.** The key **F3=Exit** shall be available on this screen. Pressing F3 shall terminate the application and return control to the calling environment.

---

## 4. Employee List Screen

### 4.1 Description

The Employee List screen displays the employees who are assigned to a specific department. The user navigates to this screen by choosing option 5 against a department on the Department Enquiry screen. The screen title is **Employees**.

### 4.2 Content and Layout

**BR-010.** The Employee List screen shall display the department's employees in a scrollable list. Each row shall show the employee's identifier in the **ID** column, the employee's full name in the **Name** column, and the employee's job code in the **Job** column.

**BR-011.** The full name displayed in the **Name** column shall be formatted as family name, followed by a comma and a space, followed by the given name.

**BR-012.** The list shall display up to fourteen rows of employee data on screen at one time. The user may scroll the list to view additional employees beyond the first fourteen.

**BR-013.** The list shall support a maximum of 9,999 entries.

**BR-014.** Only employees whose assigned department matches the department selected on the Department Enquiry screen shall appear in this list. Employees assigned to other departments shall not be shown.

### 4.3 Salary Total

**BR-015.** The screen shall display a **Total** figure above the column headers. This figure represents the sum of salary, bonus, and commission for every employee shown in the list.

**BR-016.** The total shall be calculated as the arithmetic sum of each employee's salary plus bonus plus commission, aggregated across all employees in the department. The result shall be displayed to two decimal places.

**BR-017.** The total figure shall be presented in a field that can accommodate values up to nine digits before the decimal point.

### 4.4 Function Keys

**BR-018.** The key **F12=Back** shall be available on this screen. Pressing F12 shall close the Employee List screen and return the user to the Department Enquiry screen.

---

## 5. New Employee Screen

### 5.1 Description

The New Employee screen allows an authorised user to add a new employee to the system. The screen is reached by choosing option 8 against a department on the Department Enquiry screen. The screen title is **New Employee**.

### 5.2 Content and Layout

**BR-019.** When the New Employee screen is displayed, the system shall automatically assign and display a new employee identifier in the **ID** field. This field is for display only; the user may not alter it.

**BR-020.** The **Department** field shall be pre-populated with the identifier of the department from which the user navigated. This field is for display only; the user may not alter it.

**BR-021.** The screen shall present the following input fields for the user to complete: **First**, **Initial**, **Last**, **Job**, **Salary**, and **Phone**.

### 5.3 Field Descriptions

**BR-022.** The **First** field accepts the employee's given name. It accommodates up to twelve characters.

**BR-023.** The **Initial** field accepts the employee's middle initial. It accommodates a single character.

**BR-024.** The **Last** field accepts the employee's family name. It accommodates up to fifteen characters.

**BR-025.** The **Job** field accepts the employee's job code. It accommodates up to eight characters.

**BR-026.** The **Salary** field accepts the employee's base salary as a numeric value. It accommodates up to ten characters as entered by the user, which the system shall interpret as a decimal number with two decimal places.

**BR-027.** The **Phone** field accepts the employee's internal telephone extension. It accommodates four characters.

### 5.4 Validation Rules

The system shall validate the user's input when the Enter key is pressed. All validations are applied in sequence; the first failure encountered shall cause the system to display an error message and halt submission. The user shall remain on the New Employee screen to correct the error.

**BR-028.** The **First** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *First name cannot be blank*.

**BR-029.** The **Initial** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *Middle initial cannot be blank*.

**BR-030.** The **Last** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *Last name cannot be blank*.

**BR-031.** The **Department** field must not be blank. The system shall not permit continuation if no department has been passed to the screen. This condition shall cause the system to display the message: *Department cannot be blank*.

**BR-032.** The **Job** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *Job cannot be blank*.

**BR-033.** The **Salary** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *Salary cannot be blank*.

**BR-034.** The value entered in the **Salary** field must be a valid decimal number. If the value cannot be interpreted as a number, the system shall display the message: *Salary must be a number*.

**BR-035.** The **Phone** field must not be blank. If it is blank when the user presses Enter, the system shall display the message: *Phone cannot be blank*.

**BR-036.** The value entered in the **Phone** field must be a valid whole number. If the value cannot be interpreted as a whole number, the system shall display the message: *Phone must be a number*.

**BR-037.** The value entered in the **Phone** field, when stored, must be a digit string that falls within the range 0000 to 9998 inclusive. The database constraint described in BR-001 enforces this at the point of storage.

### 5.5 Error Message Display

**BR-038.** Error messages shall be displayed on the New Employee screen in a dedicated message area located below the input fields. Messages shall be shown in red.

**BR-039.** Only one error message shall be displayed at a time. When the user corrects the offending field and presses Enter again, the system shall re-validate from the beginning and either display the next error or proceed with the submission.

**BR-040.** When a submission is rejected owing to a failed validation, all field values the user has already entered shall be retained on screen so that the user need not re-key unaffected fields.

### 5.6 Successful Submission

**BR-041.** When the user presses Enter and all validation rules are satisfied, the system shall create a new employee record with the following values:

- Employee identifier: the automatically assigned value displayed in the **ID** field.
- Given name: the value entered in the **First** field.
- Middle initial: the value entered in the **Initial** field.
- Family name: the value entered in the **Last** field.
- Assigned department: the value displayed in the **Department** field.
- Job code: the value entered in the **Job** field.
- Salary: the numeric value entered in the **Salary** field, stored to two decimal places.
- Telephone extension: the value entered in the **Phone** field.
- Hire date: the current system date at the time of submission.
- Bonus: zero.
- Commission: zero.
- Education level: zero.

**BR-042.** Upon successful creation of the employee record, the system shall close the New Employee screen and return the user to the Department Enquiry screen.

**BR-043.** If the system is unable to create the employee record, it shall display the message: *Unable to create employee.* The user shall remain on the New Employee screen and may attempt to submit again.

**BR-044.** If the system is unable to generate a new employee identifier at the time the screen is opened, it shall display the message: *Unable to automatically generate a new ID.* The screen shall remain open but the user may not successfully submit a new employee until a valid identifier can be presented.

### 5.7 Function Keys

**BR-045.** The keys available on the New Employee screen shall be **F12=Back** and **Enter=Create**, as shown on screen.

**BR-046.** Pressing F12 shall discard any input entered on the screen and return the user to the Department Enquiry screen. No record shall be created.

---

## 6. Employee Identifier Assignment

**BR-047.** Employee identifiers are assigned by the system automatically. The user shall never be required to enter or select an employee identifier.

**BR-048.** Employee identifiers shall be issued in unbroken sequence. The system shall assign to each new employee the number that is exactly one greater than the highest identifier currently in use, so that no values are skipped and no gaps appear in the identifier sequence.

**BR-049.** The identifier shall be stored and displayed as a six-character string. If the computed numeric value contains fewer than six digits, it shall be left-padded with zeroes to fill the six-character width. For example, if the computed value is 200, the identifier stored and shown shall be 000200.

**BR-050.** The identifier field accommodates up to six significant digits. As the employee population grows over time and identifier values increase accordingly, the system shall continue to produce valid, correctly zero-padded six-character identifiers without loss of capacity or precision.

**BR-051.** The identifier is assigned at the moment the New Employee screen is opened and is displayed to the user before any data is entered. The same identifier shall be used when the record is ultimately created upon a successful submission.

---

## 7. Data Population Routines

The system includes two administrative routines designed to load an initial set of reference data into the database. These routines are intended for use during initial system installation and testing. They are not accessible through the interactive screens described in this specification.

### 7.1 Department Population Routine

**BR-052.** The department population routine shall insert five department records into the department table when executed. The five departments created shall be named Admin, IT, Finance, Management, and HR.

**BR-053.** Each department created by the routine shall be assigned a randomly generated three-character department identifier, a randomly generated six-character manager number, a randomly generated administering department code, and a location value derived from the department identifier.

**BR-054.** The routine accepts no input parameters and produces no result set. It is a maintenance utility only.

### 7.2 Employee Population Routine

**BR-055.** The employee population routine shall insert two hundred employee records into the employee table when executed. It may be called with an optional nationality parameter to influence the characteristics of the generated names; if no nationality is specified, a default nationality shall be applied.

**BR-056.** The routine shall determine how many employee records already exist in the table before it begins. It shall generate exactly two hundred new records regardless of how many records are already present. New employee numbers shall be assigned sequentially starting from one greater than the current count of employees.

**BR-057.** Each generated employee shall be assigned to a department chosen at random from those currently present in the department table.

**BR-058.** Each generated employee shall be assigned a salary in the range 30,000 to 100,000, a bonus in the range 0 to 10,000, and a commission in the range 0 to 5,000. All three values shall be stored to two decimal places.

**BR-059.** Each generated employee shall be assigned a hire date falling between 1 January 2023 and approximately ten years thereafter.

**BR-060.** Each generated employee shall be assigned a date of birth falling between 1 January 1960 and approximately fifty years thereafter.

**BR-061.** Each generated employee shall be assigned an education level in the range 12 to 19 inclusive.

**BR-062.** The routine accepts one optional input parameter: a two-character nationality code. This code governs the nationality characteristic used when generating employee names.

---

## 8. Cross-Cutting Rules

### 8.1 Navigation and Screen Flow

**BR-063.** The Department Enquiry screen is the initial and root screen of the application. All other screens are subordinate to it and are reached from it.

**BR-064.** The Employee List screen is always opened in the context of a specific department. It is not possible to reach the Employee List screen except by choosing option 5 against a department on the Department Enquiry screen.

**BR-065.** The New Employee screen is always opened in the context of a specific department. It is not possible to reach the New Employee screen except by choosing option 8 against a department on the Department Enquiry screen. The selected department shall be pre-populated in the **Department** field and the user shall not be able to change it.

**BR-066.** Pressing F12 on either the Employee List screen or the New Employee screen shall always return the user to the Department Enquiry screen. The state of the Department Enquiry screen, including the position of the scrollable list, shall be restored.

**BR-067.** Pressing F3 on the Department Enquiry screen shall exit the application entirely and return control to the operating environment.

### 8.2 Subfile Behaviour

**BR-068.** On both the Department Enquiry screen and the Employee List screen, the scrollable list shall only be displayed when there is at least one record to show. If there are no records, the list area shall remain blank.

**BR-069.** When a scrollable list contains records, the initial position on entry to the screen shall be the first record in the list.

### 8.3 Error Display

**BR-070.** Error messages throughout the application shall be shown to the user on the affected screen without navigating away from it. The user shall be able to correct the condition and retry without loss of previously entered data.

**BR-071.** Error messages on the New Employee screen shall appear in the designated message area in red text. No other area of the screen shall be used to convey error information.

### 8.4 Read-Only Fields

**BR-072.** The **ID** field on the New Employee screen is generated by the system and is presented for information only. The user must not be able to modify it.

**BR-073.** The **Department** field on the New Employee screen is pre-populated by the system based on the department from which the user navigated. The user must not be able to modify it.

### 8.5 Record Scope

**BR-074.** The current release of the system provides no facility for modifying or deleting existing department or employee records through the interactive screens. Maintenance of existing records is outside the scope of the application as presently specified.

### 8.6 Transaction Control

**BR-075.** All database insertions performed by the interactive programs and the population routines shall be carried out without requiring explicit transaction commitment by the calling environment. Each individual insert shall be treated as a self-contained operation.

---

*End of Functional Specification COSYS-FS-001*
