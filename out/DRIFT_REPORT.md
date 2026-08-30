# Drift Report

## Summary

| Metric | Count |
|---|---|
| Total rules in spec | 75 |
| Verdicts rendered | 75 |
| Undocumented behaviours (raw candidates) | 125 |
| Missing verdicts | 0 |
| Validation problems | 0 |


> Undocumented findings are counted here as raw candidates. Each verification subagent works in an isolated context, so several independently report the same behaviour. The de-duplicated set is in `out/UNDOCUMENTED.md`. Both numbers are published, because reporting only the smaller one would overstate precision.

### By verdict
| Verdict | Count |
|---|---|
| DRIFTED | 11 |
| CONFIRMED | 63 |
| UNVERIFIABLE | 1 |
| UNDOCUMENTED | 125 |
| MISSING_VERDICT | 0 |

### By confidence
| Confidence | Count |
|---|---|
| HIGH | 73 |
| MEDIUM | 1 |
| LOW | 1 |

---
## Drifted Rules

### BR-001 — HIGH confidence
- **Spec says:** The system must not permit any employee record whose telephone number falls outside the range 0000 to 9998 inclusive.
- **Code does:** The CHECK constraint is defined on a CHAR(5) column as PHONENO >= '00000' AND PHONENO <= '99998', enforcing a string-comparison upper bound of '99998' (five digits, value 99998) rather than the specified maximum of 9998. Values from 9999 to 99998 are incorrectly permitted, and the five-character column width also allows five-digit numbers well beyond the stated maximum.
- **Citations:** `corpus/app/qsqlsrc/employee.table:26-28`

### BR-015 — HIGH confidence
- **Spec says:** The total figure represents the sum of salary, bonus, and commission for every employee shown in the list.
- **Code does:** getDeptDetail computes only sum(salary) for the department; bonus and commission are excluded from the aggregation. The XTOT field on the screen is populated from this salary-only total.
- **Citations:** `corpus/app/qddssrc/emps.dspf:33-36`, `corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:58-58`

### BR-016 — HIGH confidence
- **Spec says:** The total shall be the arithmetic sum of each employee's salary plus bonus plus commission, aggregated across all employees in the department, displayed to two decimal places.
- **Code does:** The SQL in getDeptDetail aggregates only salary (select sum(salary) ... from employee where workdept = :deptno). Bonus and commission are not included. Two decimal places are correctly maintained in the field definitions (packed(9:2) and 9S 2).
- **Citations:** `corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`, `corpus/app/qrpgleref/empdet.rpgleinc:13-13`, `corpus/app/qddssrc/emps.dspf:36-36`

### BR-017 — HIGH confidence
- **Spec says:** The total field shall accommodate values up to nine digits before the decimal point.
- **Code does:** The display field XTOT is defined as 9S 2 (9 total digits, 2 decimal places), which allows only 7 digits before the decimal point. The backing data structure field totalsalaries is packed(9:2), also yielding only 7 digits before the decimal.
- **Citations:** `corpus/app/qddssrc/emps.dspf:36-36`, `corpus/app/qrpgleref/empdet.rpgleinc:13-13`

### BR-027 — HIGH confidence
- **Spec says:** The Phone field accommodates four characters.
- **Code does:** The display-file field XTEL is declared as 5A (five characters) and the database column PHONENO is CHAR(5); the field accommodates five characters, not four.
- **Citations:** `corpus/app/qddssrc/nemp.dspf:42-42`, `corpus/app/qsqlsrc/employee.table:9-9`

### BR-029 — HIGH confidence
- **Spec says:** The Initial field must not be blank. If it is blank when the user presses Enter, the system shall display the message: Middle initial cannot be blank.
- **Code does:** The GetError procedure never checks whether XINIT is blank. No validation guard exists for the middle initial field; a blank value passes through all checks and is written directly to the MIDINIT column (which is NOT NULL in the database).
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165`, `corpus/app/qddssrc/nemp.dspf:17-17`

### BR-032 — HIGH confidence
- **Spec says:** The Job field must not be blank. If it is blank when the user presses Enter, the system shall display the message: Job cannot be blank.
- **Code does:** When XJOB is blank the code returns the message 'Phone number cannot be blank' instead of 'Job cannot be blank'. The wrong error message is displayed to the user.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### BR-037 — HIGH confidence
- **Spec says:** The Phone field value, when stored, must be a digit string that falls within the range 0000 to 9998 inclusive.
- **Code does:** The database CHECK constraint on the PHONENO column (CHAR(5)) enforces PHONENO >= '00000' AND PHONENO <= '99998', permitting values up to '99998' (five digits). The spec says the upper bound is 9998 (four digits), but the DB constraint allows five-digit values up to 99998.
- **Citations:** `corpus/app/qsqlsrc/employee.table:26-28`

### BR-041 — HIGH confidence
- **Spec says:** Education level shall be stored as zero.
- **Code does:** Education level (EDLEVEL) is hard-coded to 12, not zero (line 98).
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:82-112`

### BR-044 — HIGH confidence
- **Spec says:** The message text shall be 'Unable to automatically generate a new ID', and the user may not successfully submit a new employee until a valid identifier can be presented.
- **Code does:** The message text contains a typo: 'Unable to automatically generate an new ID.' (line 48). Additionally, when no valid ID was generated, the code sets no guard to block submission — GetError() never checks whether XID is blank/valid, so the user can press Enter and attempt an insert with an empty EMPNO, which fails only because of a SQL primary-key constraint (producing 'Unable to create employee' instead of the ID-error message).
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165`

### BR-048 — HIGH confidence
- **Spec says:** The system shall assign to each new employee the number that is exactly one greater than the highest identifier currently in use, so that no values are skipped and no gaps appear in the identifier sequence.
- **Code does:** The code computes highestEmpId + 100 (not +1), so each new identifier is 100 greater than the current maximum, deliberately skipping 99 values each time.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-192`

---
## Undocumented Behaviours

### popemp generates hex phone numbers that may be non-numeric — HIGH confidence
- **Code does:** The POPEMP population procedure derives PHONENO via substr(HEX(rand()), 1, 4), producing four-character hex strings (digits 0–9 and letters A–F) that can contain alphabetic characters and are stored into the PHONENO column.
- **Why it matters:** The resulting phone values may not be numeric strings; they bypass any intended numeric-range semantics and could populate the table with values that are meaningless as telephone numbers.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:72-72`

### PHONENO column is CHAR(5) but spec and UI treat it as a 4-digit number — MEDIUM confidence
- **Code does:** The EMPLOYEE table defines PHONENO as CHAR(5), while the display file field XTEL is also 5A; the sample test data and the spec treat phone numbers as four digits (e.g. '3978', '3476', '2167'), leaving the fifth character position unused or ambiguous.
- **Why it matters:** The mismatch between the column width (5) and the intended four-digit format means the constraint bounds ('00000'–'99998') operate on five-character strings, silently widening the permitted range beyond what the specification intends.
- **Citations:** `corpus/app/qsqlsrc/employee.table:9-9`, `corpus/app/qtestsrc/empdet.test.sqlrpgle:44-49`

### Application-layer phone validation does not enforce upper bound — HIGH confidence
- **Code does:** The GetError procedure in newemp.pgm.sqlrpgle validates that XTEL is non-blank and parseable as an integer, but applies no numeric range check; it relies entirely on the database CHECK constraint to reject out-of-range values.
- **Why it matters:** Users receive no early feedback if they enter a phone number above 9998; the error only surfaces as a database constraint violation, which may produce a generic or unhelpful error message.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-162`

