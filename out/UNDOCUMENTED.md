# Undocumented Behaviours — COSYS-FS-001 v1.0

> This document lists behaviours observed in the codebase that are **not
> described by any rule in the specification**. Each entry proposes a candidate
> specification statement that would cover the observed behaviour.
> Citations reference the source files and line numbers where the behaviour
> was found.

---

## U-001 — Salary minimum band (HR policy floor)
**Confidence:** HIGH

**Observed behaviour:**  
The New Employee screen rejects any salary below 30,000 with the message
`Salary below minimum band`. A source comment attributes this to an HR policy
dated 2015-03. No database CHECK constraint backs this up — the rule exists
only in the application layer.

**Candidate specification statement:**  
> The system shall reject any salary value below 30,000 on the grounds that it
> falls below the minimum pay band. If the entered salary is a valid number but
> less than 30,000, the system shall display the message: `Salary below minimum
> band`. The user shall remain on the New Employee screen to correct the value.

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-150`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147)

---

## U-002 — BIRTHDATE stored as current system date on new employee insert
**Confidence:** HIGH

**Observed behaviour:**  
`HandleInsert()` unconditionally assigns `%Date` (today's date) to the
`BIRTHDATE` column when creating a new employee record. The New Employee screen
presents no input field for date of birth. A developer comment reads: "we don't
actually care about these fields."

**Candidate specification statement:**  
> The New Employee screen does not collect the employee's date of birth. On a
> successful submission, the system shall store the current system date in the
> `BIRTHDATE` column as a placeholder value.

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96-98`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:96)

---

## U-003 — F5=Refresh available on Employee List screen
**Confidence:** HIGH

**Observed behaviour:**  
The Employee List screen footer shows `F5=Refresh F12=Back`. Pressing F5 calls
`LoadSubfile()`, which re-queries the database and repopulates the subfile from
scratch. The salary total (`XTOT`) is **not** recalculated on refresh — it
remains the value fetched when the screen was first opened.

**Candidate specification statement:**  
> The key F5=Refresh shall be available on the Employee List screen. Pressing
> F5 shall reload the employee list from the database, reflecting any changes
> made since the screen was opened. The Total figure shall not be updated by a
> refresh; it retains the value calculated on initial entry.

**Citations:**  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67-68`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:67)  
— [`corpus/app/qddssrc/emps.dspf:3`](corpus/app/qddssrc/emps.dspf:3)

---

## U-004 — Option 5 on Employee List screen is an unfinished stub
**Confidence:** MEDIUM

**Observed behaviour:**  
The Employee List subfile contains an `Opt` column (`XSEL`). When option `5` is
entered against an employee row and Enter is pressed, the code executes
`DSPLY XID` — a debug-only system call that displays the employee number in a
plain message box. No navigation to an employee detail screen occurs.

**Candidate specification statement:**  
> The Employee List screen provides an Opt column. Entering option 5 against
> an employee row and pressing Enter shall display a detail view for that
> employee. *(Note: as of the current release this action is not fully
> implemented; pressing option 5 displays the employee identifier only.)*

**Citations:**  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147-150`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147)  
— [`corpus/app/qddssrc/emps.dspf:7`](corpus/app/qddssrc/emps.dspf:7)

---

## U-005 — Employee identifier increments by 100, not 1
**Confidence:** HIGH

**Observed behaviour:**  
`getNewEmpId()` computes the next employee identifier as
`MAX(INT(EMPNO)) + 100`, not `+1`. Every new employee's ID therefore skips 99
values above the current maximum. This is already flagged as DRIFTED in
BR-048 but the +100 strategy itself has no specification statement covering
what the increment should be.

