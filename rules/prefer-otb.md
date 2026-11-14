# Prefer off-the-shelf (OTB) over hand-rolled

**Rule: if an OTB solution satisfies the requirement, use it. Hand-roll only when OTB fails a real, current requirement, and prove that failure with a test.**

Hand-rolled code is incomplete and non-deterministic by default: it covers only the cases its author thought of, and it needs maintenance forever. OTB code is tested by many users, maintained by others and behaves the same on every run.

**Scope:** a component with its own logic, such as parsing, validation, protocol handling, authentication, retry, scheduling or classification. A few lines of plumbing around an OTB call are not a component; skip the check for them.

OTB means any of these, in this search order:
1. A library, tool or feature already in this repo (`go.mod`, `MODULE.bazel`, `requirements.txt`, `package.json`, existing helpers).
2. The language standard library and its official tools (`go/ast`, `go doc`, `net/url`, `jsonschema`).
3. A widely used maintained package or CLI for the ecosystem. Add a new dependency only through the repo's own process (for example Gazelle and the lock file in a Bazel repo), never by editing generated build files by hand.

## Decision procedure (follow in order)

1. **Write the requirements** as a short list. For each, say where it comes from (ticket, design, security rule, real data). Question a requirement you cannot source; do not silently drop it, and never drop a security or privacy constraint without the owner's say.
2. **Check the requirements are real.** Measure against real data (counts from the repo, real fixtures, real files). A requirement that never occurs in real data is not a reason to reject OTB.
3. **Find candidates**, in the search order above. Name at least the best OTB candidate for every component you are about to write or keep.
4. **Test each candidate** against the requirement cases with real or realistic inputs. Show the output.
5. **Decide:**
   - OTB passes every real requirement: use it. Hand-written glue may wrap it, and the glue stays minimal.
   - OTB fails a real requirement in a test: hand-roll only that part, and say which test failed.
   - OTB passes after configuration (a flag, a filter, a single-call API): use it configured. A bad default is not a failure.

## Reasons that never justify rejecting OTB

- "We already built it." Existing hand-rolled code gets no protection. Re-evaluate it the same way as new code, and do it without defending it.
- "The default behaviour does X." Check whether it is configurable first.
- "It is an unlikely edge case." Prove it occurs in real data, or drop it.
- "It adds a dependency." Quantify it: already in the lock file? how many transitive packages? A dependency already in the repo costs nothing.
- "It is another layer or abstraction." The layer you would hand-write instead is also a layer, and it is untested.
- "I think it would not work." Run it. A rejection without a test is an opinion.
- A requirement you invented or inflated to fit the existing design.

## Valid reasons to reject OTB

- It fails a real requirement in a test you ran.
- It breaks a proven hard constraint (a secret that must not leave a process, data that must not be stored), shown by the constraint's source and a concrete path that breaks it.
- It is unmaintained, unsafe or incompatible with a license constraint, with the source named.
- No OTB candidate exists. Say what you searched.

## Example (SQL read check)

Hand-rolled: `sqlparse` plus a hand-kept keyword list. OTB candidate: a real SQL parser (`sqlglot`). Test: 15 statements, including `SELECT name AS copy FROM t`. Result: the keyword list refused the valid read, the parser made 0 errors, and the parser needs no list to maintain. Decision: use the parser. Reason it was nearly rejected, and why that was invalid: "no failing case", asserted without a test.

## Existing designs

Re-evaluating an existing hand-rolled component is analysis and is always allowed. Replacing it is a design reversal: label it "reversal", show the OTB check, and wait for the owner's approval before changing code or documents (your "never walk back a design" rule). An additive OTB fix that keeps the capability needs no waiting beyond the normal "propose first" rule.

## Determinism

A check must be a real parser, compiler tool, schema or typed result. Never build a gate on regex, keywords or substring matching over code or prose. This also applies to keyword deny lists inside "parsers". See `CLAUDE.local.md` ("No heuristic or regex checks").

## Required output: the OTB check

Any design, proposal, review or pull request that adds or keeps a hand-rolled component must contain this block. Without it the work is incomplete.

```
OTB check: <component>
Requirement: <what it must do, and the source>
Candidates tried: <name, version> -> <result of the test, with the evidence>
Decision: use OTB | hand-roll <part only>
Reason (if hand-rolled): <the failing test or the proven constraint>
```

## Enforcement

- Before sending any answer that proposes, keeps or defends hand-rolled code, ask yourself: did I name the OTB candidate, did I test it, and is my reason on the valid list? If not, run the check before answering.
- When the user asks "why not OTB?" or challenges a hand-rolled design, do not argue. Re-run the check from step 1 and report the result, including where your earlier reasons were wrong.
- When reviewing code or a design, report a hand-rolled component without an OTB check as a defect.
- Never drop an OTB option in a summary without recording the evidence that rejected it.
