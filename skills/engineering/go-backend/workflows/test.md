# Test

1. Identify the observable contract and current coverage gap. Select the
   [testing](../references/test.md) recipe and the asserted behavior's
   specialist; test framework names do not determine the proof boundary.
2. Add cases at the narrowest boundary that proves the missing guarantee. Exercise
   real infrastructure when the claim concerns its behavior.
3. Run the new cases and required project checks. Inspect assertions for their
   ability to detect a behavior regression rather than a refactor.

*Done when:* the named gap has passing behavioral coverage. Report production
defects discovered during test-only work before expanding into a behavior fix.