**Candidate specification statement:**  
> The system shall assign each new employee identifier by incrementing the
> highest existing identifier by 100. *(See also BR-048 for the authoritative
> statement of the intended increment; this candidate rule reflects the
> current implementation only.)*

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182-194`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:182)

---

## U-006 — Invalid option codes on Department Enquiry screen discarded silently
**Confidence:** HIGH

**Observed behaviour:**  
In `depts.pgm.sqlrpgle`, the `HandleInputs` loop processes only option codes
`'5'` and `'8'`. Any other non-blank value entered in the `Opt` column is
silently cleared (`XSEL = *Blank; Update SFLDTA`) with no error message shown
to the user.

**Candidate specification statement:**  
> If the user enters an option code other than 5 or 8 in the Opt column of the
> Department Enquiry screen, the system shall clear the invalid option without
> taking any action and without displaying an error message.

**Citations:**  
— [`corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-157`](corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144)

---

## U-007 — PHONENO column is CHAR(5) but effective format is four digits
**Confidence:** MEDIUM

**Observed behaviour:**  
The `EMPLOYEE` table defines `PHONENO CHAR(5)`, while the New Employee display
field `XTEL` is also `5A`. Test data and the spec treat phone numbers as
four-digit values (e.g. `3978`, `3476`). The fifth character position is not
used or documented, and the CHECK constraint silently operates on a wider range
than the spec intends.

**Candidate specification statement:**  
> The `PHONENO` column in the `EMPLOYEE` table is defined as a five-character
> fixed string. Values stored in this column shall be zero-padded numeric
> strings of up to five digits.

**Citations:**  
— [`corpus/app/qsqlsrc/employee.table:9`](corpus/app/qsqlsrc/employee.table:9)  
— [`corpus/app/qddssrc/nemp.dspf:42`](corpus/app/qddssrc/nemp.dspf:42)  
— [`corpus/app/qtestsrc/empdet.test.sqlrpgle:44-49`](corpus/app/qtestsrc/empdet.test.sqlrpgle:44)

---

## U-008 — Application layer does not enforce upper phone number range
**Confidence:** HIGH

**Observed behaviour:**  
`GetError()` validates that `XTEL` is non-blank and parses as an integer, but
applies no upper-bound check (e.g. ≤ 9998 or ≤ 99998). The only upper-bound
enforcement is the database CHECK constraint. A user entering `99999` would
receive a database constraint error rather than a friendly application message.

**Candidate specification statement:**  
> After confirming that the Phone field is numeric, the system shall validate
> that the value falls within the permitted range. If the value exceeds the
> upper bound, the system shall display an appropriate error message before
> attempting the database insert.

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-162`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153)

---

## U-009 — Employee List exits silently when department not found
**Confidence:** HIGH

**Observed behaviour:**  
In `employees.pgm.sqlrpgle`, if `getDeptDetail()` returns `found = *off`
(i.e. the department passed to the screen does not exist in the database), the
program sets `Exit = *On` and returns immediately without displaying any screen
or error message.

**Candidate specification statement:**  
> If the Employee List screen is opened for a department that does not exist in
> the database, the system shall display an appropriate error message and return
> the user to the Department Enquiry screen. The screen shall not be left blank
> without explanation.

