# Locale

Read when changing translated application messages or locale ownership.

1. Keep each module's locale assets beside its owned error catalog. Use singular `locale/` for new modules. The process owns language selection and translation infrastructure.
2. Allocate stable globally unique message keys. Do not rely on module registration or Fx group order to resolve duplicate keys.
3. For Bricks JSON shape, fallback language, filesystem contribution, and translation behavior, follow [Bricks handoff](bricks.md) to `references/i18n/usage.md`. Load the locale support guide only when changing its direct contract.
4. Compare every owned error code with every required locale. Exercise a translated outcome through the actual public translation boundary. Loaded files or a valid graph do not establish message completeness.
5. Preserve direct use-case execution by default. Locale files do not opt an operation into decorators. Read [Usecase decorator](usecase-decorator.md) only for selected decoration work.

Done when required messages resolve, duplicate keys cannot depend on load order, and translation preserves the published code and status. [Error](error.md) owns identity and cause assertions.
