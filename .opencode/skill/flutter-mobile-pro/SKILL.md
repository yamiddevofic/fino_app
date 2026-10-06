---
name: flutter-mobile-pro
description: Desarrollo mobile profesional con Flutter/Dart — apps con interfaces modernas, minimalistas y funcionales, arquitectura limpia, design system propio, accesibilidad y buen rendimiento. Usa esta skill siempre que el usuario pida crear, diseñar, refactorizar o revisar una app móvil, pantallas, widgets, temas, navegación o estado en Flutter, o mencione Flutter, Dart, Riverpod, go_router, Material 3, "app móvil", "UI móvil" o "diseño de pantallas", aunque no diga explícitamente "skill" ni "profesional". Also use for English requests like "build a Flutter app", "Flutter UI", "mobile screen design", "Flutter architecture".
---

# Flutter Mobile Pro

Esta skill guía a Claude para construir apps Flutter que se vean y se sientan como producto profesional: **minimalistas** (poco ruido, mucho espacio, una sola voz visual), **modernas** (Material 3, tipografía cuidada, micro-animaciones sutiles) y **funcionales** (cada elemento tiene un propósito, todos los estados están cubiertos, es rápida y accesible).

La razón de fondo: el código Flutter genérico tiende a verse "de tutorial" (colores por defecto, sombras pesadas, espaciados inconsistentes, sin estados de carga/error). Lo que separa una app profesional es un **sistema de diseño consistente** y **estados completos**, no más widgets.

## Flujo de trabajo

1. **Entender antes de codificar.** Si el pedido es una app o feature nueva, confirma en pocas líneas: objetivo, usuarios, pantallas clave, backend/datos (API, Firebase, local), plataformas (Android/iOS). Si ya hay proyecto, lee `pubspec.yaml` y la estructura de `lib/` y **respeta lo existente** (estado, navegación, convenciones) en lugar de imponer el stack de abajo.
2. **Definir el sistema de diseño primero** (colores, tipografía, espaciado, radios) — ver Parte 1. Todo widget posterior consume esos tokens; nunca valores sueltos.
3. **Estructurar por features** — ver Parte 2.
4. **Construir pantallas con todos sus estados**: cargando, vacío, error, éxito, sin conexión.
5. **Verificar**: `dart format .`, `flutter analyze`, y tests de widgets para lo crítico. Si tienes entorno con Flutter, ejecútalos; si no, revisa el código contra el checklist final.

## Stack por defecto (proyectos nuevos)

| Área | Elección | Por qué |
|---|---|---|
| UI | Material 3 (`useMaterial3: true`) + tema propio | Base sólida y accesible, personalizable |
| Estado | Riverpod (`flutter_riverpod`) | Testeable, sin `BuildContext`, escalable |
| Navegación | `go_router` | Deep links, guards, rutas declarativas |
| Red | `dio` + repositorios | Interceptores, cancelación, manejo de errores |
| Modelos | `freezed` + `json_serializable` (o clases simples si es pequeño) | Inmutabilidad, `copyWith` |
| Almacenamiento | `shared_preferences` (simple), `flutter_secure_storage` (tokens), `drift` (relacional local) | Cada uno para su caso |
| Tipografía | `google_fonts` (Inter / Plus Jakarta Sans) o fuente empaquetada | Look moderno consistente |
| Iconos | Material Symbols / `lucide_icons` | Trazo uniforme |

No agregues paquetes por costumbre: cada dependencia es deuda. Si algo se resuelve con 20 líneas, escríbelo.

## Principios de diseño minimalista

- **Una acción principal por pantalla.** Un solo botón relleno (primario); el resto `outlined` o `text`.
- **Espacio > decoración.** Prefiere aire y jerarquía tipográfica a cajas, divisores y sombras. Bordes de 1px con baja opacidad en lugar de elevaciones marcadas.
- **Paleta contenida:** neutros (fondo, superficie, texto) + **un** color de acento. Semánticos (éxito/error/aviso) solo para estados.
- **Escala tipográfica corta** (5–6 estilos) con pesos 400/500/600. Jerarquía por tamaño y peso, no por color.
- **Cuadrícula de 4/8 dp** para todo espaciado; márgenes de pantalla de 20–24 dp.
- **Radios consistentes** (ej. 12 controles, 16 tarjetas, 24 sheets).
- **Movimiento con intención:** 150–300 ms, `Curves.easeOutCubic`, para transiciones de estado; nada decorativo que retrase al usuario.
- **Modo claro y oscuro** desde el inicio, generados desde los mismos tokens.
- **Contenido real**, no lorem ipsum: los diseños se juzgan con datos verosímiles (nombres largos, listas vacías, textos en 2 líneas).

