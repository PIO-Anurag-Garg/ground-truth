# Corpus

## What is in here

`app/` is [IBM's own published sample application](https://github.com/IBM/ibmi-company_system) —
an IBM i department and employee maintenance system in SQLRPGLE, DDS and SQL.
954 lines across 14 source members. It was chosen because it is public, small
enough to audit by hand, and reproducible: any judge can clone it and re-run this
project against it.

`spec/FUNCTIONAL_SPEC.md` is the functional specification the audit is run against.

## How the corpus was built — read this before judging the results

A real twenty-five-year-old application comes with a specification that drifted
away from the code long ago. To reproduce that honestly, and to make the audit's
accuracy measurable rather than merely asserted, the corpus was built in two
stages.

**Stage 1 — write the specification.** IBM Bob read the application and wrote the
functional specification from it, in the voice of a business analyst in 1998,
describing intended behaviour in business language. Bob was instructed never to
reference code and to document what the system is *supposed* to do — so where the
application contains a defect, the specification states the correct intent. Two
rules that transcribed an implementation detail instead of intent were sent back
and rewritten.

**Stage 2 — plant a maintenance changeset.** Six changes were then applied to the
application, of the kind a maintenance programmer makes over two decades: a policy
validation added, a field widened, a function key added, a calculation narrowed, a
validation dropped, a default value changed. The specification was *not* updated —
which is exactly what happens in practice.

The changeset is recorded in `evaluation/ANSWER_KEY.md`, along with six defects
that were already present in IBM's published code before anything was planted.
The answer key is deliberately outside the audit's scope. The audit runs blind.

Nothing in the result was tuned after the fact.
