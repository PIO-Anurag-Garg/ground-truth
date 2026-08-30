# Ground Truth

An IBM Bob skill pack that proves, rule by rule, which parts of a legacy specification the code still obeys.

**[Watch the 4-minute demo](https://youtu.be/C2dAUMIdoA8)** · [Full audit report](out/DRIFT_REPORT.md) · [How we verified it](#how-we-know-it-works)

---

## The problem

Every long-lived system has a specification document. It was accurate the day it was written, but the code kept moving and the document did not. Nobody lied — they just fixed a bug, added a policy validation, widened a field — and updating a Word document was not part of the ticket. After a few years the gap is wide enough to cause real harm: a developer reads the spec, believes it, and changes code to match a rule the system silently stopped obeying a decade ago.

Closing that gap by hand is never scheduled, so it never happens. The check requires reading every rule in the specification, finding the relevant code, and producing a verdict with a citation — a file and a line number that proves it. For a modest 75-rule specification, estimating five minutes per rule gives six hours and fifteen minutes of focused work. That is a full working day, for one document, for one release. Nobody books it. A single timed attempt — one developer, twenty years of IBM i experience, source tree and grep available — is documented in [`evaluation/BASELINE.md`](evaluation/BASELINE.md).

The document stays wrong. The next developer trusts it. The cycle repeats.

---

## The result

Run against IBM's own published sample application ([IBM/ibmi-company_system](https://github.com/IBM/ibmi-company_system), 954 lines, 15 source members) with a 75-rule specification:

- **27 minutes** wall clock
- **63 CONFIRMED, 11 DRIFTED, 1 UNVERIFIABLE**
- **32 undocumented behaviours**, de-duplicated from 125 raw candidates
- Every finding carries a file and line number

### Most alarming findings

| Rule | What the spec says | What the code does | File and line |
|------|-------------------|--------------------|---------------|
| BR-032 | Blank Job field → *"Job cannot be blank"* | Returns *"Phone number cannot be blank"* — the wrong field is named | [`newemp.pgm.sqlrpgle:133–135`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle) |
| BR-044 | Error text shall be *"Unable to automatically generate a new ID"* | Text reads *"Unable to automatically generate **an** new ID."* — a typo that breaks any string-match test | [`newemp.pgm.sqlrpgle:48`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle) |
| BR-048 | New identifier = highest current ID + 1, no gaps | Code computes `highestEmpId + 100` — 99 values skipped on every insert | [`newemp.pgm.sqlrpgle:182–192`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle) |
| BR-029 | Middle Initial must not be blank; blank → validation error | Blank-check was removed entirely; a blank value is written directly to a NOT NULL column | [`newemp.pgm.sqlrpgle:114–165`](corpus/app/qrpglesrc/newemp.pgm.sqlrpgle) |
| BR-015/016 | Department total = sum of salary + bonus + commission | `getDeptDetail` aggregates only `salary`; bonus and commission are silently excluded | [`empdet.sqlrpgle:42–56`](corpus/app/qrpglesrc/empdet.sqlrpgle) |
| U-003 | *(not in spec)* | Test fixture contains an employee (GREG ORLANDO) with a salary below the 30,000 minimum band — any test exercising that validation will fail | [`empdet.test.sqlrpgle`](corpus/app/qtestsrc/empdet.test.sqlrpgle) |
| U-014 | *(not in spec)* | `popemp` fetches real names over HTTP from `randomuser.me` via `SYSTOOLS.HTTP_GET` — the data-population routine carries a live internet dependency | [`popemp.sqlprc:43–45`](corpus/app/qsqlsrc/popemp.sqlprc) |
| U-013 | *(not in spec)* | `popemp` derives phone numbers as 4-character hex substrings — values like `A3F2` are stored in a field the spec treats as a 4-digit number | [`popemp.sqlprc`](corpus/app/qsqlsrc/popemp.sqlprc) |

---

## How it works

| Step | Description | Type |
|------|-------------|------|
| 1 | Parse the `.docx` specification; assign a stable `rule_id` to every normative statement → `out/rules.json` | DETERMINISTIC |
| 2 | Report rule count and a sanity sample to the operator | **GATE** — human approval required |
| 3 | Cluster rules by subsystem; assign candidate files to each cluster → `out/worklist.json` | DETERMINISTIC |
| 4 | Spawn one verification subagent per cluster in parallel; each reads the code and writes `out/verdicts/<cluster_id>.json` | AI |
| 5 | Validate all verdict files and merge into `out/drift.json` | DETERMINISTIC |
| 6 | Present all DRIFTED and UNDOCUMENTED findings to the operator | **GATE** — human approval required |
| 7 | Write `out/SPEC_CORRECTED.md` (corrected rule text) and `out/UNDOCUMENTED.md` (candidate spec statements) | AI |
| 8 | Render `out/DRIFT_REPORT.md` and `out/drift.xlsx` from `drift.json` | DETERMINISTIC |
| 9 | Generate test stubs in `out/tests/` for every CONFIRMED rule | AI |

Four of the nine steps consume no model tokens (1, 3, 5, and 8). Two more are hard-stop human approvals that the pipeline cannot skip.

---

## Which IBM Bob capabilities this uses, and where

| Capability | What it does here | Where it lives |
|-----------|-------------------|----------------|
| **Document understanding** | The input is a Word (`.docx`) file; Bob reads it directly and extracts every normative statement | [`scripts/extract_rules.py`](scripts/extract_rules.py) orchestrated by the skill |
| **Subagents and parallel tasks** | 23 rule clusters are verified concurrently — one subagent per cluster | Step 4 in [`.bob/skills/spec-drift/SKILL.md`](.bob/skills/spec-drift/SKILL.md) |
| **Agent mode** | Writes `SPEC_CORRECTED.md`, `UNDOCUMENTED.md`, and test stubs autonomously across multi-file output | Steps 7 and 9 in [`.bob/skills/spec-drift/SKILL.md`](.bob/skills/spec-drift/SKILL.md) |
| **Custom mode — Spec Auditor** | A dedicated mode whose `edit` permission group is scoped to `^out` by `fileRegex`; the auditor cannot alter the source code or the specification it is examining | [`.bob/custom_modes.yaml`](.bob/custom_modes.yaml) |
| **Skills** | `spec-drift` drives the nine-step pipeline; `rule-verifier` is the subagent skill each parallel worker loads | [`.bob/skills/spec-drift/SKILL.md`](.bob/skills/spec-drift/SKILL.md), [`.bob/skills/rule-verifier/SKILL.md`](.bob/skills/rule-verifier/SKILL.md) |
| **Slash command** | `/drift <spec_file> <source_root>` is the single entry point a user types to start the audit | [`.bob/commands/drift.md`](.bob/commands/drift.md) |

---

## Reproduce it

```bash
# 1. Clone this repository
git clone https://github.com/PIO-Anurag-Garg/ground-truth
cd ground-truth

# 2. Install Python dependencies
pip install python-docx openpyxl

# 3. Open IBM Bob and switch to the Spec Auditor custom mode

# 4. Run the audit
/drift corpus/spec/FUNCTIONAL_SPEC.docx corpus/app
```

Bob pauses at Step 2 (rule count confirmation) and Step 6 (findings review). Approve both prompts to receive the full report in `out/`.

| Output file | Contents |
|-------------|----------|
| `out/rules.json` | All 75 extracted rules |
| `out/worklist.json` | 23 rule clusters with candidate files |
| `out/verdicts/` | Per-cluster verdict JSON (one file per cluster) |
| `out/drift.json` | Merged audit results |
| `out/DRIFT_REPORT.md` | Full human-readable report |
| `out/drift.xlsx` | Excel version of the same report |
| `out/SPEC_CORRECTED.md` | Corrected rule text for all 11 DRIFTED rules |
| `out/UNDOCUMENTED.md` | Candidate spec statements for 32 undocumented behaviours |
| `out/tests/` | Test stubs for all 63 CONFIRMED rules |
| `out/REDTEAM.md` | Adversarial re-verification report |

---

## How we know it works

**The corpus was built in two stages, with six changes planted.** Stage 1: IBM Bob read the application and wrote the functional specification from it, in the voice of a 1998 business analyst, stating what the system is *supposed* to do. Where the application already contained a defect, the specification states the correct intent. Stage 2: six maintenance changes were applied to the code without updating the specification — a policy validation added, a field widened, a function key added, a calculation narrowed, a validation removed, a default value changed — exactly what happens in practice over two decades. The planted changes and six pre-existing defects are recorded in [`evaluation/ANSWER_KEY.md`](evaluation/ANSWER_KEY.md); the full methodology is in [`docs/CORPUS.md`](docs/CORPUS.md). The audit ran blind. Nothing in the result was tuned after the fact.

**Recall against the planted changeset: 9 of 9.** The planted changeset produced nine expected findings — seven rules that should read DRIFTED and two behaviours the specification never mentions. The audit found all nine. A tenth expectation, BR-018, was removed from the denominator before scoring because the answer key was wrong, not the audit: BR-018 states that F12 shall be available, not that it is the only key. Adding F5 does not contradict it, so CONFIRMED was correct, and the audit surfaced F5 separately as undocumented. That correction is recorded in [`evaluation/answer_key.json`](evaluation/answer_key.json).

**All six pre-existing defects in IBM's published code were also found.** Three DRIFTED rules and three undocumented behaviours that existed in the IBM repository before any change was planted were independently identified. These are credit above the recall line and were not part of the planted changeset.

**A seeded random sample of CONFIRMED verdicts was adversarially re-verified; 10 of 11 survived.** A red-team run (seed 20260830, documented in [`out/REDTEAM.md`](out/REDTEAM.md)) drew 11 CONFIRMED verdicts and tasked independent subagents to assume each verdict was wrong and attempt to refute it. Ten survived unchanged. The one that did not — BR-074, an absence claim ("no facility for modifying or deleting records") — was correctly downgraded from CONFIRMED to UNVERIFIABLE: the absence is real, but absence cannot be cited, and a CONFIRMED verdict requires citable evidence. That is the correct call.

---

## Honest limits

- **The manual baseline is one timed attempt, n = 1.** A developer with roughly twenty years of IBM i experience, working from the specification and the full source tree with grep and editor search available, abandoned BR-068 unresolved after more than 20 minutes. It was the rule labelled hardest of the three offered before the attempt began. Nothing is extrapolated from it. The six-hour figure in the problem section rests on arithmetic (75 rules × 5 minutes), not on that attempt. The full conditions are in [`evaluation/BASELINE.md`](evaluation/BASELINE.md).

- **The specification was written by Bob from the code.** A specification written by a human analyst in 1998, independently of any code read, would drift differently — and may be harder to extract rules from. This corpus cannot simulate that.

- **125 raw undocumented candidates were de-duplicated to 32.** Both numbers are reported here because publishing only the smaller one would overstate precision. The de-duplication was done by a model; it was not exhaustively hand-audited.

- **The corpus is 954 lines across 15 members.** Behaviour at 100,000 lines is untested. Parallelism helps with scale, but verification quality on a much larger codebase has not been measured.

- **Undocumented findings were spot-checked, not exhaustively verified.** The five undocumented findings recorded in the answer key (P1, P3, E4, E5, E6) were all matched correctly. Five more were afterwards checked by hand against the source and all five held: the hex-derived phone numbers (`popemp.sqlprc:72`), the live HTTP call to randomuser.me (`popemp.sqlprc:49`), the use of `count(empno)+1` rather than `max` when assigning identifiers (`popemp.sqlprc:43`), the middle initial taken from the first letter of the first name (`popemp.sqlprc:62`), and the below-band salary in the test fixture (`empdet.test.sqlrpgle:49`). That is ten of thirty-two verified. The remaining twenty-two were not hand-checked and are reported as candidates.

---

## Repository layout

| Directory | Contents |
|-----------|----------|
| `.bob/` | Custom mode, skills, and slash command that implement the audit pipeline |
| `corpus/` | The application under audit (`corpus/app/`) and its specification (`corpus/spec/`) |
| `scripts/` | Deterministic Python scripts for rule extraction, clustering, merging, and report rendering |
| `out/` | All audit outputs — verdicts, reports, corrected spec, test stubs |
| `evaluation/` | Answer key, baseline timing, and red-team sample — outside the audit's scope |
| `docs/` | Corpus provenance and methodology |
| `bob_sessions/` | Saved IBM Bob session transcripts from the audit runs |
