# Bug fix

1. Reproduce the reported failure at its affected boundary using a focused
   test, command, request, or captured evidence. Record expected and actual
   behavior. If reproduction is unavailable, state the limit before claiming
   a cause or correction.
2. Trace the failure to the responsible owner. Select that owner's recipe;
   an endpoint exposing a SQL defect does not automatically select REST work.
3. Correct the mechanism. Add a regression test when it can meaningfully
   distinguish broken from correct behavior; show that it fails before the
   fix and passes afterward when feasible.
4. Repeat the original reproduction and check affected adjacent behavior.
   Run repository-required checks.

*Done when:* the original symptom is corrected with evidence tied to its cause
and required checks pass. An unresolved reproduction or required verification
limit leaves the correction unverified; report that limit explicitly.
