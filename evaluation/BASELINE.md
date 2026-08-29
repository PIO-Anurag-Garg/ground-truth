# Manual baseline

## What was measured

One rule, attempted by hand, timed.

| Rule | Difficulty label assigned **before** the attempt | Time | Outcome |
|---|---|---|---|
| BR-068 | hard — a display condition spanning two programs | > 20 min | **abandoned, unresolved** |
| BR-011 | easy | — | not attempted |
| BR-033 | medium | — | not attempted |

**Conditions.** The developer has roughly twenty years of IBM i experience. He had
the Word specification and the full source tree open, with grep and editor search
available, and had not previously read this codebase. He did not have access to the
audit output. The stopping condition was a verdict plus a file and line number that
proved it — the same bar the audit had to clear.

**n = 1.** This is reported exactly as it happened and nothing is extrapolated from
it. The rule attempted was the one labelled *hard* before the attempt began, which
is stated here so the figure is not mistaken for a typical rule.

## The argument that does not depend on the stopwatch

The specification contains **75 rules**. Suppose a rule takes five minutes — far
faster than the single attempt actually recorded, and optimistic for any rule that
spans more than one program.

    75 rules x 5 minutes = 6 hours 15 minutes

That is a full working day, for one specification, for one release. It is why a
full manual reconciliation is never scheduled, and why the document had been wrong
for years without anyone noticing.

The audit completed the same 75 rules in **27 minutes**, found eleven rules the code
no longer obeys, and cited a file and line number for every one.

## Honest limits

- One timed attempt is not a distribution. It is a data point, labelled as one.
- The attempted rule was the hardest of the three offered.
- A different developer, or the same developer on the two easier rules, would very
  probably be faster. Nothing here claims otherwise.