## Estados: la mitad del trabajo

Toda pantalla que dependa de datos debe manejar explícitamente:

- **Loading** → skeleton/shimmer sutil (no spinner a pantalla completa salvo primera carga).
- **Empty** → ilustración simple o icono + mensaje útil + acción.
- **Error** → mensaje humano (no `e.toString()`), botón "Reintentar".
- **Offline / datos viejos** → mostrar caché y avisar discretamente.
- **Éxito** → feedback breve (snackbar, haptic ligero), sin diálogos bloqueantes innecesarios.

Con Riverpod esto es natural: `ref.watch(provider).when(data:, loading:, error:)` y widgets reutilizables `AppLoading`, `AppEmpty`, `AppError` (ver Parte 3).

## Reglas de código

- Widgets pequeños y `const` siempre que se pueda; extrae **clases** `StatelessWidget`, no métodos `_buildX()` (los métodos no se optimizan ni se testean igual).
- Nunca lógica de negocio ni llamadas de red en `build()` ni en widgets: van en repositorios/notifiers.
- Colores, textos y espaciados salen de `Theme.of(context)` / tokens (`context.colors`, `context.text`, `AppSpacing`). Cero `Color(0xFF...)` sueltos en pantallas.
- Usa `withValues(alpha: x)` (no `withOpacity`, deprecado en Flutter 3.27+).
- Listas largas: `ListView.builder` / `SliverList`; imágenes remotas con `cached_network_image` y placeholders.
- Async seguro: comprueba `context.mounted` tras `await` antes de usar el contexto.
- Textos de usuario en `l10n` (ARB) si la app será multi-idioma; si no, centralízalos igual en una clase para migrar luego.
- Null-safety estricta, `analysis_options.yaml` con `flutter_lints` (o `very_good_analysis` en equipos).
- Errores tipados (`sealed class Failure`) en la capa de datos; la UI traduce a mensajes.

## Accesibilidad y responsive

- Áreas táctiles ≥ 48×48 dp; contraste texto/fondo ≥ 4.5:1.
- Respeta escalado de texto del sistema (no fijes alturas que rompan con `textScaler` 1.5).
- `Semantics`/`tooltip` en botones de solo icono; no transmitas información solo con color.
- Usa `SafeArea`, `LayoutBuilder`/`MediaQuery` y anchos máximos (`ConstrainedBox(maxWidth: 600)`) para tablets y landscape.
- Teclado: `resizeToAvoidBottomInset`, `TextInputAction`, `autofillHints`, scroll al enfocar.

## Rendimiento

- `const` constructores; separa partes que cambian para acotar rebuilds (`select` en Riverpod).
- Evita `Opacity`/`ClipRRect` anidados en listas; prefiere `DecoratedBox` y `color.withValues`.
- `RepaintBoundary` solo si el profiler lo justifica. Mide con DevTools antes de optimizar.
- Precarga fuentes/imágenes críticas; usa `Hero` y transiciones nativas de `go_router`.

## Seguridad básica

- Tokens en `flutter_secure_storage`, nunca en `SharedPreferences`.
- Claves y URLs por `--dart-define` / `.env` fuera del repositorio; no incluir secretos en el cliente.
- Validar entradas en cliente **y** servidor; HTTPS obligatorio.

## Entregables al construir una app/feature

1. Estructura de carpetas propuesta (breve).
2. `pubspec.yaml` con solo las dependencias necesarias.
3. Tema (`app_theme.dart`, tokens) y componentes base si son nuevos.
4. Pantallas + notifiers/repositorios, con todos los estados.
5. Rutas (`app_router.dart`).
6. Notas cortas: decisiones, cómo correr (`flutter pub get`, `flutter run`), y qué falta.

Entrega archivos completos y coherentes (imports correctos, sin `// TODO` ocultando lógica clave). Si el código es largo, crea los archivos en lugar de pegarlo todo en el chat.

## Guía de secciones

