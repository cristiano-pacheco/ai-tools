# Bricks handoff

Read only for an unverified Bricks API, configuration field, module, or lifecycle contract. A business change with verified unchanged infrastructure does not load this guide.

## 1. Keep application policy here

`go-backend` owns the workflow, responsibilities, naming, and test boundaries. The standalone `bricks` skill owns framework usage. Project contracts override either skill's defaults. Application constructors stay concrete. External factories keep their actual signatures.

## 2. Load the specialist guide

Locate `bricks` through the available skill list. Read its `SKILL.md` once and select the smallest matching guide or recipe. Any Bricks destination named by a backend reference is relative to that skill directory, not this one.

Read each destination once. Do not load guides for every imported dependency. Adapt examples to the application's owned components and accepted layout. A framework tutorial does not select decoration or authorize a test boundary.

## 3. Verify uncertain APIs

Use tutorials first for ordinary usage. For version-sensitive behavior, undocumented APIs, or discrepancies, follow Bricks `references/local-source.md`. A newer checkout does not establish support in the application's selected dependency. Do not upgrade the dependency to fit an example.

If the skill is unavailable, inspect only the relevant locally installed package and its callers:

1. Set `GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off GOVCS='*:off'` before Go queries.
2. Preserve workspace, replacements, vendor mode, alternate module file, and overlays. Resolve the requested package with `go list -find -json` using effective vendor mode or `-mod=readonly`.
3. Read the returned source directory and relevant callers. Stop when the requested contract is supported. Do not fetch modules, modify dependency files, or search the machine for another version.
4. If source or tooling is unavailable, report the limitation and request the missing guide or source. Do not invent framework behavior.

## 4. Resume the backend task

Continue the original playbook. Apply [Test policy](test-policy.md) to the affected guarantees. Record execution evidence and unverified checks. Framework inspection does not prove runtime behavior.