**Citations:**  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52-56`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:52)

---

## U-010 — Salary total is salary-only (bonus/commission excluded); field is 7 digits before decimal
**Confidence:** HIGH

**Observed behaviour:**  
This is already recorded as DRIFTED (BR-015, BR-016, BR-017). The undocumented
aspect is that the `empdet` module also computes a separate `netincome` value
(`salary + bonus + comm`) that is returned from `getDeptDetail()` but is never
displayed on any screen.

**Candidate specification statement:**  
> The `getDeptDetail` service module shall return both a `totalsalaries` figure
> (sum of salary only) and a `netincome` figure (sum of salary, bonus, and
> commission). The `netincome` figure is available for future use but is not
> currently displayed on any interactive screen.

**Citations:**  
— [`corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`](corpus/app/qrpglesrc/empdet.sqlrpgle:42)  
— [`corpus/app/qrpgleref/empdet.rpgleinc:13-14`](corpus/app/qrpgleref/empdet.rpgleinc:13)

---

## U-011 — Test expects salary total to include bonus and commission (test vs. code inconsistency)
**Confidence:** HIGH

**Observed behaviour:**  
The unit test in `empdet.test.sqlrpgle` asserts `totalsalaries = 90160` for
department A00, a value that equals `salary + bonus + commission` for the
fixture employees — not salary alone. The production SQL aggregates only
`salary`, so the test would fail against the current code.

**Candidate specification statement:**  
> *(Test contract)* The `getDeptDetail` procedure shall return a `totalsalaries`
> value equal to the sum of `salary + bonus + commission` for all employees in
> the given department, as asserted by the automated test suite.

**Citations:**  
— [`corpus/app/qtestsrc/empdet.test.sqlrpgle:117-122`](corpus/app/qtestsrc/empdet.test.sqlrpgle:117)  
— [`corpus/app/qrpglesrc/empdet.sqlrpgle:46-48`](corpus/app/qrpglesrc/empdet.sqlrpgle:46)

---

## U-012 — DEPARTMENT cascade-delete via ADMRDEPT foreign key
**Confidence:** HIGH

**Observed behaviour:**  
The `DEPARTMENT` table defines a self-referential foreign key (`ROD`) on
`ADMRDEPT` referencing `DEPTNO` with `ON DELETE CASCADE`. Deleting a department
will automatically cascade to delete all departments that list it as their
administering department.

**Candidate specification statement:**  
> When a department record is deleted from the system, all department records
> for which that department is the administering department (`ADMRDEPT`) shall
> also be automatically deleted by the database cascade rule. This cascade
> applies recursively.

*(Note: this is already partially described by a note in Section 2.1 of the
specification: "When a department is deleted, all departments that administered
by it are deleted as well." However no corresponding rule (BR-xxx) was
extracted; it should be formalised as a numbered rule.)*

**Citations:**  
— [`corpus/app/qsqlsrc/department.table:11-14`](corpus/app/qsqlsrc/department.table:11)

---

## U-013 — Department population routine: ADMRDEPT randomly assigned, FK violation likely
**Confidence:** HIGH

**Observed behaviour:**  
`popdept.sqlprc` assigns `ADMRDEPT` a randomly generated 3-character value
(`right('000' || cast(rand()*1000 as int), 3)`). Because `ADMRDEPT` has a
foreign key constraint requiring it to match an existing `DEPTNO`, this
random value will almost never satisfy the constraint. The procedure contains
no error handling for this case.

**Candidate specification statement:**  
> The department population routine shall set the `ADMRDEPT` column of each
> generated department to a value that satisfies the self-referential foreign
> key constraint (i.e. the value must match a `DEPTNO` already present in the
> table). The routine shall handle the case where no valid administering
> department exists.

**Citations:**  
— [`corpus/app/qsqlsrc/popdept.sqlprc:22`](corpus/app/qsqlsrc/popdept.sqlprc:22)  
— [`corpus/app/qsqlsrc/department.table:11-14`](corpus/app/qsqlsrc/department.table:11)

---

## U-014 — Department population routine: duplicate DEPTNO collision risk
**Confidence:** MEDIUM

**Observed behaviour:**  
`DEPTNO` in `popdept.sqlprc` is generated as a random integer in the range
0–999 zero-padded to 3 characters. Across five iterations there is a non-zero
probability of collision, which would cause a primary-key violation. No
retry or uniqueness-check logic exists.

**Candidate specification statement:**  
> The department population routine shall ensure that each generated department
> identifier is unique. If a collision is detected, the routine shall generate
> a new identifier and retry before inserting the record.

**Citations:**  
— [`corpus/app/qsqlsrc/popdept.sqlprc:20`](corpus/app/qsqlsrc/popdept.sqlprc:20)

---

## U-015 — Location value formula: `'Location ' || deptno`
**Confidence:** MEDIUM

**Observed behaviour:**  
The location value for each department created by `popdept.sqlprc` is always
`'Location ' || deptno` (e.g. `'Location 042'`). The spec states only that the
location is "derived from the department identifier" without specifying the
format.

**Candidate specification statement:**  
> The location value for each generated department shall be the string
> `'Location '` concatenated with the department identifier (e.g. if the
> identifier is `042`, the location shall be `'Location 042'`).

**Citations:**  
— [`corpus/app/qsqlsrc/popdept.sqlprc:23`](corpus/app/qsqlsrc/popdept.sqlprc:23)

---

## U-016 — Employee population routine: default nationality is `'gb'`
**Confidence:** HIGH

**Observed behaviour:**  
The `popemp.sqlprc` procedure declares `in Nationality char(2) default 'gb'`.
The spec (BR-055, BR-062) only states that a default nationality is applied
without naming it.

**Candidate specification statement:**  
> When the employee population routine is called without specifying a
> nationality, it shall default to the nationality code `'gb'` (Great Britain).

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:11`](corpus/app/qsqlsrc/popemp.sqlprc:11)

