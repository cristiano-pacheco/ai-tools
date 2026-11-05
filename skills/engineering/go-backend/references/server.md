# Server bootstrap

Read when creating or changing the server process graph. [CLI](cli.md) owns the Cobra lifecycle runner. [Fx](fx.md) owns construction and interface bindings.

## 1. Select the required resources

List the public operations and transports the process exposes. Include shared infrastructure once and each business module once. Add a database, Redis, translation, metrics, or tracing only when the selected behavior needs it. Keep authentication connected to real middleware or session infrastructure. Never fabricate a default actor.

## 2. Compose the process

`cmd/application.go` can expose application composition without hard-coding framework modules in each business module:

```go
package cmd

import "go.uber.org/fx"

func ServerOptions(platform fx.Option, businessModules ...fx.Option) fx.Option {
    options := []fx.Option{platform}
    options = append(options, businessModules...)
    return fx.Options(options...)
}
```

The caller supplies the actual platform and business modules. This example is a composition fragment, not a complete server. For a Bricks server, follow [Bricks handoff](bricks.md) to its Chi setup or complete HTTP recipe. Add only the component guides needed for missing contracts. Do not load all package guides simply because the server imports them.

Provide concrete use cases directly. Add decorator dependencies and publication only for an explicit request or an existing decorated operation being changed.

## 3. Connect the command

Use the existing `NewServerCommand` from [CLI](cli.md). Supply trusted identity and process options at the root. The executable uses a signal-cancelled context, prints one returned error, and sets the exit status after cleanup.

Keep migration execution in its separate [migration command](migration-command.md) when that is the project's deployment contract. A migration-only command does not start HTTP.

## 4. Verify startup and readiness

Use fields supported by the application's resolved dependency. Do not copy a newer version's YAML into an older release. Validate project secrets and pool bounds before use.

Force the intended server consumer in the graph. Distinguish construction, startup, listener readiness, and dependency health. A static health route does not prove database readiness. Listener startup behavior can differ by framework version, so verify the actual installed contract when that guarantee matters.

Done when required routes and operations are reachable, each resource has one owner, configuration loads, and readiness and shutdown have execution evidence or explicit gaps.
