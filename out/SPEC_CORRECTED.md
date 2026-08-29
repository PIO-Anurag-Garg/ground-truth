# Spec Corrections — COSYS-FS-001 v1.0

> This document lists every rule whose verdict is **DRIFTED**.  
> Each entry gives the original rule text, the corrected rule text that matches
> what the code actually does, and the citations that justify the correction.  
> Rule IDs are preserved unchanged.

---

## BR-001 — PHONENO column constraint
**Section:** 2.2 EMPLOYEE

**Original rule:**
> The PHONENO column is subject to a database-level constraint. The system must not permit any employee record whose telephone number, when stored, falls outside the range 0000 to 9998 inclusive.

**Corrected rule:**
> The PHONENO column is subject to a database-level CHECK constraint. The column is defined as a five-character fixed string (`CHAR(5)`). The constraint permits any value in the range `00000` to `99998` inclusive (string comparison). Values from `00000` up to and including `99998` are accepted; values outside that range are rejected.

**Justification:**  
The DDL declares `PHONENO CHAR(5)` with `CHECK (PHONENO >= '00000' AND PHONENO <= '99998')`. The specified four-digit bound of 9998 does not match either the column width (5) or the upper bound in the constraint (`99998`).  
— [`corpus/app/qsqlsrc/employee.table:26-28`](corpus/app/qsqlsrc/employee.table:26)

---

## BR-015 — Employee List salary total description
**Section:** 4.3 Salary Total

**Original rule:**
> The screen shall display a Total figure above the column headers. This figure represents the sum of salary, bonus, and commission for every employee shown in the list.

**Corrected rule:**
> The screen shall display a Total figure above the column headers. This figure represents the sum of **salary only** for every employee shown in the list. Bonus and commission are not included in this total.