- **Parte 1 · Sistema de diseño** → al crear o ajustar tema, colores, tipografía, espaciado, dark mode.
- **Parte 2 · Arquitectura** → al estructurar proyecto, estado, navegación, capa de datos, tests.
- **Parte 3 · Componentes base** → al construir widgets base (botón, campo, tarjeta, estados, bottom sheet, navegación inferior).

## Checklist final (revisa antes de entregar)

- [ ] ¿Un solo CTA primario por pantalla y jerarquía clara?
- [ ] ¿Todo sale de tokens/tema (sin colores ni tamaños sueltos)?
- [ ] ¿Modo oscuro funciona y mantiene contraste?
- [ ] ¿Loading, vacío, error y offline cubiertos?
- [ ] ¿Áreas táctiles ≥ 48 dp y textos escalables?
- [ ] ¿Sin lógica de negocio en widgets? ¿`context.mounted` tras awaits?
- [ ] ¿`const` donde aplica, listas con builder, imágenes con caché?
- [ ] ¿`dart format` y `flutter analyze` limpios?
- [ ] ¿Solo dependencias justificadas?

---

# Parte 1 · Sistema de diseño (tokens + tema)

Índice: [Filosofía](#filosofía) · [Tokens](#tokens) · [Color](#color) · [Tipografía](#tipografía) · [Tema](#tema-material-3) · [Extensiones de contexto](#extensiones-de-contexto) · [Elección de acento](#elección-de-acento)

### Filosofía

Neutros que hacen el 90% del trabajo + un acento. Modo claro/oscuro derivados de la misma definición. Todo valor visual vive aquí; las pantallas solo lo consumen.

### Tokens

```dart
// lib/core/theme/tokens.dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Margen horizontal estándar de pantalla.
  static const double screen = 20;
}

abstract final class AppRadius {
  static const double control = 12; // botones, inputs, chips
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
}
```

### Color

Paleta neutra cálida/fría a elección + acento. Ejemplo (acento índigo):

```dart
// lib/core/theme/colors.dart
import 'package:flutter/material.dart';

abstract final class AppPalette {
  // Acento
  static const accent = Color(0xFF4F46E5);

  // Claro
  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111827);
  static const lightTextMuted = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFE5E7EB);

  // Oscuro
  static const darkBg = Color(0xFF0B0B0F);
  static const darkSurface = Color(0xFF15151B);
  static const darkText = Color(0xFFF3F4F6);
  static const darkTextMuted = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF26262E);

  // Semánticos (solo para estados)
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}
```

Reglas: texto principal sobre fondo ≥ 4.5:1; el acento como fondo de botón lleva texto blanco (verifica contraste); en oscuro, evita blanco puro y negro puro (fatiga visual).

### Tipografía

Escala corta. Peso y tamaño crean jerarquía.

```dart
// lib/core/theme/typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildTextTheme(Color color, Color muted) {
  final base = GoogleFonts.interTextTheme();
  return base.copyWith(
    displaySmall: base.displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.5, color: color),
    headlineSmall: base.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.2, color: color),
    titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: color),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: color),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: color),
    labelLarge: base.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: color),
    bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.4, color: muted),
  );
}
```

Para apps que deben funcionar offline desde el primer arranque, empaqueta la fuente en `assets/fonts` en vez de `google_fonts`.

### Tema Material 3

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppPalette.lightBg,
        surface: AppPalette.lightSurface,
        text: AppPalette.lightText,
        muted: AppPalette.lightTextMuted,
        border: AppPalette.lightBorder,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppPalette.darkBg,
        surface: AppPalette.darkSurface,
        text: AppPalette.darkText,
        muted: AppPalette.darkTextMuted,
        border: AppPalette.darkBorder,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color text,
    required Color muted,
    required Color border,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.accent,
      brightness: brightness,
    ).copyWith(
      primary: AppPalette.accent,
      surface: surface,
      onSurface: text,
      outline: border,
      error: AppPalette.danger,
    );

    final radius = BorderRadius.circular(AppRadius.control);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: buildTextTheme(text, muted),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppPalette.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppPalette.danger)),
        hintStyle: TextStyle(color: muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppPalette.accent.withValues(alpha: 0.12),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
```

En `MaterialApp.router`: `theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system`.

### Extensiones de contexto

Atajos para no repetir `Theme.of(context)` y mantener el código de pantallas corto:

```dart
// lib/core/theme/context_x.dart
import 'package:flutter/material.dart';

extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get muted => colors.onSurface.withValues(alpha: 0.6);
}
```

### Elección de acento

Ofrece al usuario 2–3 opciones según el tipo de app, en vez de decidir sin contexto:

| Tipo de app | Acento sugerido |
|---|---|
| Productividad / finanzas | Índigo `#4F46E5`, azul `#2563EB` |
| Salud / bienestar / agro | Verde `#16A34A`, teal `#0D9488` |
| Comercio / food | Naranja `#EA580C`, rojo coral `#E11D48` |
| Creativo / social | Violeta `#7C3AED`, magenta `#C026D3` |