### Minimum salary band of 30000 enforced in application layer only — HIGH confidence
- **Code does:** newemp.pgm.sqlrpgle enforces a minimum salary of 30000 in the GetError procedure, referencing an HR policy from 2015-03, but no equivalent CHECK constraint exists on the EMPLOYEE table.
- **Why it matters:** The salary floor can be bypassed by any insertion path that does not go through the NEWEMP program (e.g. direct SQL, the POPEMP procedure), leaving the business rule unprotected at the database level.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Option codes 5 and 8 drive navigation to sub-screens — HIGH confidence
- **Code does:** Entering '5' against a department row calls the Employees program for that department; entering '8' calls the NewEmp program to add a new employee to that department.
- **Why it matters:** The valid option codes and their effects are not documented in the specification rules for this cluster, so their correctness cannot be audited.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-151`, `corpus/app/qddssrc/depts.dspf:35-36`

### Selection field is blanked after each option is processed — HIGH confidence
- **Code does:** After processing a changed subfile row, the program clears XSEL to blank and updates the subfile record, preventing the same option from being re-processed on the next interaction.
- **Why it matters:** This implicit reset behaviour is not described in the spec; a user who enters options on multiple rows would see them cleared after submission.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:153-157`

### XNAME display field is 38 characters wide but DEPTNAME column is VARCHAR(36) — MEDIUM confidence
- **Code does:** The XNAME subfile field is declared as 38A in the display file, two characters wider than the VARCHAR(36) DEPTNAME column in the DEPARTMENT table DDL.
- **Why it matters:** The two extra characters are never populated, but the discrepancy may indicate a copy-paste error or an undocumented layout margin that could mislead future maintenance.
- **Citations:** `corpus/app/qddssrc/depts.dspf:8-8`, `corpus/app/qsqlsrc/department.table:5-5`

### Subfile is fully loaded into memory before display (no lazy/paged fetch) — HIGH confidence
- **Code does:** LoadSubfile fetches all rows from the DEPARTMENT cursor in a loop and writes every row to the subfile before the screen is shown, rather than loading pages on demand.
- **Why it matters:** For large department tables approaching the 9,999-entry maximum, the load time could be noticeable; this eager-load pattern is not mentioned in the specification.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:94-131`

### Option 8 clears selection field even when NewEmp program is not invoked (unknown option entered) — HIGH confidence
- **Code does:** Any non-blank value in XSEL — including unrecognised option codes — causes the selection field to be blanked and the subfile record to be updated, even though no action was taken for that option.
- **Why it matters:** Users entering an invalid option code receive no error message; the option is silently discarded and cleared, which may cause confusion.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-157`

### TODO comment acknowledges stale design: department pass-through was considered incomplete — MEDIUM confidence
- **Code does:** A TODO comment in newemp.pgm.sqlrpgle (line 5) states 'need a way to let the parent program pass in a department id', yet the parameter interface already exists and is used.
- **Why it matters:** The stale TODO may mislead maintainers into thinking the department pre-selection feature is unimplemented, when it is in fact fully wired.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:5-5`

### New employee minimum salary enforcement (HR policy floor of 30,000) — HIGH confidence
- **Code does:** The GetError procedure in newemp.pgm.sqlrpgle rejects any salary below 30,000 with the message 'Salary below minimum band'.
- **Why it matters:** This business rule (referenced as a 2015-03 HR policy) is enforced in code but is not described in any specification rule in this cluster.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Employee ID auto-generation on New Employee screen — HIGH confidence
- **Code does:** On entry to the New Employee screen, getNewEmpId() queries the maximum existing EMPNO, increments it by 100, and pre-fills the employee ID field.
- **Why it matters:** This auto-generation behaviour is not described in any specification rule and could produce unexpected IDs if the max EMPNO is not purely numeric.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### Employee List screen displays total salaries for the department — HIGH confidence
- **Code does:** After loading the employee subfile, the Employees program retrieves the department's total salaries via getDeptDetail() and populates the XTOT field on the screen.
- **Why it matters:** No specification rule describes the display of aggregate salary data on the Employee List screen, making this behaviour unaudited.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-58`

### F5 refresh on Employee List screen — HIGH confidence
- **Code does:** Pressing F5 on the Employee List screen calls LoadSubfile() to refresh the employee list from the database.
- **Why it matters:** No specification rule describes this refresh capability for the Employee List screen.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67-68`

### Employee List screen option 5 displays employee ID via DSPLY (debug stub) — HIGH confidence
- **Code does:** In employees.pgm.sqlrpgle, option 5 on an employee row executes 'DSPLY XID', which is a debug display operation rather than any production screen navigation.
- **Why it matters:** This appears to be an incomplete or debug implementation; no production behaviour is specified or implemented for drilling into a single employee record from the Employee List screen.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147-149`

### F3 defined as CA (Command Attention) key, not CF (Command Function) — HIGH confidence
- **Code does:** CA03(03) in the DDS causes F3 to return without transmitting modified screen data to the program.
- **Why it matters:** Any data entered or changed by the user before pressing F3 is silently discarded; no spec rule documents this discard behaviour.
- **Citations:** `corpus/app/qddssrc/depts.dspf:2-2`

### Function key detection via INFDS FUNKEY field rather than indicators — MEDIUM confidence
- **Code does:** The program reads the last-used function key from position 369 of the file information data structure (FILEINFO.FUNKEY) and compares it to hex constants.
- **Why it matters:** This is an implementation-level technique not described by any specification rule; it bypasses the indicator approach implied by CA03(03) and couples the program to INFDS layout details.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:42-51`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:71-71`

### Employee list displays a Total salary field not described in employee list rules — HIGH confidence
- **Code does:** The SFLCTL record format includes an XTOT field (9S 2O) at screen position 5,61 under a 'Total' column header, populated with the sum of all department salaries via getDeptDetail().
- **Why it matters:** No specification rule in section 4.2 describes a total salary figure being shown on the Employee List screen; its presence, labelling, and calculation are undocumented behaviour.
- **Citations:** `corpus/app/qddssrc/emps.dspf:33-36`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-58`

### Employee list program exits silently if the requested department is not found — HIGH confidence
- **Code does:** If getDeptDetail() returns found=*off for the given DEPTNO, the program immediately returns without displaying any screen or error message.
- **Why it matters:** No rule describes the behaviour when an invalid or non-existent department code is passed to the Employee List; silent exit could be confusing or mask data errors.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:54-56`

### Employee list supports an Opt (selection) column allowing option '5' to display employee ID — HIGH confidence
- **Code does:** The subfile includes an XSEL input field; when value '5' is entered, the employee's EMPNO is shown via DSPLY — an interactive selection mechanism not described in the employee list rules.
- **Why it matters:** The rules describe the list as a display-only screen; the presence of an actionable Opt column implies navigational or drill-down behaviour that is undocumented.
- **Citations:** `corpus/app/qddssrc/emps.dspf:7-7`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:136-158`

### Test expects totalsalaries to include bonus and commission but SQL omits them — HIGH confidence
- **Code does:** The unit test in empdet.test.sqlrpgle asserts totalsalaries = 90160 for department A00, a value that equals salary+bonus+comm for those employees, yet the production SQL only sums salary — creating an inconsistency between the test expectation and the implementation.
- **Why it matters:** The test would fail against the current production implementation, indicating either the test or the SQL is out of sync and the defect may be undetected if tests are not being run against the current code.
- **Citations:** `corpus/app/qtestsrc/empdet.test.sqlrpgle:117-122`, `corpus/app/qrpglesrc/empdet.sqlrpgle:46-48`

### Total field is not refreshed when F5=Refresh is pressed — MEDIUM confidence
- **Code does:** When the user presses F5 (Refresh), LoadSubfile() is called to reload the employee list subfile, but getDeptDetail() and the XTOT assignment are not repeated, so the displayed total is not recalculated on refresh.
- **Why it matters:** If employee data changes between the initial load and a refresh, the total shown will be stale while the list is current, leading to a visible inconsistency on screen.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:64-72`

### F12 terminates program with *INLR=*ON rather than a simple return — MEDIUM confidence
- **Code does:** When F12 is pressed, the employees program sets *INLR = *ON before returning, which fully closes the program and releases all resources rather than leaving it dormant in the call stack.
- **Why it matters:** If the program were ever called from a context that expects to re-activate a dormant activation group, *INLR=*ON would cause loss of any retained state; no specification rule addresses this lifecycle behaviour.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:65-66`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:75-76`