---

## U-017 — Employee population routine: external HTTP dependency on randomuser.me
**Confidence:** HIGH

**Observed behaviour:**  
`popemp.sqlprc` issues one HTTP GET request to
`https://randomuser.me/api/?nat=<Nationality>` per employee row (200 calls per
run) using the DB2 `SYSTOOLS.HTTPGETCLOB` function to fetch generated names and
gender.

**Candidate specification statement:**  
> The employee population routine shall obtain generated employee names and
> gender by calling the external API at `https://randomuser.me/api/` with the
> nationality parameter. The routine requires network access to
> `randomuser.me` to function correctly. If the API is unavailable, the
> routine will fail.

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:49-56`](corpus/app/qsqlsrc/popemp.sqlprc:49)  
— [`corpus/app/qsqlsrc/popemp.sqlprc:61-63`](corpus/app/qsqlsrc/popemp.sqlprc:61)

---

## U-018 — Employee population routine: SEX field from API gender response
**Confidence:** HIGH

**Observed behaviour:**  
The `SEX` column is set to the first character of the `gender` string returned
by the randomuser.me API (e.g. `'m'` or `'f'`).

**Candidate specification statement:**  
> Each generated employee shall be assigned a sex value derived from the gender
> returned by the name-generation API. The value stored shall be the first
> character of the gender string (`'m'` for male, `'f'` for female).

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:76`](corpus/app/qsqlsrc/popemp.sqlprc:76)

---

## U-019 — Employee population routine: MIDINIT derived from first character of first name
**Confidence:** HIGH

**Observed behaviour:**  
`popemp.sqlprc` sets `MIDINIT = substr(first_name, 1, 1)` — the first letter
of the employee's first name, not a genuine middle initial.

**Candidate specification statement:**  
> Each generated employee's middle initial shall be set to the first character
> of the employee's first name. *(Note: this is a synthetic approximation, not
> a true middle initial.)*

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:62`](corpus/app/qsqlsrc/popemp.sqlprc:62)

---

## U-020 — Employee population routine: JOB code format is `'JOB'` + 4 random hex chars
**Confidence:** HIGH

**Observed behaviour:**  
Each generated employee's `JOB` column is set to `'JOB' || substr(HEX(rand()), 1, 4)`
(e.g. `'JOB3F9A'`).

**Candidate specification statement:**  
> Each generated employee shall be assigned a job code consisting of the
> prefix `'JOB'` followed by four randomly generated hexadecimal characters
> (e.g. `'JOB3F9A'`).

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:74`](corpus/app/qsqlsrc/popemp.sqlprc:74)

---

## U-021 — Employee population routine: PHONENO generated as 4-char hex (constraint conflict)
**Confidence:** HIGH

**Observed behaviour:**  
`popemp.sqlprc` generates `PHONENO` as `substr(HEX(rand()), 1, 4)`, a
four-character hex string (e.g. `'3F7A'`). The `EMPLOYEE` table defines
`PHONENO CHAR(5)` with a CHECK constraint requiring all-numeric values in
the range `'00000'–'99998'`. Hex values containing A–F will violate this
constraint at runtime.

