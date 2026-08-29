"""
export_bob_sessions.py - export this project's IBM Bob task sessions to Markdown.

Bob 2.x keeps task history in a SQLite database at ~/.bob/db/bob.db. This script
copies it (the live file is WAL-journalled and in use), selects every task whose
project is this repository, and writes one Markdown transcript per top-level task
with its subagents attached, plus an index carrying the token and cost accounting.

Usage:
    python scripts/export_bob_sessions.py [output_dir] [project_substring]
"""
import json, os, shutil, sqlite3, sys, tempfile
from datetime import datetime
from pathlib import Path

TOOL_OUTPUT_CAP = 1500          # tool results are truncated; assistant text never is


def load_db() -> sqlite3.Connection:
    src = Path.home() / ".bob" / "db" / "bob.db"
    if not src.exists():
        sys.exit(f"Bob database not found at {src}")
    tmp = Path(tempfile.mkdtemp()) / "bob.db"
    for suffix in ("", "-wal", "-shm"):
        s = Path(str(src) + suffix)
        if s.exists():
            shutil.copy2(s, str(tmp) + suffix)
    con = sqlite3.connect(tmp)
    con.row_factory = sqlite3.Row
    return con


def jload(s, default=None):
    try:
        return json.loads(s) if s else (default if default is not None else {})
    except Exception:
        return default if default is not None else {}


def stamp(ms):
    return datetime.fromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M:%S")


def slug(text, n=48):
    keep = "".join(ch if ch.isalnum() or ch in " -" else " " for ch in (text or "task"))
    return "-".join(keep.split())[:n].strip("-").lower() or "task"


def render_message(row) -> list[str]:
    out, data = [], jload(row["data"])
    role, content = row["role"], (data.get("content") or "").strip()

    if role == "user":
        out.append("### Operator\n")
        out.append("```\n" + content + "\n```\n")
    elif role == "assistant":
        if content:
            out.append("### Bob\n\n" + content + "\n")
        for call in data.get("toolCalls") or []:
            args = call.get("arguments") or {}
            if isinstance(args, dict):
                brief = ", ".join(f"{k}={str(v)[:70]!r}" for k, v in list(args.items())[:3])
            else:
                brief = str(args)[:140]
            out.append(f"- **tool** `{call.get('name')}` — {brief}\n")
    elif role == "tool":
        sig = ((data.get("toolUsage") or {}).get("signature") or {})
        body = content if len(content) <= TOOL_OUTPUT_CAP else \
            content[:TOOL_OUTPUT_CAP] + f"\n... [{len(content) - TOOL_OUTPUT_CAP} more characters truncated by the exporter]"
        out.append(f"<details><summary>result of <code>{sig.get('name', 'tool')}</code></summary>\n\n```\n{body}\n```\n\n</details>\n")
    return out