### Employee List screen displays total department salaries (XTOT) in the subfile control — HIGH confidence
- **Code does:** The program fetches total salary data via getDeptDetail() and writes it to the XTOT field displayed in the subfile control header before entering the main interaction loop.
- **Why it matters:** No specification rule in the assigned cluster (or referenced in BR-018) describes the presence of an aggregate salary total on the Employee List screen.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-58`, `corpus/app/qddssrc/emps.dspf:33-36`

### Employee ID generated as max(EMPNO)+100, not max+1 — HIGH confidence
- **Code does:** getNewEmpId queries the maximum existing integer EMPNO and adds 100 to produce the next ID, leaving gaps of 99 between auto-generated employee numbers.
- **Why it matters:** The generation strategy is not specified; if any downstream logic assumes contiguous IDs it will break, and auditors may flag unexplained ID gaps.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-194`

### Minimum salary band of 30,000 enforced on new hire creation — HIGH confidence
- **Code does:** GetError rejects any salary value below 30,000 with the message 'Salary below minimum band', citing a 2015-03 HR policy.
- **Why it matters:** This HR policy constraint is not documented in any specification rule; it is a hidden business rule that silently blocks valid-looking input.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Copy-paste bug: blank Job field produces 'Phone number cannot be blank' error — HIGH confidence
- **Code does:** When XJOB is blank, GetError returns the string 'Phone number cannot be blank' instead of a job-related message.
- **Why it matters:** The misleading error message will confuse users and is evidence of a latent defect in the validation logic.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### HIREDATE automatically set to current system date at insert — HIGH confidence
- **Code does:** HandleInsert assigns %Date (today's date) to newEmp.HIREDATE without any user input or confirmation.
- **Why it matters:** No specification rule describes how HIREDATE is set; if back-dated hires are ever needed this hard-coding will require a code change.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:93-93`

### BIRTHDATE, EDLEVEL, BONUS, and COMM silently set to stub defaults at insert — HIGH confidence
- **Code does:** HandleInsert sets BIRTHDATE to today's date, EDLEVEL to 12, BONUS to 0, and COMM to 0 unconditionally, with a comment acknowledging these are not real values.
- **Why it matters:** These fields contain fabricated data in the database after every new-employee creation; no specification rule describes or justifies this behaviour.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-100`

### Minimum salary band enforced at 30,000 — HIGH confidence
- **Code does:** The GetError procedure rejects any salary value below 30,000, returning 'Salary below minimum band'.
- **Why it matters:** This HR policy constraint (commented as 2015-03) is not described by any specification rule and cannot be audited or changed without awareness.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### PHONENO database constraint restricts value to numeric range 00000–99998 — HIGH confidence
- **Code does:** A CHECK constraint on the EMPLOYEE table requires PHONENO to be between '00000' and '99998', effectively limiting it to five-digit numeric strings.
- **Why it matters:** No specification rule describes numeric-only or upper-bound constraints on the phone field; this silently rejects otherwise-valid extensions.
- **Citations:** `corpus/app/qsqlsrc/employee.table:26-28`

### Employee ID auto-generated by incrementing current maximum by 100 — HIGH confidence
- **Code does:** getNewEmpId selects the maximum existing EMPNO, adds 100, and zero-pads it to six characters as the new employee ID.
- **Why it matters:** The ID generation strategy (non-sequential +100 step, no gap-fill) is undocumented and could produce collisions or unexpected IDs if records are deleted.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### Misleading error message when Job field is blank — HIGH confidence
- **Code does:** When the XJOB field is empty the code returns the message 'Phone number cannot be blank' instead of a job-related message.
- **Why it matters:** This is a copy-paste defect that will mislead users; no specification rule acknowledges this behaviour.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Phone field validated as integer at entry time — HIGH confidence
- **Code does:** GetError attempts %int(XTEL) and returns 'Phone must be a number' if conversion fails, enforcing numeric-only input beyond what the display-file field type implies.
- **Why it matters:** No specification rule states that the Phone field must be numeric; this constraint is invisible to spec readers.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-162`

### Minimum salary band enforcement (HR policy floor) — HIGH confidence
- **Code does:** If the entered salary is a valid number but less than 30000, the system rejects the submission with the message 'Salary below minimum band'.
- **Why it matters:** This business rule — attributed to a 2015-03 HR policy in a code comment — is entirely absent from the specification; its correctness and the exact threshold cannot be audited against any documented requirement.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Department field is output-only on the screen — HIGH confidence
- **Code does:** The XDEPT field in the display file is defined with output usage (O), meaning the user cannot type into it; the department is always taken from the value passed in by the calling program.
- **Why it matters:** No rule documents that the department field is display-only rather than a user-editable input; this affects the user experience and error-handling model for BR-031.
- **Citations:** `corpus/app/qddssrc/nemp.dspf:27-27`

### Automatic employee ID generation by incrementing max existing ID by 100 — HIGH confidence
- **Code does:** The program derives a new employee number by selecting MAX(INT(EMPNO)) from the EMPLOYEE table and adding 100, then zero-padding to 6 characters.
- **Why it matters:** No specification rule documents this ID generation algorithm; concurrent inserts or non-numeric legacy EMPNO values could produce collisions or errors that are unspecified.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### HIREDATE is always set to the current date; BIRTHDATE and EDLEVEL are hard-coded defaults — MEDIUM confidence
- **Code does:** HandleInsert unconditionally sets HIREDATE to %Date (today), BIRTHDATE to %Date (today), and EDLEVEL to 12, ignoring any user input or real birth/education data.
- **Why it matters:** No specification rule covers how these fields are populated; storing today's date as the employee's birth date is likely incorrect and could cause data quality issues.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:93-100`

### Wrong error message text for blank Job field — HIGH confidence
- **Code does:** When XJOB is blank the error message returned is 'Phone number cannot be blank' instead of a job-related message.
- **Why it matters:** The mislabelled error message would mislead users into thinking the phone field is missing when it is actually the job field that is empty.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Salary minimum-band enforcement (HR policy) — HIGH confidence
- **Code does:** Salaries below 30,000 are rejected with 'Salary below minimum band', enforcing a 2015-03 HR policy minimum.
- **Why it matters:** This business rule is not documented in the specification; if the minimum changes, there is no spec entry to prompt a code update.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Auto-generated Employee ID with fallback error — HIGH confidence
- **Code does:** The program auto-generates a new employee ID by querying the max existing EMPNO and adding 100; if this fails, an error is shown before any user input.
- **Why it matters:** The auto-ID generation algorithm and the pre-entry error state are not covered by any specification rule.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### Department field is read-only output, not user-editable — HIGH confidence
- **Code does:** XDEPT is declared as Output-only (O) in the display file and is pre-populated from the calling program's currentDepartment parameter; users cannot change it.
- **Why it matters:** The spec does not describe the department field being locked to the parent context or being non-editable.
- **Citations:** `corpus/app/qddssrc/nemp.dspf:27-27`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53-53`

### BIRTHDATE populated with current system date on insert — HIGH confidence
- **Code does:** When a new employee is inserted, the BIRTHDATE field is set to %Date (the current system date), not a value entered by the user.
- **Why it matters:** No specification rule describes how BIRTHDATE is populated; storing today's date as a birth date is almost certainly incorrect and cannot be audited against any rule.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-98`

### EDLEVEL hard-coded to 12 instead of zero — HIGH confidence
- **Code does:** The education level field is always written as 12, despite a developer comment stating 'We don't actually care about these fields.'
- **Why it matters:** The spec requires EDLEVEL to be zero; the non-zero default will silently corrupt the education-level data for every employee created through this screen.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-99`

### Salary minimum-band validation enforces HR policy not in spec — MEDIUM confidence
- **Code does:** GetError() rejects salaries below 30000, returning 'Salary below minimum band', citing a 2015-03 HR policy.
- **Why it matters:** This business rule is implemented in code but has no corresponding specification rule; its correctness and continued applicability cannot be audited.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### GetError job-blank check emits misleading 'Phone number cannot be blank' message — HIGH confidence
- **Code does:** When XJOB (the Job field) is blank, the error message returned is 'Phone number cannot be blank' rather than a job-related message.
- **Why it matters:** This is a copy-paste bug that presents a misleading error to the user; no spec rule describes the expected validation message for a blank Job field.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Wrong error message for blank Job field — HIGH confidence
- **Code does:** When the Job field is blank, the validation error returned is 'Phone number cannot be blank' instead of a job-related message.
- **Why it matters:** Users will see a misleading error message, making it impossible to diagnose why the form cannot be submitted.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Employee ID auto-generated as max(EMPNO)+100 — HIGH confidence
- **Code does:** The new employee ID is computed as the maximum existing numeric EMPNO plus 100, zero-padded to 6 characters.
- **Why it matters:** This ID generation strategy (gaps of 100) and its failure mode (returns blank on SQL error) are not described anywhere in the specification.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### HIREDATE silently set to current date — HIGH confidence
- **Code does:** The new employee record's HIREDATE is automatically set to the current system date (%Date) with no user input or display.
- **Why it matters:** Users cannot set or review the hire date on the New Employee screen; this behaviour is not mentioned in the specification.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:93-93`

### BIRTHDATE, EDLEVEL, BONUS, COMM set to dummy defaults on insert — HIGH confidence
- **Code does:** Four EMPLOYEE table columns (BIRTHDATE=%Date, EDLEVEL=12, BONUS=0, COMM=0) are hard-coded to placeholder values because the New Employee screen collects no input for them.
- **Why it matters:** These defaults may violate data-quality expectations and are entirely undocumented in the specification.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-100`

### Minimum salary band of 30,000 enforced on new hire — HIGH confidence
- **Code does:** A salary value below 30,000 is rejected with 'Salary below minimum band', referencing an HR policy dated 2015-03.
- **Why it matters:** This business constraint is not documented in the specification and would be invisible to anyone relying solely on the spec.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### NEWEMP is called from Department Enquiry (option 8), not Employee Enquiry — MEDIUM confidence
- **Code does:** The New Employee program is launched by selecting option '8' against a department row in the Department Enquiry screen (DEPTS.PGM), not from within the Employee list screen.
- **Why it matters:** The entry path for creating a new employee is undocumented in the specification rules for this cluster.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150`

### New employee ID increments by 100, not 1 — HIGH confidence
- **Code does:** getNewEmpId computes MAX(EMPNO) + 100 rather than MAX(EMPNO) + 1, intentionally reserving a block of 99 unused identifier values between each new hire.
- **Why it matters:** This contradicts BR-048 and may exhaust the six-digit identifier space roughly 100 times faster than the spec intends; it is also unexplained by any documented policy.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:188-188`

### Data-population procedure (popemp) assigns IDs by row count, not MAX+1 — MEDIUM confidence
- **Code does:** popemp.sqlprc derives the starting employee number from COUNT(empno)+1, which produces incorrect IDs if any rows have been deleted, rather than using MAX(empno)+1.
- **Why it matters:** This alternative ID-assignment path bypasses both the sequential-increment rule (BR-048) and the screen-based assignment rule (BR-051), and could create duplicate EMPNO values if rows are ever removed.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:43-45`, `corpus/app/qsqlsrc/popemp.sqlprc:60-60`

### Salary minimum band enforced at £30,000 by HR policy comment — HIGH confidence
- **Code does:** GetError rejects any new-hire salary below 30000, citing a 2015-03 HR policy, and returns a 'Salary below minimum band' error.
- **Why it matters:** This business rule is hard-coded with a policy date comment but is not described in any specification rule in this cluster or referenced by the candidate file set.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### GetError validation message mislabels job field as phone number — HIGH confidence
- **Code does:** The validation for a blank XJOB field returns the error string 'Phone number cannot be blank' instead of a job-related message.
- **Why it matters:** This is a latent user-facing defect: users who leave Job blank will see a misleading error message referencing the phone number field.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### BIRTHDATE and EDLEVEL are silently set to fixed defaults on new-hire insert — HIGH confidence
- **Code does:** HandleInsert always sets BIRTHDATE to the current date and EDLEVEL to 12, ignoring any real values, with the comment 'We don't actually care about these fields'.
- **Why it matters:** These fields exist in the EMPLOYEE table schema as meaningful data points; silently filling them with dummy values could corrupt reporting or downstream analytics.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-99`

### INSERT uses WITH NC (no-commit) isolation — HIGH confidence
- **Code does:** Each INSERT into the DEPARTMENT table is executed with WITH NC (no commitment control), meaning rows are written without any transaction isolation.
- **Why it matters:** No spec rule describes the commit/isolation behaviour; if the procedure is called inside a larger transaction, the inserted rows bypass rollback and may persist even if the calling transaction is rolled back.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:35-36`

### ADMRDEPT foreign key self-reference may cause constraint violation — HIGH confidence
- **Code does:** ADMRDEPT is assigned a randomly generated 3-character value that is unlikely to match any DEPTNO already in the DEPARTMENT table, which has a self-referencing foreign key (ROD) on ADMRDEPT referencing DEPTNO.
- **Why it matters:** The insert will fail with a foreign key violation on every row unless referential-integrity checking is disabled or the randomly chosen ADMRDEPT value happens to match a DEPTNO already present; the procedure has no error handling for this case.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:22-22`, `corpus/app/qsqlsrc/department.table:11-14`

### Duplicate DEPTNO primary key collision possible across iterations — MEDIUM confidence
- **Code does:** DEPTNO is generated as right('000' || cast(rand()*1000 as int), 3), producing a value in the range 000-999; across five loop iterations there is a non-zero probability of generating the same value twice, which would cause a primary-key violation on the second INSERT.
- **Why it matters:** The procedure has no duplicate-detection or retry logic, and no spec rule addresses uniqueness guarantees or error recovery.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:20-20`, `corpus/app/qsqlsrc/department.table:4-9`

### Location value has fixed 'Location ' prefix rather than being purely derived — MEDIUM confidence
- **Code does:** The location column is set to the string literal 'Location ' concatenated with the DEPTNO value (e.g. 'Location 042'), so all locations share the same prefix.
- **Why it matters:** The spec only says the location is 'derived from the department identifier', but the specific derivation formula ('Location ' + deptno) is not documented and constrains what valid location values look like.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:23-23`

### Default nationality is 'gb' (Great Britain) — HIGH confidence
- **Code does:** When no nationality is supplied the procedure defaults to 'gb'; the spec only says 'a default nationality shall be applied' without specifying which one.
- **Why it matters:** Callers relying on spec alone cannot predict the language/locale of generated names for the default case.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:11-11`

### Names fetched from external HTTP API (randomuser.me) — HIGH confidence
- **Code does:** Each iteration issues an HTTP GET to https://randomuser.me/api/?nat=<Nationality> and parses the JSON response for first name, last name, and gender.
- **Why it matters:** Network availability and third-party API uptime become a hard dependency; no spec rule mentions this external dependency.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:49-56`, `corpus/app/qsqlsrc/popemp.sqlprc:61-63`

### SEX field populated from API gender response — HIGH confidence
- **Code does:** The employee SEX column is set to the first character of the 'gender' field returned by the randomuser.me API (e.g. 'm' or 'f').
- **Why it matters:** Gender assignment is undocumented in any spec rule; the field's derivation and valid values are not specified.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:76-76`

### MIDINIT derived as first character of first name — HIGH confidence
- **Code does:** The MIDINIT (middle initial) column is set to substr(first_name, 1, 1) — the first letter of the employee's first name, not a true middle initial.
- **Why it matters:** No spec rule describes how MIDINIT is populated; using the first-name initial is semantically incorrect and could mislead downstream consumers.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:62-62`

### JOB column assigned a random hex-based code — HIGH confidence
- **Code does:** Each employee's JOB column is set to 'JOB' concatenated with 4 random hex characters (e.g. 'JOB3F9A').
- **Why it matters:** No spec rule describes how the JOB field is populated; the format is undocumented.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:74-74`

### PHONENO generated as 4-char hex string into a CHAR(5) column — HIGH confidence
- **Code does:** Phone number is set to substr(HEX(rand()), 1, 4), producing a 4-character hex string, while the EMPLOYEE table defines PHONENO as CHAR(5) with a CHECK constraint requiring '00000'–'99998'.
- **Why it matters:** Hex digits A–F do not satisfy the all-numeric CHECK constraint on PHONENO, which may cause insertion failures at runtime; this mismatch is undocumented.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:72-72`, `corpus/app/qsqlsrc/employee.table:26-28`

### Education level upper bound is 19 (not 20) — HIGH confidence
- **Code does:** Ed level is computed as 12 + int(rand() * 8); since int(rand() * 8) yields 0–7, the maximum possible value is 19 inclusive, consistent with BR-061.
- **Why it matters:** The expression int(rand()*8) never produces 8, so the value 20 is unreachable; this boundary detail is not captured in the spec.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:75-75`

### INSERT uses WITH NC (no-commit) isolation — HIGH confidence
- **Code does:** Each INSERT statement is executed with 'WITH NC' (no commitment control), meaning records are not written under transaction control.
- **Why it matters:** Partial population runs cannot be rolled back on failure; this transactional behaviour is not documented in any spec rule.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:83-86`

### Employee List silently exits if department not found — HIGH confidence
- **Code does:** employees.pgm.sqlrpgle returns immediately (without displaying anything or showing an error) if getDeptDetail() reports the department was not found.
- **Why it matters:** A user or caller passing a non-existent department code will see the screen disappear instantly with no feedback, and no specification rule describes this failure mode.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-56`

### Stale TODO comment in New Employee program despite working parameter interface — HIGH confidence
- **Code does:** newemp.pgm.sqlrpgle contains a TODO comment saying 'need a way to let the parent program pass in a department id', but the program already declares and uses a currentDepartment parameter via dcl-pi.
- **Why it matters:** The comment is misleading and suggests the department-passing mechanism may have been retrofitted without removing the original note, which could confuse future maintainers about the intent of the code.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:5-9`

### New Employee ID auto-generated as max(empno)+100, not +1 — HIGH confidence
- **Code does:** getNewEmpId() selects the maximum integer employee number and adds 100 to it, leaving a gap of 100 ID slots between the last existing employee and any newly created one.
- **Why it matters:** The large increment is undocumented and could rapidly exhaust the 6-digit numeric ID space if called frequently; no specification rule describes the ID generation strategy.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-195`

### GetError() validation message for Job field incorrectly reads 'Phone number cannot be blank' — HIGH confidence
- **Code does:** When the XJOB field is blank, GetError() returns the string 'Phone number cannot be blank' instead of a message referring to Job.
- **Why it matters:** This is a copy-paste error in the validation logic that will display a misleading error message to the user when the Job field is omitted.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### F5=Refresh key on Employee List reloads subfile from database — HIGH confidence
- **Code does:** employees.pgm.sqlrpgle handles F5 by calling LoadSubfile(), re-querying the database and refreshing the displayed employee list for the current department.
- **Why it matters:** This refresh capability is not mentioned in any specification rule and represents a functional behaviour that could have UX implications (e.g., unsaved selections are discarded).
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67-68`, `corpus/app/qddssrc/emps.dspf:3-3`

### SFLRRN reset to rrn (last loaded record) after each selection update — MEDIUM confidence
- **Code does:** After processing a selection in HandleInputs, SFLRRN is set to the value of rrn (the last loaded RRN) rather than the current selected record's position, which controls where the cursor returns to on the screen.
- **Why it matters:** The post-selection cursor position is effectively the bottom of the loaded subfile rather than the row the user acted on, which may be unexpected behaviour not described in any specification rule.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:153-157`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:152-156`

### Employee List subfile is cleared and reloaded on F5=Refresh — HIGH confidence
- **Code does:** Pressing F5 on the Employee List screen triggers a full ClearSubfile + LoadSubfile cycle, requerying the database and repopulating the subfile from scratch.
- **Why it matters:** No specification rule describes the F5=Refresh function or its effect on the employee list; this is observable behaviour that could mask data changes or performance concerns.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67-68`

### Employee List exits immediately if department is not found — HIGH confidence
- **Code does:** After loading the subfile, employees.pgm.sqlrpgle calls getDeptDetail and returns immediately if the department is not found, bypassing the display loop entirely.
- **Why it matters:** No specification rule describes this early-exit behaviour; users navigating to an invalid department would see a blank/instant return with no error message.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-56`

### Incorrect validation error message for empty Job field — HIGH confidence
- **Code does:** When XJOB is blank, GetError returns 'Phone number cannot be blank' instead of a job-related message, misidentifying the failed field to the user.
- **Why it matters:** Users receive a misleading error message that names the wrong field, which could cause confusion and difficulty correcting the form.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Salary field validated against minimum band (HR policy floor of 30000) — HIGH confidence
- **Code does:** GetError rejects salary values below 30000, citing an HR policy (2015-03) minimum band; this business rule is not described in any specification rule in the assigned cluster.
- **Why it matters:** An undocumented HR-policy business rule is enforced in code and could silently become stale if the policy changes.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Auto-generated employee ID displayed as error when generation fails — MEDIUM confidence
- **Code does:** Before entering the main loop, if getNewEmpId() returns blank, XERR is set to an error message on the initial screen display rather than through the normal validation path.
- **Why it matters:** This pre-loop error path means an error can be shown without the user having entered any data, and the program will still proceed to accept input in the loop — the error message may be silently overwritten.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:47-51`

### HandleInsert ignores screen XDEPT and uses the raw program parameter instead — HIGH confidence
- **Code does:** On insert, newEmp.WORKDEPT is assigned from the program parameter currentDepartment (line 91), not from the display field XDEPT, so any hypothetical screen value for XDEPT is silently discarded.
- **Why it matters:** If the read-only enforcement on XDEPT were ever removed, a user-entered department would still be silently overridden by the caller-supplied parameter, making the behaviour non-obvious and untestable from the UI.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:85-112`

### Wrong error message returned when Job field is blank — HIGH confidence
- **Code does:** When XJOB is blank the function returns the string 'Phone number cannot be blank' instead of a message about the job field.
- **Why it matters:** This copy-paste error will confuse users who leave the Job field empty, as they will be told to fix the phone number instead.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Minimum salary band of $30,000 enforced at creation time — HIGH confidence
- **Code does:** GetError rejects any salary below 30000, citing a 2015-03 HR policy; no employee can be created below this threshold.
- **Why it matters:** This business rule is not documented in the specification and cannot be audited for correctness or currency.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Employee ID generation adds 100 to the current maximum rather than incrementing by 1 — MEDIUM confidence
- **Code does:** getNewEmpId computes the next ID as max(int(empno)) + 100, meaning IDs advance in steps of 100 rather than sequentially.
- **Why it matters:** This gap strategy is undocumented; it may reflect an intentional design choice or a latent bug, and the spec says only that the ID is system-generated.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-195`

### Minimum salary band enforced on new employee creation — HIGH confidence
- **Code does:** newemp.pgm.sqlrpgle rejects any new-hire salary below 30,000 with the message 'Salary below minimum band', attributed to a 2015-03 HR policy comment.
- **Why it matters:** This business rule is not described in the specification and could silently block valid data entry if the policy changes.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Employee ID is auto-generated by incrementing the current maximum EMPNO by 100 — HIGH confidence
- **Code does:** getNewEmpId() queries the maximum integer value of EMPNO, adds 100, and zero-pads it to 6 characters; the spec does not describe this generation strategy.
- **Why it matters:** The +100 step increment is an undocumented convention that could cause ID collisions or unexpected gaps if records are inserted outside the application.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:172-194`

### Option '5' on the employees subfile only displays the employee number (DSPLY), not a detail screen — MEDIUM confidence
- **Code does:** In employees.pgm.sqlrpgle, selecting option 5 on an employee row calls DSPLY XID, which merely pops a system message box showing the employee number rather than navigating to a proper detail panel.
- **Why it matters:** This appears to be an unfinished stub — a placeholder left in place of a real employee-detail screen — which is behaviour not mentioned in the specification.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147-150`

### GetError() mislabels the job-field validation error as 'Phone number cannot be blank' — HIGH confidence
- **Code does:** When XJOB is blank, the error message returned is 'Phone number cannot be blank' instead of 'Job cannot be blank', indicating a copy-paste defect.
- **Why it matters:** The incorrect error message would mislead users attempting to submit the new-employee form with a missing job code.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### COMMIT(*NONE) baked into compiled objects via makefile — HIGH confidence
- **Code does:** All three RPGLE programs (DEPTS, EMPLOYEES, NEWEMP) are compiled with COMMIT(*NONE) in the makefile, which disables journal-based commitment control at the object level, not just at the SQL statement level.
- **Why it matters:** The no-commit behaviour is enforced at compile time, so it cannot be overridden by the calling environment even if desired — this is stronger than the spec implies (which only states no explicit commitment is required from the caller).
- **Citations:** `corpus/app/makefile:39-49`

### SQL stored procedures use WITH NC on INSERT but have no explicit commit scope declaration — MEDIUM confidence
- **Code does:** The stored procedures popdept and popemp use 'WITH NC' on each INSERT statement, preventing journal commitment, but the CREATE PROCEDURE statements themselves carry no COMMIT ON RETURN or AUTONOMOUS clause, leaving batch-level rollback behaviour undefined if the procedure is called inside an outer transaction.
- **Why it matters:** If a caller ever wraps the procedure call in a transaction (e.g. from a JDBC/ODBC client with autocommit off), the WITH NC inserts will bypass commitment control anyway, but the interaction between the outer transaction and the procedure's side effects is not specified.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:5-9`, `corpus/app/qsqlsrc/popemp.sqlprc:10-16`

### Employee ID auto-generation increments by 100 instead of 1 — HIGH confidence
- **Code does:** getNewEmpId() computes the next employee ID as MAX(INT(empno)) + 100, not MAX + 1, creating large gaps in the employee number sequence.
- **Why it matters:** No specification rule describes this gap-by-100 strategy; if employee numbers are expected to be sequential (e.g. for reporting or range queries) this behaviour could produce unexpected results.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-194`

### Minimum salary validation hard-coded to 30000 with HR policy comment — MEDIUM confidence
- **Code does:** newemp.pgm.sqlrpgle rejects any new hire salary below 30000, citing a 2015-03 HR policy in a source comment.
- **Why it matters:** This business rule is undocumented in the specification and is embedded as a magic constant with a dated policy reference, making it invisible to future maintainers without reading the source.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Employee List exits immediately if department is not found — HIGH confidence
- **Code does:** EMPLOYEES program calls getDeptDetail and returns without displaying any screen if the department record is not found (found = *off).
- **Why it matters:** This silent early-exit is invisible to the user — no error message is shown — and the behaviour is undocumented, so a caller cannot predict what happens when an invalid department is passed.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-56`

### Employee List displays total salaries from getDeptDetail, not a subfile sum — HIGH confidence
- **Code does:** XTOT is populated from getDeptDetail.totalsalaries (a pre-computed SQL SUM of the department's employees' salaries) before the display loop begins; it is not recalculated from the subfile rows.
- **Why it matters:** The salary total can therefore differ from the visible list if the subfile query and the getDeptDetail query run at different points in time, and this approach is not described in any specification rule.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-58`, `corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`

### Employee List supports F5=Refresh to reload the subfile — HIGH confidence
- **Code does:** Pressing F5 on the Employee List screen triggers LoadSubfile(), re-querying the database and refreshing the displayed employee rows.
- **Why it matters:** This is a user-visible interactive feature shown in the screen footer ('F5=Refresh F12=Back') that is not mentioned in any specification rule.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67-68`, `corpus/app/qddssrc/emps.dspf:39-39`

### Employee List option 5 shows a DSPLY popup rather than navigating to a screen — HIGH confidence
- **Code does:** When the user selects option 5 on an employee row, the program executes 'DSPLY XID' — a raw system display of the employee ID — instead of opening a dedicated employee detail screen.
- **Why it matters:** This is a stub/placeholder behaviour that a user or developer would not expect from a production system; it is undocumented and differs from the analogous option 5 on the Department screen which calls the EMPLOYEES program.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147-149`

### New Employee screen displays a name formatted as 'LASTNAME, FIRSTNAME' in the Employee List — HIGH confidence
- **Code does:** The Employee List subfile row for XNAME is assembled as LASTNAME + ', ' + FIRSTNAME (trimmed), not FIRSTNAME LASTNAME.
- **Why it matters:** The display format of the employee name in the list is undocumented.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:117-118`

### New Employee insert uses HIREDATE = current date and hard-coded BIRTHDATE = current date — HIGH confidence
- **Code does:** HandleInsert sets HIREDATE to %Date (today) and BIRTHDATE also to %Date (today) with a comment 'We don't actually care about these fields', and hardcodes EDLEVEL=12, BONUS=0, COMM=0.
- **Why it matters:** Using the current date as birthdate is semantically incorrect and represents undocumented default-value behaviour for fields the user cannot enter.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:93-101`

### Salary minimum band validation enforces 30,000 minimum for new hires — HIGH confidence
- **Code does:** GetError rejects a salary below 30,000 with the message 'Salary below minimum band', citing a 2015-03 HR policy comment in the source.
- **Why it matters:** This business rule (minimum salary of 30,000) is enforced in the interactive validation path but is not described in any specification rule.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`

### Job validation error message is mislabelled as 'Phone number cannot be blank' — HIGH confidence
- **Code does:** When XJOB (the Job field) is blank, GetError returns 'Phone number cannot be blank' instead of a job-related message — the error message text is incorrect for the field being validated.
- **Why it matters:** This is a bug in validation error messaging that is invisible in the specification; the user receives a misleading error.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`

### Salary field on New Employee screen is entered as free-text and converted to DECIMAL — HIGH confidence
- **Code does:** XSAL is declared as a 10-character alphanumeric input field; the program validates it with %dec() and converts it to a packed decimal on insert.
- **Why it matters:** The alphanumeric salary input and the numeric conversion/validation step are undocumented behaviours.
- **Citations:** `corpus/app/qddssrc/nemp.dspf:37-37`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:137-145`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:104-104`

### Phone field validated as integer but stored as CHAR(5) in the database — HIGH confidence
- **Code does:** GetError validates XTEL with %int() to ensure it is numeric, but PHONENO in the database is CHAR(5); the 5-character screen field is stored directly.
- **Why it matters:** The validation allows any 5-digit-or-fewer integer string but does not enforce that the value is exactly 5 digits or padded; this undocumented type-coercion behaviour is separate from the PHONENO range constraint (BR-001).
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-162`, `corpus/app/qsqlsrc/employee.table:9-9`

### getNewEmpId increments maximum existing EMPNO by 100, not 1 — HIGH confidence
- **Code does:** getNewEmpId selects MAX(INT(EMPNO)) from EMPLOYEE and adds 100 to derive the next employee number, then zero-pads it to 6 characters.
- **Why it matters:** The gap of 100 between IDs is an undocumented detail of the ID-generation algorithm that differs from a simple sequential increment.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-192`

### getNewEmpId returns blank string on SQL error; program shows generic error message — MEDIUM confidence
- **Code does:** If the MAX(EMPNO) query fails (sqlstate <> '00000'), getNewEmpId returns '' and the caller displays 'Unable to automatically generate an new ID.' without further detail.
- **Why it matters:** The error handling path for ID generation failure is undocumented.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:47-51`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:193-194`

### getDeptDetail substitutes 'N/A' when department LOCATION is NULL — HIGH confidence
- **Code does:** getDeptDetail uses COALESCE(location, 'N/A') so a department with no location returns the string 'N/A' rather than blank.
- **Why it matters:** This substitution is an undocumented presentation rule for missing location data.
- **Citations:** `corpus/app/qrpglesrc/empdet.sqlrpgle:44-45`

### getEmployeeDetail computes net income as salary + bonus + comm — HIGH confidence
- **Code does:** getEmployeeDetail returns netincome as the arithmetic sum of SALARY, BONUS, and COMM columns.
- **Why it matters:** The composition of 'net income' (i.e., including bonus and commission) is an undocumented calculation rule for the employee detail service.
- **Citations:** `corpus/app/qrpglesrc/empdet.sqlrpgle:16-17`

### getDeptDetail returns total salaries as sum of SALARY only (excludes bonus and comm) — HIGH confidence
- **Code does:** The department total returned in totalsalaries is SUM(salary) for employees in the department — it does not include BONUS or COMM.
- **Why it matters:** The composition of the department salary total is undocumented, and it differs from the employee-level net income calculation which includes bonus and comm.
- **Citations:** `corpus/app/qrpglesrc/empdet.sqlrpgle:46-48`

### Department table has a self-referential foreign key CASCADE DELETE on ADMRDEPT — HIGH confidence
- **Code does:** The DEPARTMENT table enforces a foreign key on ADMRDEPT that references DEPARTMENT itself, with ON DELETE CASCADE, meaning deleting a department can cascade-delete its administered sub-departments.
- **Why it matters:** This referential integrity rule is undocumented in the specification and has significant data-integrity implications.
- **Citations:** `corpus/app/qsqlsrc/department.table:11-14`

### LOCATION column on DEPARTMENT table is declared NOT NULL in DDL but COALESCE used as if nullable — MEDIUM confidence
- **Code does:** The DDL declares LOCATION CHAR(16) NOT NULL, but getDeptDetail wraps location in COALESCE(location, 'N/A'), suggesting the schema has been or was expected to allow NULLs.
- **Why it matters:** The discrepancy between the DDL constraint and the defensive COALESCE is undocumented and may indicate schema drift or dead defensive code.
- **Citations:** `corpus/app/qsqlsrc/department.table:8-8`, `corpus/app/qrpglesrc/empdet.sqlrpgle:44-45`

### popdept generates department names from a fixed set of five categories — HIGH confidence
- **Code does:** popdept always creates exactly the same five department names: Admin, IT, Finance, Management, HR (in that iteration order), while DEPTNO, MGRNO, and ADMRDEPT are randomised.
- **Why it matters:** The fixed department name list is undocumented; the spec only says 5 departments with random IDs.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:26-32`

### popdept sets ADMRDEPT to a random value, which may not exist in the DEPARTMENT table, violating the self-referential FK — MEDIUM confidence
- **Code does:** admrdept is set to a random 3-digit string that is independent of the generated DEPTNO values; insertion with 'with nc' skips commit but does not bypass FK enforcement.
- **Why it matters:** The population procedure may produce FK violations on ADMRDEPT if the randomly generated value does not match an existing DEPTNO, which is undocumented risk.
- **Citations:** `corpus/app/qsqlsrc/popdept.sqlprc:22-22`, `corpus/app/qsqlsrc/department.table:11-14`

### popemp uses SYSTOOLS.HTTP_GET to fetch live random user data from randomuser.me per employee record — HIGH confidence
- **Code does:** For each of the 200 employees, popemp makes an individual HTTP GET request to randomuser.me/api to obtain first name, last name, and sex, performing 200 sequential HTTP calls per invocation.
- **Why it matters:** The external HTTP dependency and one-request-per-row design is undocumented and has significant performance and availability implications.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:48-56`

### popemp derives PHONENO as a 4-character hex substring of a random value — HIGH confidence
- **Code does:** v_phone_no is set to the first 4 characters of HEX(rand()), producing a 4-digit hex string (e.g. '3F7A') rather than a numeric phone number.
- **Why it matters:** The phone number is stored as a non-numeric hex value, which may violate the PHONENO constraint (BR-001 requires 00000–99998) and is entirely undocumented.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:72-72`

### popemp derives MIDINIT from first character of first name, not a separate middle-initial field — HIGH confidence
- **Code does:** v_mid_init is set to SUBSTR of the first name's first character rather than a dedicated middle-initial value from the API response.
- **Why it matters:** The middle initial is always identical to the first letter of the first name; this undocumented derivation rule means MIDINIT is not independent data.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:62-62`

### popemp derives SEX from first character of gender string returned by API — MEDIUM confidence
- **Code does:** v_sex is set to SUBSTR(json_value(...gender),1,1), mapping 'male'→'m' and 'female'→'f'.
- **Why it matters:** The mapping from the API gender field to the SEX column is undocumented.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:76-76`

### popemp generates job codes as 'JOB' concatenated with 4 hex characters — HIGH confidence
- **Code does:** v_job is set to 'JOB' || SUBSTR(HEX(rand()),1,4), producing values like 'JOB3F7A' rather than meaningful job titles.
- **Why it matters:** The job generation algorithm is undocumented and produces non-descriptive codes.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:74-74`

### popemp hire date spans a 10-year window from 2023-01-01 — MEDIUM confidence
- **Code does:** v_hire_date = date('2023-01-01') + INT(rand() * 365 * 10) DAYS, producing hire dates between 2023 and approximately 2033.
- **Why it matters:** The specific hire-date window (starting 2023, spanning 10 years) is undocumented in the specification.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:73-73`

### popemp birth date spans a 50-year window from 1960-01-01 — MEDIUM confidence
- **Code does:** v_birth_date = date('1960-01-01') + INT(rand() * 365 * 50) DAYS, producing birth dates between 1960 and approximately 2010.
- **Why it matters:** The specific birth-date window is undocumented.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:77-77`

### popemp uses sequential integer EMPNO starting from current row count + 1 — HIGH confidence
- **Code does:** i is initialised to COUNT(empno)+1 (not MAX+1), so if any rows were deleted the new IDs may collide with previously used (now-deleted) IDs.
- **Why it matters:** Using COUNT rather than MAX for the starting ID is an undocumented design choice that can produce duplicate primary key errors when rows have been deleted.
- **Citations:** `corpus/app/qsqlsrc/popemp.sqlprc:43-45`

### mypgm.pgm.rpgle is an orphaned test/hello-world program with no functional role — HIGH confidence
- **Code does:** mypgm prints 'Hello to all you people' via printf and DSPLY; it has no relation to the application's department/employee functionality.
- **Why it matters:** The presence of this program in the application source tree is undocumented; it may be leftover scaffolding that should be removed.
- **Citations:** `corpus/app/qrpglesrc/mypgm.pgm.rpgle:1-18`

### Test suite uses CRTDUPOBJ + OVRDBF to isolate tests against QTEMP copies of tables — HIGH confidence
- **Code does:** setupMockTable duplicates the EMPLOYEE and DEPARTMENT tables into QTEMP and overrides the file reference at job scope so test queries hit the isolated copies.
- **Why it matters:** The test isolation strategy (QTEMP duplication, job-scoped override) is not described in the specification and is important for understanding how tests can be run safely without affecting production data.
- **Citations:** `corpus/app/qtestsrc/empdet.test.sqlrpgle:11-33`

### Test fixture includes an employee (GREG ORLANDO) with salary below the 30,000 minimum band — MEDIUM confidence
- **Code does:** setUpSuite inserts employee '200120' with SALARY=29250, which is below the 30,000 minimum enforced by the new-employee validation.
- **Why it matters:** The test data contradicts the salary minimum-band rule, suggesting existing employees may have sub-minimum salaries or the rule is only enforced on insert via the interactive screen.
- **Citations:** `corpus/app/qtestsrc/empdet.test.sqlrpgle:48-49`

### Departments subfile loaded without ORDER BY — display order is undefined — MEDIUM confidence
- **Code does:** The deptCur cursor in depts.pgm.sqlrpgle selects DEPTNO and DEPTNAME FROM DEPARTMENT with no ORDER BY clause, so the display order depends on physical storage order.
- **Why it matters:** The undocumented (and non-deterministic) sort order of the department list is a behaviour not covered by the specification.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:101-103`

### Employee subfile loaded without ORDER BY — display order is undefined — MEDIUM confidence
- **Code does:** The empCur cursor in employees.pgm.sqlrpgle selects employees with no ORDER BY clause.
- **Why it matters:** The undocumented sort order of the employee list is a behaviour not covered by the specification.
- **Citations:** `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:98-101`

### Depts program uses fixed-format RPG file declaration (F-spec) instead of free-format Dcl-F — LOW confidence
- **Code does:** depts.pgm.sqlrpgle mixes fixed-format F-spec and D-spec declarations with free-format RPG code, unlike the fully free-format style used in employees.pgm.sqlrpgle.
- **Why it matters:** The inconsistent coding style between programs is undocumented and may indicate the depts program was not fully converted to free-format RPG.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:20-51`

---
## Unverifiable Rules

### BR-074 — LOW confidence
- **Spec says:** —
- **Code does:** —
- **Note:** Downgraded from CONFIRMED by adversarial re-verification, see out/REDTEAM.md. The rule asserts the ABSENCE of a modify/delete facility. A full-corpus search finds no UPDATE or DELETE against the data tables, so the absence appears real, but absence cannot be established by citation.

---
## Confirmed Rules (compact)

| Rule ID | Confidence | Citations | Note |
|---|---|---|---|
| BR-002 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:101-120`, `corpus/app/qddssrc/depts.dspf:7-8`, `corpus/app/qddssrc/depts.dspf:22-25` |  |
| BR-003 | HIGH | `corpus/app/qddssrc/depts.dspf:11-11` |  |
| BR-004 | HIGH | `corpus/app/qddssrc/depts.dspf:12-12` |  |
| BR-005 | HIGH | `corpus/app/qddssrc/depts.dspf:6-6`, `corpus/app/qddssrc/depts.dspf:19-21` |  |
| BR-006 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-147`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:4-6` |  |
| BR-007 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:7-9`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53-53` |  |
| BR-008 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:153-157` |  |
| BR-009 | HIGH | `corpus/app/qddssrc/depts.dspf:2-2`, `corpus/app/qddssrc/depts.dspf:30-31`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:71-72`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:76-79`, `corpus/app/qrpgleref/constants.rpgleinc:3-3` |  |
| BR-010 | HIGH | `corpus/app/qddssrc/emps.dspf:8-10`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:116-119` |  |
| BR-011 | HIGH | `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:117-118` |  |
| BR-012 | HIGH | `corpus/app/qddssrc/emps.dspf:13-13` |  |
| BR-013 | HIGH | `corpus/app/qddssrc/emps.dspf:14-14` |  |
| BR-014 | HIGH | `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:4-6`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:98-101` |  |
| BR-018 | HIGH | `corpus/app/qddssrc/emps.dspf:2-2`, `corpus/app/qddssrc/emps.dspf:39-39`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:65-66`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:75-76`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:145-147` |  |
| BR-019 | HIGH | `corpus/app/qddssrc/nemp.dspf:7-7`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51` |  |
| BR-020 | HIGH | `corpus/app/qddssrc/nemp.dspf:27-27`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53-53` |  |
| BR-021 | HIGH | `corpus/app/qddssrc/nemp.dspf:12-12`, `corpus/app/qddssrc/nemp.dspf:17-17`, `corpus/app/qddssrc/nemp.dspf:22-22`, `corpus/app/qddssrc/nemp.dspf:32-32`, `corpus/app/qddssrc/nemp.dspf:37-37`, `corpus/app/qddssrc/nemp.dspf:42-42` |  |
| BR-022 | HIGH | `corpus/app/qddssrc/nemp.dspf:12-12`, `corpus/app/qsqlsrc/employee.table:5-5` |  |
| BR-023 | HIGH | `corpus/app/qddssrc/nemp.dspf:17-17`, `corpus/app/qsqlsrc/employee.table:6-6` |  |
| BR-024 | HIGH | `corpus/app/qddssrc/nemp.dspf:22-22`, `corpus/app/qsqlsrc/employee.table:7-7` |  |
| BR-025 | HIGH | `corpus/app/qddssrc/nemp.dspf:32-32`, `corpus/app/qsqlsrc/employee.table:11-11` |  |
| BR-026 | HIGH | `corpus/app/qddssrc/nemp.dspf:37-37`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:104-104`, `corpus/app/qsqlsrc/employee.table:15-15` |  |
| BR-028 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:119-121` |  |
| BR-030 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:123-125` |  |
| BR-031 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:127-131` |  |
| BR-033 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:137-139` |  |
| BR-034 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:141-145` |  |
| BR-035 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-154` |  |
| BR-036 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:157-161` |  |
| BR-038 | HIGH | `corpus/app/qddssrc/nemp.dspf:44-44`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:74-76` |  |
| BR-039 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:55-76`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165` |  |
| BR-040 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:55-78`, `corpus/app/qddssrc/nemp.dspf:12-42` |  |
| BR-042 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:68-70`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:78-80`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-151` |  |
| BR-043 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:68-72` |  |
| BR-045 | HIGH | `corpus/app/qddssrc/nemp.dspf:2-2`, `corpus/app/qddssrc/nemp.dspf:47-47`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:62-72` |  |
| BR-046 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:62-63`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:78-80`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150` |  |
| BR-047 | HIGH | `corpus/app/qddssrc/nemp.dspf:7-7`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51` |  |
| BR-049 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:175-191` |  |
| BR-050 | HIGH | `corpus/app/qsqlsrc/employee.table:4-4`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:42-42`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:178-178` |  |
| BR-051 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:87-87` |  |
| BR-052 | HIGH | `corpus/app/qsqlsrc/popdept.sqlprc:18-39`, `corpus/app/qsqlsrc/popdept.sqlprc:26-32` |  |
| BR-053 | HIGH | `corpus/app/qsqlsrc/popdept.sqlprc:20-23` |  |
| BR-054 | HIGH | `corpus/app/qsqlsrc/popdept.sqlprc:5-7` |  |
| BR-055 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:10-12`, `corpus/app/qsqlsrc/popemp.sqlprc:43-45`, `corpus/app/qsqlsrc/popemp.sqlprc:48-48` |  |
| BR-056 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:43-45`, `corpus/app/qsqlsrc/popemp.sqlprc:48-48`, `corpus/app/qsqlsrc/popemp.sqlprc:60-60` |  |
| BR-057 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:66-70` |  |
| BR-058 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:78-80`, `corpus/app/qsqlsrc/employee.table:15-17` |  |
| BR-059 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:73-73` |  |
| BR-060 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:77-77` |  |
| BR-061 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:75-75` |  |
| BR-062 | HIGH | `corpus/app/qsqlsrc/popemp.sqlprc:10-12` |  |
| BR-063 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:63-79`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:4-10` |  |
| BR-064 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-148`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:4-6` |  |
| BR-065 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:7-9`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53-53`, `corpus/app/qddssrc/nemp.dspf:27-27` |  |
| BR-066 | MEDIUM | `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:65-66`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:75-76`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:62-63`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:64-76`, `corpus/app/qddssrc/depts.dspf:17-17` |  |
| BR-067 | HIGH | `corpus/app/qddssrc/depts.dspf:2-2`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:71-72`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:78-79` |  |
| BR-068 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:83-92`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:127-130`, `corpus/app/qddssrc/depts.dspf:14-16`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:80-89`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:130-133`, `corpus/app/qddssrc/emps.dspf:16-17` |  |
| BR-069 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:127-130`, `corpus/app/qddssrc/depts.dspf:17-17`, `corpus/app/qrpglesrc/employees.pgm.sqlrpgle:130-133`, `corpus/app/qddssrc/emps.dspf:19-19` |  |
| BR-070 | HIGH | `corpus/app/qddssrc/nemp.dspf:44-44`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:55-78` |  |
| BR-071 | HIGH | `corpus/app/qddssrc/nemp.dspf:44-44`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:60-76` |  |
| BR-072 | HIGH | `corpus/app/qddssrc/nemp.dspf:7-7`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51` |  |
| BR-073 | HIGH | `corpus/app/qddssrc/nemp.dspf:27-27`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53-53`, `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150` |  |
| BR-075 | HIGH | `corpus/app/qsqlsrc/popdept.sqlprc:35-36`, `corpus/app/qsqlsrc/popemp.sqlprc:83-86`, `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:106-109`, `corpus/app/makefile:39-49` |  |
