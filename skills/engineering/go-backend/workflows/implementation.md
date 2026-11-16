# Implementation

1. Define observable acceptance criteria. For a performance change, record
   a reproducible baseline and compare the same workload afterward.
2. Sketch caller usage, operation input/output, errors, and required durable
   effects. Select recipes for each changed boundary. For a new operation,
   trace entry point through application policy and adapters back to output.
3. Implement the smallest complete slice: application contracts and policy,
   required adapters, transport, then composition. Reuse unchanged components;
   create a schema change only when persistence requirements change.
4. Prove acceptance criteria at the affected boundaries using the testing recipe.
   Run repository-required checks after the complete change. Inspect the diff
   against the selected ownership and compatibility contracts.

*Done when:* the observable behavior passes, required wiring is reachable, and
the diff implements only the requested scope. Report unresolved checks.
