# Investigation

1. State the question and trace the relevant entry point, owners, types,
   dependencies, and observable result. Select guides only for guarantees
   being explained or diagnosed.
2. Resolve uncertain runtime claims with focused observations where available.
   For historical intent, inspect ADRs and history rather than infer motive
   from current code.
3. Explain the path with file references. Separate observed facts, inferences,
   and unknowns; name the next observation that would resolve each material gap.

*Done when:* the question has an evidence-backed answer or a specific unresolved
gap. Keep the investigation read-only unless the user requests a change.
