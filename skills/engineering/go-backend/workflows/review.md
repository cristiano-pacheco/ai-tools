# Review

1. Establish intended behavior, local contracts, and the review scope. Select
   recipes for every boundary being judged, including unchanged dependencies
   whose guarantees are part of the review.
2. Trace changed behavior through callers, representations, errors, side
   effects, registration, and tests. Check ownership by function body rather
   than its name or package.
3. Validate suspected defects against repository evidence. Report actionable
   findings with location, trigger, consequence, and missing proof. Distinguish
   a project-contract violation from a different but valid architecture.

*Done when:* the scoped boundaries have been assessed and findings or the absence
of findings are reported alongside verification limits. Review stays read-only
unless fixes were requested.