def main():
    outdir = Path(sys.argv[1] if len(sys.argv) > 1 else "bob_sessions")
    needle = sys.argv[2] if len(sys.argv) > 2 else "ground-truth"
    outdir.mkdir(parents=True, exist_ok=True)
    con = load_db()

    tasks = [dict(r) for r in con.execute(
        "select * from tasks where project_id like ? order by created_at", (f"%{needle}%",))]
    if not tasks:
        sys.exit(f"no tasks found for project matching {needle!r}")

    # skip tasks that were opened but never used - they carry no evidence
    # Subagents keep their output in the parent's tool results rather than in
    # messages, so only top-level tasks are filtered on having a transcript.
    used = {r[0] for r in con.execute("select distinct task_id from messages")}
    tasks = [t for t in tasks
             if t["task_type"] != "normal" or t["id"] in used]
    parents = [t for t in tasks if t["task_type"] == "normal"]
    children: dict[str, list] = {}
    for t in tasks:
        if t["task_type"] != "normal":
            children.setdefault(t["parent_id"], []).append(t)

    index, grand = [], {"cost": 0.0, "output": 0, "input": 0}
    for i, p in enumerate(parents, 1):
        kids = sorted(children.get(p["id"], []), key=lambda k: k["created_at"])
        pc = jload(p["costs"])
        kc = [jload(k["costs"]) for k in kids]
        total = pc.get("cost", 0) + sum(c.get("cost", 0) for c in kc)
        out_tok = pc.get("output", 0) + sum(c.get("output", 0) for c in kc)
        in_tok = pc.get("input", 0) + sum(c.get("input", 0) for c in kc)
        grand["cost"] += total; grand["output"] += out_tok; grand["input"] += in_tok

        title = (p["title"] or "untitled").strip().replace("\n", " ")
        name = f"{i:02d}-{slug(title)}.md"
        L = [f"# Session {i:02d} — {title[:110]}\n",
             f"- task id `{p['id']}`",
             f"- started {stamp(p['created_at'])}, last activity {stamp(p['updated_at'])}",
             f"- subagents spawned: **{len(kids)}**",
             f"- tokens in {in_tok:,} / out {out_tok:,}",
             f"- spend for this session including subagents: **{total:.2f}**\n", "---\n"]
        for row in con.execute("select * from messages where task_id=? order by id", (p["id"],)):
            L += render_message(row)
        if kids:
            L.append("\n---\n\n## Subagents\n")
            L.append("Each ran with its own clean context and reported back to the session above.\n")
            for j, k in enumerate(kids, 1):
                c = jload(k["costs"])
                L.append(f"\n### Subagent {j:02d} — `{k['id']}`\n")
                L.append(f"spend {c.get('cost', 0):.3f} · out {c.get('output', 0):,} tokens · "
                         f"{stamp(k['created_at'])} to {stamp(k['updated_at'])}\n")
                L.append("**Brief given to it:**\n\n```\n" + (k["title"] or "").strip()[:1200] + "\n```\n")
                for row in con.execute("select * from messages where task_id=? order by id", (k["id"],)):
                    L += render_message(row)
        (outdir / name).write_text("\n".join(L), encoding="utf-8")
        index.append((i, name, title, len(kids), in_tok, out_tok, pc.get("cost", 0), total,
                      stamp(p["created_at"]), stamp(p["updated_at"]), p["id"]))
        print(f"wrote {name}  ({len(kids)} subagents)")

    idx = ["# Bob task sessions\n",
           "Exported from Bob's own task database with "
           "[`scripts/export_bob_sessions.py`](../scripts/export_bob_sessions.py), so the "
           "accounting below is Bob's own record rather than a hand-written summary.\n",
           f"**{len(parents)} top-level sessions, {len(tasks) - len(parents)} subagents, "
           f"{grand['output']:,} output tokens.**\n",
           "The **session** column is the figure Bob shows in the app for that task on its "
           "own. The **with subagents** column adds the spend of every subagent it spawned, "
           "which the in-app badge does not include. The screenshots in this folder show the "
           "first number; the second is the true cost of the work.\n",
           "Each row links its transcript and the Task Summary screenshot taken from Bob. "
           "The task id in the screenshot matches the id at the head of the transcript, so "
           "any figure here can be traced back to the tool that produced it.\n",
           "| # | Session | Task id | Subagents | Tokens out | Session | With subagents | Screenshot |",
           "|---|---------|---------|-----------|------------|---------|----------------|------------|"]
    for i, name, title, nk, ti, to, own, tc, st, en, tid in index:
        idx.append(f"| {i:02d} | [{title[:52]}]({name}) | `{tid[:12]}` | {nk} | {to:,} | "
                   f"{own:.2f} | **{tc:.2f}** | [png]({i:02d}-task-summary.png) |")
    idx.append(f"\n**Total spend across all sessions: {grand['cost']:.2f}**\n")
    (outdir / "SESSIONS.md").write_text("\n".join(idx), encoding="utf-8")
    print(f"\nwrote {outdir/'SESSIONS.md'}")


if __name__ == "__main__":
    main()
