# Verdict Rubric

There are four possible verdicts. Every rule_id receives exactly one of the
first three. UNDOCUMENTED is a separate finding class, not a rule verdict.

---

## ⚠️ Bias Rule — Read This First

> **When torn between CONFIRMED and UNVERIFIABLE, always choose UNVERIFIABLE.**

A false CONFIRMED is the worst possible output of this audit. It tells a
developer to trust a specification statement that the code does not actually
satisfy. The cost of a missed drift is far higher than the cost of flagging
a rule as unverifiable.

---

## CONFIRMED

**Definition:** The code does exactly what the rule states. You have read the
relevant lines and can cite them directly.

**Criteria:**
- You identified the code path that implements the rule's subject behaviour.
- The code's observable behaviour matches the rule text without interpretation.
- You can cite specific line ranges that prove this.

**Worked example:**

> Rule `AUTH-04`: "A session token must expire after 30 minutes of inactivity."

The verifier finds:

```python
# src/auth/session.py  lines 87–91
INACTIVITY_TIMEOUT = timedelta(minutes=30)

def is_session_valid(session):
    if datetime.utcnow() - session.last_active > INACTIVITY_TIMEOUT:
        return False
```

Verdict: **CONFIRMED**
Citation: `src/auth/session.py:87-91`
Note: "Constant `INACTIVITY_TIMEOUT` is 30 minutes; `is_session_valid` enforces
it on every access check."

---

## DRIFTED

**Definition:** The code's behaviour differs from what the rule states. Both the
rule's claim and the code's actual behaviour must be described and cited.

**Criteria:**
- You found the relevant code path.
- The code does something measurably different from the rule text.
- You can cite the lines that demonstrate the discrepancy.

**Worked example:**

> Rule `AUTH-04`: "A session token must expire after 30 minutes of inactivity."

The verifier finds:

```python
# src/auth/session.py  lines 87–91
INACTIVITY_TIMEOUT = timedelta(minutes=60)

def is_session_valid(session):
    if datetime.utcnow() - session.last_active > INACTIVITY_TIMEOUT:
        return False
```

Verdict: **DRIFTED**
Citation: `src/auth/session.py:87-91`
Rule claims: 30-minute inactivity timeout.
Code implements: 60-minute inactivity timeout.

---

## UNVERIFIABLE

**Definition:** You cannot confirm or deny the rule because either (a) the rule
text is too vague to produce a concrete test, or (b) the subject of the rule
does not appear anywhere in the source tree.

**Criteria (either is sufficient):**
- The rule uses terms like "should", "appropriately", "as needed", or other
  language that admits no single measurable implementation.
- After searching the full source tree (not just hint files), no code can be
  identified as implementing the rule's subject.

**Worked example:**

> Rule `PERF-02`: "The system should respond quickly under normal load."

"Quickly" is undefined; there is no threshold to verify against.

Verdict: **UNVERIFIABLE**
Reason: "Rule text contains no measurable criterion ('quickly'). Cannot confirm
or deny without a numeric threshold."

---

## UNDOCUMENTED (finding class, not a rule verdict)

**Definition:** Behaviour observed in the code that no rule in the specification
describes. This is reported as a separate finding, not assigned to any rule_id.

**Criteria:**
- You read code that implements a non-trivial behaviour.
- After reviewing all rules in your cluster (and the full rule list if needed),
  no rule covers this behaviour.

**Worked example:**

The verifier reads `src/auth/session.py` while verifying cluster `AUTH` and
notices:

```python
# src/auth/session.py  lines 112–117
def invalidate_all_user_sessions(user_id):
    """Invalidates every active session for a user (e.g. after password change)."""
    Session.objects.filter(user_id=user_id, active=True).update(active=False)
```

No rule in the specification mentions bulk session invalidation on password
change.

Finding: **UNDOCUMENTED**
Citation: `src/auth/session.py:112-117`
Description: "All active sessions for a user are invalidated when
`invalidate_all_user_sessions` is called. No specification rule covers this
behaviour."
