# Adversarial Re-verification Report

**Sample source:** `evaluation/redteam_sample.json` (seed 20260830, 11 rules)  
**Method:** One independent subagent per rule, instructed to assume the CONFIRMED verdict is wrong and attempt to refute it. Parent auditor verified all contested findings directly against source files before finalising verdicts.

---

## Results Table

| Rule | Original Verdict | Redteam Finding | Final Call | Reasoning |
|------|-----------------|-----------------|------------|-----------|
| **BR-004** | CONFIRMED | SHOULD-BE-DRIFTED (subagent) → **Overturned** | **UPHELD** | `SFLSIZ(9999)` in `depts.dspf:12` is a platform-enforced subfile ceiling on IBM i: writing past it raises a runtime exception. No application-level guard is needed. The `rrn` variable is `Zoned(4:0)` (max 9,999), providing a second ceiling. The concern that "the loop is unbounded at the application level" is correct but irrelevant — the platform enforces the constraint and the spec is satisfied. |
| **BR-008** | CONFIRMED | **UPHELD** | **UPHELD** | `XSEL = *Blank; Update SFLDTA;` at `depts.pgm.sqlrpgle:153-157` runs after every processed option, with an identical pattern at `employees.pgm.sqlrpgle:152-156`. No code path bypasses this clearing. |
| **BR-009** | CONFIRMED | SHOULD-BE-DRIFTED (subagent) → **Overturned** | **UPHELD** | The subagent incorrectly inferred that DEPTS is a subprogram because it uses `Dcl-Pr Employees ExtPgm` — those are prototypes for programs DEPTS *calls*, not for how DEPTS is called. DEPTS has no `Dcl-Pi` at the module level, confirming it is the top-level program. `*INLR = *ON; Return` at `depts.pgm.sqlrpgle:78-79` genuinely terminates the application. F3 is defined at `depts.dspf:2` and displayed at `depts.dspf:30`. |
| **BR-019** | CONFIRMED | **UPHELD** | **UPHELD** | `nemp.dspf:7` defines `XID` with usage `O` (output-only in DDS), preventing user input. `newemp.pgm.sqlrpgle:45-50` assigns the auto-generated ID before the first `Exfmt`. Both clauses — auto-assigned and non-alterable — hold. |
| **BR-038** | CONFIRMED | **UPHELD** | **UPHELD** | `nemp.dspf:44` defines `XERR` at row 15 with `COLOR(RED)`. All input fields end at row 13. The message area is genuinely below the inputs and genuinely red. No alternative error-display mechanism (e.g. `ERRMSG`) found. |
| **BR-045** | CONFIRMED | **UPHELD** | **UPHELD** | `nemp.dspf:2` defines only `CA12(12)` — F12 is the sole declared command-attention key. Enter is handled implicitly at `newemp.pgm.sqlrpgle:65-72`. No other CA/CF keys are defined. All three sub-clauses hold. |
| **BR-049** | CONFIRMED | **UPHELD** | **UPHELD** | `newemp.pgm.sqlrpgle:175-191` initialises `result` as `Char(6)` filled with `'000000'`, computes `startI = 7 - %len(asChar)`, and uses `%subst(result:startI)` to right-align digits, producing correct zero-padding. `employee.table:4` confirms `EMPNO CHAR(6)`. Both storage and padding clauses hold. |
| **BR-054** | CONFIRMED | **UPHELD** | **UPHELD** | `popdept.sqlprc:5` declares `popdept()` with no parameters; `popdept.sqlprc:7` explicitly states `Result Sets 0`. The body contains only `INSERT` operations. Both no-input and no-result-set clauses hold. |
| **BR-055** | CONFIRMED | **UPHELD** | **UPHELD** | `popemp.sqlprc:10-12` declares `Nationality char(2) default 'gb'` (optional parameter, default applied). `popemp.sqlprc:43-45` sets the loop range to insert exactly `count+200 - (count+1) + 1 = 200` rows. All three clauses hold. |
| **BR-065** | CONFIRMED | **UPHELD** | **UPHELD** | `depts.pgm.sqlrpgle:148-150` is the only caller of `NewEmp`. `newemp.pgm.sqlrpgle:7-9` accepts `currentDepartment` and populates `XDEPT` at line 53. `nemp.dspf:27` marks `XDEPT` as `O` (output-only). All three clauses hold. |
| **BR-074** | CONFIRMED | **UPHELD** | **SHOULD-BE-UNVERIFIABLE** | See detailed analysis below. |

---

## Detailed Finding: BR-074

**Rule:** *"The current release of the system provides no facility for modifying or deleting existing department or employee records through the interactive screens."*

This is the **forced-in absence claim** (noted in the sample as "a known-hard absence claim").

The original audit cited code showing what the application *does* support (options `5` and `8`, Exfmt calls, etc.) as evidence that modify/delete is absent. That is backwards reasoning.

Independent re-verification confirms:

- A complete search of `corpus/app` for `UPDATE` and `DELETE` in `*.sqlrpgle` and `*.rpgleinc` returns **zero matches** (only `Update SFLDTA` — a subfile record-selection UI update — appears, not a data-table update).
- `*.sqlprc` files contain no `UPDATE` or `DELETE` against `DEPARTMENT` or `EMPLOYEE`.
- Option handlers in `depts.pgm.sqlrpgle:144-151` and `employees.pgm.sqlrpgle:147-150` only branch on `'5'` and `'8'`; no `'2'=Change` or `'4'=Delete` codes exist.
- No display-file defines change/delete screens.

The absence is real. **However**, absence of evidence is not the same as confirmed absence in a formal audit. The citations provided in `drift.json` for BR-074 point to lines that show what *is* present (options 5 and 8, Enter handler, screen definitions) — they do not constitute proof of absence. A fully rigorous audit would record this as **UNVERIFIABLE** because no finite set of code citations can prove that nothing was omitted; the verdict rests on the completeness of the search, which cannot itself be cited.

The audit was **over-confident** on BR-074: the finding is almost certainly correct in practice, but the epistemological status is UNVERIFIABLE, not CONFIRMED.

---

## Summary

| Outcome | Count | Rule IDs |
|---------|-------|----------|
| UPHELD (survived adversarial review) | 10 | BR-008, BR-009, BR-019, BR-038, BR-045, BR-049, BR-054, BR-055, BR-065, BR-004 |
| SHOULD-BE-UNVERIFIABLE | 1 | BR-074 |
| SHOULD-BE-DRIFTED | 0 | — |

**10 of 11 sampled CONFIRMED verdicts survive adversarial review.**

**The audit was over-confident on exactly 1 verdict (BR-074).** BR-074 is an absence claim ("no facility for modifying or deleting") that was marked CONFIRMED with citations pointing at code that does something else. The absence is genuinely supported by a full-corpus search, but a CONFIRMED verdict requires citable evidence — and absence cannot be cited. The correct verdict for BR-074 is **UNVERIFIABLE**.

Two subagent challenges (BR-004 and BR-009) were initially assessed as SHOULD-BE-DRIFTED but were overturned on direct re-examination: BR-004 because `SFLSIZ` is a platform-enforced hard limit on IBM i, and BR-009 because DEPTS has no program-entry parameters and is genuinely the top-level application program.
