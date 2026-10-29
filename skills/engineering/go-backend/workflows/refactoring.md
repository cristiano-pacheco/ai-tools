# Refactoring

1. Capture the behavior to preserve through existing checks, characterization
   cases, or an observable baseline before changing structure.
2. Identify the current ownership problem and target shape. Select recipes for
   the affected responsibilities; keep unrelated behavior outside scope.
3. Move in small steps while preserving the baseline. Update affected callers
   and remove obsolete paths within scope; keep package names singular.
4. Verify the same observable behavior, inspect the final diff, and run required
   project checks. A build alone does not prove equivalence.

*Done when:* the target structure is in place, behavior remains equivalent,
required checks pass, and no stale callers or references remain within scope.