**Candidate specification statement:**  
> The employee population routine shall generate telephone extension values
> that satisfy the `PHONENO` column constraint. Generated phone values shall
> be numeric strings of appropriate length and shall fall within the permitted
> range enforced by the database constraint.

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:72`](corpus/app/qsqlsrc/popemp.sqlprc:72)  
— [`corpus/app/qsqlsrc/employee.table:26-28`](corpus/app/qsqlsrc/employee.table:26)

---

## U-022 — Employee population routine: IDs assigned by COUNT, not MAX (deletion risk)
**Confidence:** MEDIUM

**Observed behaviour:**  
`popemp.sqlprc` computes the starting employee number as `COUNT(empno) + 1`
(not `MAX(empno) + 1`). If any rows have been deleted, the count-based start
value may duplicate an existing `EMPNO`, causing a primary-key violation.

**Candidate specification statement:**  
> The employee population routine shall determine the starting employee
> identifier by finding the highest existing numeric `EMPNO` value and
> incrementing from there. Row count shall not be used as a proxy for the
> maximum identifier.

**Citations:**  
— [`corpus/app/qsqlsrc/popemp.sqlprc:43-45`](corpus/app/qsqlsrc/popemp.sqlprc:43)  
— [`corpus/app/qsqlsrc/popemp.sqlprc:60`](corpus/app/qsqlsrc/popemp.sqlprc:60)

---

## U-023 — `WITH NC` (no-commit) enforced at compile time via COMMIT(*NONE)
**Confidence:** HIGH

**Observed behaviour:**  
All three RPGLE programs (`DEPTS`, `EMPLOYEES`, `NEWEMP`) are compiled with
`COMMIT(*NONE)` in the makefile. This disables journal-based commitment control
at the object level — a stronger commitment than the spec implies (which only
states that no explicit commit is required from the calling environment).

**Candidate specification statement:**  
> All interactive programs in the system shall be compiled with
> `COMMIT(*NONE)`, disabling commitment control at the object level. This
> ensures that inserts take effect immediately and cannot be rolled back by the
> calling environment.

**Citations:**  
— [`corpus/app/makefile:39-49`](corpus/app/makefile:39)

---

## U-024 — `getDeptDetail` returns 'N/A' for NULL LOCATION values
**Confidence:** MEDIUM

**Observed behaviour:**  
The `getDeptDetail` SQL uses `COALESCE(location, 'N/A')` to substitute the
string `'N/A'` whenever the department `LOCATION` column is NULL.

**Candidate specification statement:**  
> When a department's location is not set (NULL), the system shall display the
> value `'N/A'` in any location field shown to the user.

**Citations:**  
— [`corpus/app/qrpglesrc/empdet.sqlrpgle:42-56`](corpus/app/qrpglesrc/empdet.sqlrpgle:42)

---

## U-025 — Test fixture contains a salary below the 30,000 minimum band
**Confidence:** HIGH

**Observed behaviour:**  
The test data in `empdet.test.sqlrpgle` inserts an employee with salary
`29250.00`, which is below the 30,000 minimum enforced by `GetError()`. Running
the full test suite against production code would fail for any test path that
attempts to create this employee via the interactive screen.

**Candidate specification statement:**  
> *(Test-data constraint)* All test fixture employees shall have salaries at or
> above the application's minimum salary band (currently 30,000) so that test
> data can be re-created via the interactive New Employee screen without
> triggering the salary validation error.

**Citations:**  
— [`corpus/app/qtestsrc/empdet.test.sqlrpgle:44-49`](corpus/app/qtestsrc/empdet.test.sqlrpgle:44)

---

## U-026 — Subfile display order is non-deterministic (no ORDER BY)
**Confidence:** MEDIUM

**Observed behaviour:**  
Neither the department subfile query in `depts.pgm.sqlrpgle` nor the employee
subfile query in `employees.pgm.sqlrpgle` includes an `ORDER BY` clause. The
display order of rows is therefore determined by the database storage engine and
may vary between runs or after data changes.

**Candidate specification statement:**  
> The department list shall be displayed in ascending order by department
> identifier. The employee list shall be displayed in ascending order by
> employee identifier.

**Citations:**  
— [`corpus/app/qrpglesrc/depts.pgm.sqlrpgle:101-120`](corpus/app/qrpglesrc/depts.pgm.sqlrpgle:101)  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:98-115`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:98)

---

## U-027 — F3 declared as CA (Command Attention) — screen changes discarded on exit
**Confidence:** MEDIUM

