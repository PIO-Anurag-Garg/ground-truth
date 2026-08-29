# Drift Report

## Summary

| Metric | Count |
|---|---|
| Total rules in spec | 75 |
| Verdicts rendered | 11 |
| Undocumented behaviours | 2 |
| Missing verdicts | 65 |
| Validation problems | 3 |

### By verdict
| Verdict | Count |
|---|---|
| CONFIRMED | 7 |
| DRIFTED | 3 |
| UNVERIFIABLE | 1 |
| UNDOCUMENTED | 2 |
| MISSING_VERDICT | 65 |

### By confidence
| Confidence | Count |
|---|---|
| HIGH | 8 |
| MEDIUM | 1 |
| LOW | 2 |

---
## Drifted Rules

### BR-005 — HIGH confidence
- **Spec says:** Screen shall display a selection column labelled Opt.
- **Code does:** Variable is named XSEL internally; screen label not verified in DDS.
- **Citations:** `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:134-158`
- **Note:** Need to check DDS source for actual column label.

### BR-028 — HIGH confidence
- **Spec says:** First field must not be blank; error message: 'First name cannot be blank'.
- **Code does:** Validates XFIRST empty and returns 'First name cannot be blank' — matches spec.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:119-121`
- **Note:** Marked DRIFTED only as a demo; in reality this is CONFIRMED.

### BR-032 — HIGH confidence
- **Spec says:** Job field must not be blank; error message: 'Job cannot be blank'.
- **Code does:** XJOB empty check returns 'Phone number cannot be blank' instead of 'Job cannot be blank'.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:133-135`
- **Note:** Wrong error message wired to the Job field check — likely copy-paste bug.

---
## Undocumented Behaviours

### No citation on undocumented finding — LOW confidence
- **Code does:** Code does something undocumented.
- **Why it matters:** Intentional missing citation to trigger validation error.
- **Citations:** —

### Salary minimum band enforcement — HIGH confidence
- **Code does:** Rejects any new hire salary below 30,000 with message 'Salary below minimum band'.
- **Why it matters:** The spec says nothing about a minimum salary band; this is undocumented HR policy.
- **Citations:** `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:147-151`

---
## Unverifiable Rules

### BR-029 — LOW confidence
- **Spec says:** Initial field must not be blank; error message: 'Middle initial cannot be blank'.
- **Code does:** No check for XINIT blank found in GetError procedure.
- **Note:** Middle initial validation appears to be missing from the code.

---
## Confirmed Rules (compact)

| Rule ID | Confidence | Citations | Note |
|---|---|---|---|
| BR-002 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:101-125` |  |
| BR-006 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:145-147` |  |
| BR-007 | HIGH | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150` |  |
| BR-008 | MEDIUM | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:152-156` |  |
| BR-BOGUS | HIGH | — | Intentional bad rule_id to trigger validation error. |
| BR-003 | LOW | `corpus/app/qrpglesrc/depts.pgm.sqlrpgle:1-9999` | Citation end_line 9999 intentionally exceeds file length to trigger validation. |
| BR-030 | HIGH | `corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:123-125` |  |

---
## Missing Verdicts

| Rule ID | Section |
|---|---|
| BR-001 | 2.2 EMPLOYEE |
| BR-004 | 3.2 Content and Layout |
| BR-009 | 3.4 Function Keys |
| BR-010 | 4.2 Content and Layout |
| BR-011 | 4.2 Content and Layout |
| BR-012 | 4.2 Content and Layout |
| BR-013 | 4.2 Content and Layout |
| BR-014 | 4.2 Content and Layout |
| BR-015 | 4.3 Salary Total |
| BR-016 | 4.3 Salary Total |
| BR-017 | 4.3 Salary Total |
| BR-018 | 4.4 Function Keys |
| BR-019 | 5.2 Content and Layout |
| BR-020 | 5.2 Content and Layout |
| BR-021 | 5.2 Content and Layout |
| BR-022 | 5.3 Field Descriptions |
| BR-023 | 5.3 Field Descriptions |
| BR-024 | 5.3 Field Descriptions |
| BR-025 | 5.3 Field Descriptions |
| BR-026 | 5.3 Field Descriptions |
| BR-027 | 5.3 Field Descriptions |
| BR-031 | 5.4 Validation Rules |
| BR-033 | 5.4 Validation Rules |
| BR-034 | 5.4 Validation Rules |
| BR-035 | 5.4 Validation Rules |
| BR-036 | 5.4 Validation Rules |
| BR-037 | 5.4 Validation Rules |
| BR-038 | 5.5 Error Message Display |
| BR-039 | 5.5 Error Message Display |
| BR-040 | 5.5 Error Message Display |
| BR-041 | 5.6 Successful Submission |
| BR-042 | 5.6 Successful Submission |
| BR-043 | 5.6 Successful Submission |
| BR-044 | 5.6 Successful Submission |
| BR-045 | 5.7 Function Keys |
| BR-046 | 5.7 Function Keys |
| BR-047 | 6. Employee Identifier Assignment |
| BR-048 | 6. Employee Identifier Assignment |
| BR-049 | 6. Employee Identifier Assignment |
| BR-050 | 6. Employee Identifier Assignment |
| BR-051 | 6. Employee Identifier Assignment |
| BR-052 | 7.1 Department Population Routine |
| BR-053 | 7.1 Department Population Routine |
| BR-054 | 7.1 Department Population Routine |
| BR-055 | 7.2 Employee Population Routine |
| BR-056 | 7.2 Employee Population Routine |
| BR-057 | 7.2 Employee Population Routine |
| BR-058 | 7.2 Employee Population Routine |
| BR-059 | 7.2 Employee Population Routine |
| BR-060 | 7.2 Employee Population Routine |
| BR-061 | 7.2 Employee Population Routine |
| BR-062 | 7.2 Employee Population Routine |
| BR-063 | 8.1 Navigation and Screen Flow |
| BR-064 | 8.1 Navigation and Screen Flow |
| BR-065 | 8.1 Navigation and Screen Flow |
| BR-066 | 8.1 Navigation and Screen Flow |
| BR-067 | 8.1 Navigation and Screen Flow |
| BR-068 | 8.2 Subfile Behaviour |
| BR-069 | 8.2 Subfile Behaviour |
| BR-070 | 8.3 Error Display |
| BR-071 | 8.3 Error Display |
| BR-072 | 8.4 Read-Only Fields |
| BR-073 | 8.4 Read-Only Fields |
| BR-074 | 8.5 Record Scope |
| BR-075 | 8.6 Transaction Control |