Cambiar el acento debe requerir tocar **una** constante (`AppPalette.accent`).


---

# Parte 2 · Arquitectura, estado, navegación y datos

Índice: [Estructura](#estructura-por-features) · [Capas](#capas) · [Riverpod](#estado-con-riverpod) · [Navegación](#navegación-go_router) · [Red y errores](#red-y-errores) · [Tests](#tests) · [Proyecto existente](#si-el-proyecto-ya-existe)

### Estructura por features

Agrupa por funcionalidad, no por tipo de archivo. Escala mejor y evita carpetas `widgets/` con 80 archivos.

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router + temas
├── core/
│   ├── theme/                  # tokens, colores, tipografía, app_theme
│   ├── router/app_router.dart
│   ├── network/dio_client.dart
│   ├── errors/failure.dart
│   ├── widgets/                # componentes base compartidos (AppButton, AppError…)
│   └── utils/
└── features/
    └── tasks/
        ├── data/               # repositorios, DTOs, fuentes de datos
        ├── domain/             # entidades (opcional si es simple)
        └── presentation/
            ├── tasks_screen.dart
            ├── task_detail_screen.dart
            ├── providers/      # notifiers / providers
            └── widgets/        # widgets exclusivos de la feature
```

Regla de dependencia: `presentation → data/domain`, nunca al revés. `core` no importa de `features`.

### Capas

- **Presentation:** widgets + notifiers. Solo pinta estado y dispara acciones.
- **Data:** repositorios que hablan con API/DB y devuelven modelos o lanzan `Failure`.
- **Domain (opcional):** entidades y casos de uso solo si hay lógica de negocio real; en apps pequeñas sobra, no lo fuerces.

### Estado con Riverpod

```dart
// features/tasks/presentation/providers/tasks_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(ref.watch(dioProvider)),
);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() => ref.watch(tasksRepositoryProvider).fetchAll();

  Future<void> add(String title) async {
    final repo = ref.read(tasksRepositoryProvider);
    final previous = state.valueOrNull ?? [];
    // Optimistic update: la UI responde al instante
    state = AsyncData([Task.temp(title), ...previous]);
    try {
      final created = await repo.create(title);
      state = AsyncData([created, ...previous]);
    } catch (_) {
      state = AsyncData(previous); // rollback
      rethrow;
    }
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);
```

Uso en UI, con los tres estados siempre resueltos:

```dart
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: tasks.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(
          message: 'No pudimos cargar tus tareas.',
          onRetry: () => ref.invalidate(tasksProvider),
        ),
        data: (items) => items.isEmpty
            ? const AppEmpty(icon: Icons.checklist_rounded, title: 'Sin tareas', message: 'Crea la primera para empezar.')
            : RefreshIndicator(
                onRefresh: () => ref.refresh(tasksProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => TaskTile(task: items[i]),
                ),
              ),
      ),
    );
  }
}
```

Pautas: `ref.watch` en `build`, `ref.read` en callbacks; `select` para reconstruir solo lo necesario; `autoDispose` por defecto para estado de pantalla; estado inmutable.

### Navegación (go_router)

```dart
// core/router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.valueOrNull != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(shell: shell), // NavigationBar
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const TasksScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});
```

Usa `StatefulShellRoute` para navegación inferior con estado preservado por pestaña. Rutas con nombre/constantes centralizadas para evitar strings dispersos.

### Red y errores

```dart
// core/errors/failure.dart
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;
}
class NetworkFailure extends Failure { const NetworkFailure() : super('Sin conexión. Revisa tu internet.'); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Tu sesión expiró.'); }
class ServerFailure extends Failure { const ServerFailure([super.message = 'Algo salió mal. Intenta de nuevo.']); }
```

Mapea `DioException` a `Failure` en el repositorio (timeouts/conexión → `NetworkFailure`, 401 → `UnauthorizedFailure`). Interceptor de `dio` para token y refresh. La UI muestra `failure.message`, nunca la excepción cruda.

### Tests

- **Unit:** repositorios (con `dio` mockeado) y notifiers (`ProviderContainer` con overrides).
- **Widget:** pantallas críticas en sus estados (loading/empty/error/data) con `ProviderScope(overrides: [...])`.
- **Golden (opcional):** componentes base del design system en claro y oscuro para detectar regresiones visuales.
- **Integration:** solo flujos clave (login, checkout).

### Si el proyecto ya existe

Adapta, no reescribas: si usa Bloc, Provider, GetX o `setState`, mantén esa convención en el código nuevo y sugiere migraciones solo si el usuario lo pide o hay un problema real. Aplica igualmente tokens/tema, estados completos y accesibilidad, que son independientes del gestor de estado.


---

# Parte 3 · Componentes base

Índice: [AppButton](#appbutton) · [AppTextField](#apptextfield) · [AppCard](#appcard) · [Estados: loading, empty, error](#estados) · [Bottom sheet](#bottom-sheet) · [Navegación inferior](#navegación-inferior) · [Feedback](#feedback) · [Pantalla ejemplo](#pantalla-ejemplo-login-minimalista)

Van en `lib/core/widgets/`. Regla: si un patrón aparece 3 veces, se vuelve componente. Todos consumen tokens/tema.

### AppButton

Botón con estado de carga; evita doble tap y mantiene el ancho para que no "salte" el layout.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    void handle() {
      HapticFeedback.selectionClick();
      onPressed!.call();
    }

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: enabled ? handle : null, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: enabled ? handle : null, child: child),
      AppButtonVariant.text => TextButton(onPressed: enabled ? handle : null, child: child),
    };
  }
}
```

### AppTextField

Etiqueta arriba (no flotante) es más limpia y legible; el error aparece bajo el campo.

```dart
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.suffix,
  });

  final String label;
  final String? hint, errorText;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint, errorText: errorText, suffixIcon: suffix),
        ),
      ],
    );
  }
}
```

### AppCard

Superficie con borde fino; sin sombra. Hace la tarjeta pulsable con feedback de tinta.

```dart
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}
```

### Estados

```dart
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
}

class AppEmpty extends StatelessWidget {
  const AppEmpty({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: t.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: t.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class AppError extends StatelessWidget {
  const AppError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Algo no salió bien',
        message: message,
        action: onRetry == null
            ? null
            : SizedBox(
                width: 180,
                child: AppButton(label: 'Reintentar', onPressed: onRetry, variant: AppButtonVariant.secondary),
              ),
      );
}
```

Para carga de listas, prefiere skeletons (`shimmer` o contenedores con `AnimatedOpacity` pulsando) con la misma forma que el contenido real.

### Bottom sheet

Preferible al diálogo para acciones y formularios cortos en móvil.

```dart
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}
```

### Navegación inferior

Máximo 3–5 destinos; iconos outline/filled para estado seleccionado.

```dart
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
```

### Feedback

- **Snackbar** flotante y corto para confirmaciones y errores leves; con acción "Deshacer" cuando sea posible en vez de pedir confirmación.
- **Diálogo** solo para acciones destructivas irreversibles.
- **Haptics** ligeros (`selectionClick`, `lightImpact`) en acciones clave; nunca en exceso.

### Pantalla ejemplo: login minimalista

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(_email.text.trim(), _password.text);
    } on Failure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenido', style: context.text.displaySmall),
                    const SizedBox(height: 8),
                    Text('Inicia sesión para continuar', style: context.text.bodyMedium?.copyWith(color: context.muted)),
                    const SizedBox(height: 32),
                    AppTextField(label: 'Correo', controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email]),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Contraseña', controller: _password, obscure: true, textInputAction: TextInputAction.done, autofillHints: const [AutofillHints.password]),
                    const SizedBox(height: 24),
                    AppButton(label: 'Entrar', loading: _loading, onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Nota el patrón: tokens, `SafeArea`, ancho máximo para tablets, `autofillHints`, `dispose` de controllers, `mounted` tras `await`, estado de carga en el botón.