**Observed behaviour:**  
F3 is declared `CA03(03)` in `depts.dspf`, not `CF03`. A Command Attention
key returns the AID byte without transmitting modified screen data to the
program. Any value entered or changed in the `Opt` column is silently
discarded when the user presses F3.

**Candidate specification statement:**  
> Pressing F3 on the Department Enquiry screen shall discard any option codes
> the user has entered but not yet submitted, and shall exit the application
> immediately.

**Citations:**  
— [`corpus/app/qddssrc/depts.dspf:2`](corpus/app/qddssrc/depts.dspf:2)

---

## U-028 — `mypgm.pgm.rpgle` is an orphaned hello-world program
**Confidence:** LOW

**Observed behaviour:**  
The file `corpus/app/qrpglesrc/mypgm.pgm.rpgle` contains a simple "Hello
World" RPGLE program. It is not referenced by any other file in the application
source tree and has no functional role in the system.

**Candidate specification statement:**  
> *(Housekeeping)* The file `mypgm.pgm.rpgle` is a development artefact with
> no functional purpose and should be removed from the application source
> library.

**Citations:**  
— [`corpus/app/qrpglesrc/mypgm.pgm.rpgle:1`](corpus/app/qrpglesrc/mypgm.pgm.rpgle:1)

---

## U-029 — XNAME display field is 38 chars but DEPTNAME is VARCHAR(36)
**Confidence:** MEDIUM

**Observed behaviour:**  
The Department Enquiry subfile field `XNAME` is declared `38A` in `depts.dspf`,
two characters wider than the `DEPTNAME VARCHAR(36)` column in the department
table. The two trailing characters are always blank.

**Candidate specification statement:**  
> The Name column on the Department Enquiry screen shall accommodate up to 36
> characters, matching the maximum width of the department name in the database.

**Citations:**  
— [`corpus/app/qddssrc/depts.dspf:8`](corpus/app/qddssrc/depts.dspf:8)  
— [`corpus/app/qsqlsrc/department.table:5`](corpus/app/qsqlsrc/department.table:5)

---

## U-030 — Department and employee subfiles are fully loaded into memory before display
**Confidence:** HIGH

**Observed behaviour:**  
Both `depts.pgm.sqlrpgle` and `employees.pgm.sqlrpgle` use a `LoadSubfile()`
procedure that fetches all rows from the SQL cursor in a loop and writes every
row to the subfile before showing the screen. There is no lazy paging or
demand-load mechanism.

**Candidate specification statement:**  
> On entry to the Department Enquiry screen and the Employee List screen, the
> system shall load all matching records into the subfile in a single pass
> before displaying the screen to the user.

**Citations:**  
— [`corpus/app/qrpglesrc/depts.pgm.sqlrpgle:94-131`](corpus/app/qrpglesrc/depts.pgm.sqlrpgle:94)  
— [`corpus/app/qrpglesrc/employees.pgm.sqlrpgle:80-135`](corpus/app/qrpglesrc/employees.pgm.sqlrpgle:80)

---

## U-031 — `HandleInsert` uses program parameter for WORKDEPT, not screen field
**Confidence:** HIGH

**Observed behaviour:**  
`HandleInsert()` assigns `newEmp.WORKDEPT = currentDepartment` (the value
passed in by the calling program), not `XDEPT` (the screen display field).
The screen field is output-only, so in practice they are the same value —
but if `XDEPT` were ever made editable, the user's entry would be silently
ignored.

**Candidate specification statement:**  
> The assigned department for a newly created employee shall always be derived
> from the department passed to the New Employee screen by the calling program,
> not from any value displayed or entered on the screen itself.

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:85-112`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:85)

---

## U-032 — Stale TODO comment in New Employee program
**Confidence:** MEDIUM

**Observed behaviour:**  
`newemp.pgm.sqlrpgle` contains a TODO comment on line 5: *"need a way to let
the parent program pass in a department id"*. The `dcl-pi` parameter interface
that fulfils this requirement already exists and is fully used.

**Candidate specification statement:**  
> *(Maintenance note)* The TODO comment on line 5 of `newemp.pgm.sqlrpgle` is
> obsolete and should be removed.

**Citations:**  
— [`corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:5`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:5)