**Justification:**  
`getDeptDetail` in [`corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`](corpus/app/qrpglesrc/empdet.sqlrpgle:42) executes `SELECT SUM(salary) … FROM employee WHERE workdept = :deptno`. Bonus and commission columns are not referenced. The result populates `XTOT` on the Employee List screen.  
— [`corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`](corpus/app/qrpglesrc/empdet.sqlrpgle:42)  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:58`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:58)  
— [`corpus/app/qddssrc/emps.dspf:33-36`](corpus/app/qddssrc/emps.dspf:33)

---

## BR-016 — Salary total calculation
**Section:** 4.3 Salary Total

**Original rule:**
> The total shall be calculated as the arithmetic sum of each employee's salary plus bonus plus commission, aggregated across all employees in the department. The result shall be displayed to two decimal places.

**Corrected rule:**
> The total shall be calculated as the sum of each employee's **salary** aggregated across all employees in the department. Bonus and commission are not included in this aggregation. The result shall be displayed to two decimal places.

**Justification:**  
The SQL in `getDeptDetail` aggregates only `salary` (`SELECT SUM(salary) …`). Two decimal places are correctly maintained via `packed(9:2)` and the `9S 2` display field.  
— [`corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`](corpus/app/qrpglesrc/empdet.sqlrpgle:42)  
— [`corpus/app/qrpgleref/empdet.rpgleinc:13`](corpus/app/qrpgleref/empdet.rpgleinc:13)  
— [`corpus/app/qddssrc/emps.dspf:36`](corpus/app/qddssrc/emps.dspf:36)

---

## BR-017 — Salary total field capacity
**Section:** 4.3 Salary Total

**Original rule:**
> The total figure shall be presented in a field that can accommodate values up to nine digits before the decimal point.

**Corrected rule:**
> The total figure shall be presented in a field that can accommodate values up to **seven** digits before the decimal point. The field is defined as nine total digits with two decimal places, leaving seven integer digits.

**Justification:**  
`XTOT` in the display file is `9S 2` (9 total digits, 2 decimal — 7 integer digits). The backing data structure field `totalsalaries` is `packed(9:2)`, also yielding 7 digits before the decimal.  
— [`corpus/app/qddssrc/emps.dspf:36`](corpus/app/qddssrc/emps.dspf:36)  
— [`corpus/app/qrpgleref/empdet.rpgleinc:13`](corpus/app/qrpgleref/empdet.rpgleinc:13)

---

## BR-027 — Phone field length
**Section:** 5.3 Field Descriptions

**Original rule:**
> The Phone field accepts the employee's internal telephone extension. It accommodates four characters.

**Corrected rule:**
> The Phone field accepts the employee's internal telephone extension. It accommodates **five** characters.

**Justification:**  
The display-file field `XTEL` is declared `5A` and the database column `PHONENO` is `CHAR(5)`. Both enforce a five-character width.  
— [`corpus/app/qddssrc/nemp.dspf:42`](corpus/app/qddssrc/nemp.dspf:42)  
— [`corpus/app/qsqlsrc/employee.table:9`](corpus/app/qsqlsrc/employee.table:9)

---

## BR-029 — Middle initial blank validation
**Section:** 5.4 Validation Rules

**Original rule:**
> The Initial field must not be blank. If it is blank when the user presses Enter, the system shall display the message: Middle initial cannot be blank.

**Corrected rule:**
> ~~The Initial field must not be blank.~~ **The Initial field is not validated for blank input.** A blank value passes all validation checks and is written directly to the `MIDINIT` column in the database. No error message is displayed if the field is left empty.

**Justification:**  
`GetError()` in [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114) contains checks for `XFIRST`, `XLAST`, `XDEPT`, `XJOB`, `XSAL`, and `XTEL`, but contains no guard for `XINIT`. The `MIDINIT` column is `NOT NULL` in the schema, so a blank submission will be accepted at the application layer and stored as a blank character.  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114)  
— [`corpus/app/qddssrc/nemp.dspf:17`](corpus/app/qddssrc/nemp.dspf:17)

---

## BR-032 — Job field blank validation message
**Section:** 5.4 Validation Rules

**Original rule:**
> The Job field must not be blank. If it is blank when the user presses Enter, the system shall display the message: Job cannot be blank.

**Corrected rule:**
> The Job field must not be blank. If it is blank when the user presses Enter, the system shall display the message: **Phone number cannot be blank.** *(Note: this is a defect — the wrong error message is shown.)*

**Justification:**  
When `XJOB` is blank, the code at line 133–135 returns the string literal `'Phone number cannot be blank'` rather than `'Job cannot be blank'`. This is a copy-paste error in `GetError()`.  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133)

---

## BR-037 — Phone field stored range
**Section:** 5.4 Validation Rules

**Original rule:**
> The value entered in the Phone field, when stored, must be a digit string that falls within the range 0000 to 9998 inclusive. The database constraint described in BR-001 enforces this at the point of storage.

**Corrected rule:**
> The value entered in the Phone field, when stored, must be a digit string that falls within the range `00000` to `99998` inclusive (five-digit bounds). The database CHECK constraint on `PHONENO CHAR(5)` enforces this at the point of storage.

**Justification:**  
Same as BR-001 — the column is `CHAR(5)` and the constraint uses five-character string literals.  
— [`corpus/app/qsqlsrc/employee.table:26-28`](corpus/app/qsqlsrc/employee.table:26)

---

## BR-041 — Education level on new employee record
**Section:** 5.6 Successful Submission

**Original rule (partial):**
> Education level: zero.

**Corrected rule (partial):**
> Education level: **12**.

**Justification:**  
`HandleInsert()` sets `newEmp.EDLEVEL = 12` unconditionally (line 98). A developer comment in the source reads "we don't actually care".  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:82-112`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:82)

---

## BR-044 — Unable to generate new ID behaviour
**Section:** 5.6 Successful Submission

**Original rule:**
> If the system is unable to generate a new employee identifier at the time the screen is opened, it shall display the message: Unable to automatically generate a new ID. The screen shall remain open but the user may not successfully submit a new employee until a valid identifier can be presented.

**Corrected rule:**
> If the system is unable to generate a new employee identifier at the time the screen is opened, it shall display the message: **Unable to automatically generate an new ID.** *(Note: "an new" is a typo in the current implementation.)* The screen shall remain open. **No submission guard is enforced** — the user may press Enter and attempt to submit; the insert will fail due to a SQL primary-key constraint and the system will display "Unable to create employee." instead.

**Justification:**  
Line 48 contains the literal `'Unable to automatically generate an new ID.'`. `GetError()` does not check whether `XID` is blank before allowing submission; pressing Enter with no valid ID reaches `HandleInsert()` and fails on the SQL PK constraint.  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45)  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114)

---

## BR-048 — Employee identifier sequence increment
**Section:** 6. Employee Identifier Assignment

**Original rule:**
> Employee identifiers shall be issued in unbroken sequence. The system shall assign to each new employee the number that is exactly one greater than the highest identifier currently in use, so that no values are skipped and no gaps appear in the identifier sequence.

**Corrected rule:**
> Employee identifiers are not issued in unbroken sequence. The system assigns to each new employee the number that is **one hundred greater** than the highest identifier currently in use. Ninety-nine values are skipped between every pair of consecutive employee records created through the interactive screen.

**Justification:**  
`getNewEmpId()` computes `highestEmpId + 100` at line 188 of [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:188). No comment explains the intent.  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-192`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182)
