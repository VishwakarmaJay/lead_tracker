# theme

**Path:** `lib/src/theme/` · **Layer:** shared UI

- `app_color.dart` — `AppColors` theme extension (`light` / `dark`): primary, surfaces, text, success/warning/danger, and lead temperature colors `hot`/`warm`/`cold`.
- `app_text_theme.dart` — `AppTypography` extension: `title`, `subtitle`, `body`, `bodyMuted`, `label`, `caption`.
- `app_theme.dart` — `buildAppTheme(Brightness)` → Material 3 `ThemeData` with both extensions.
- `providers/theme_provider.dart` — `appThemeModeProvider` (keepAlive), default `ThemeMode.system`. Persisted in `app_settings.theme_mode` from Milestone 1.

Widgets read colors and text through `context.colors` / `context.text`, never `Theme.of(context)` or hard-coded colors.
