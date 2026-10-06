---
name: mobile-design
description: Use when designing, building, or reviewing Flutter mobile UI screens, widgets, layouts, themes (light/dark), navigation, forms, cards, accessibility, adaptive/responsive behavior, or visual polish. Trigger on requests like "diseña una pantalla", "mejora la UI", "crea un widget", "estilo moderno", "tema claro/oscuro", "responsive", "adaptativo", "accesibilidad", "Material 3", "Material 3 Expressive", "material_ui", or any work under lib/screen/ and lib/widgets/ in a Flutter app. Use it even when the user only says "arregla cómo se ve esto" on a Flutter screen.
---

# Mobile Design (Flutter)

Guía de diseño visual e interacción para pantallas Flutter modernas,
profesionales y consistentes. Aplica estos principios al crear o modificar
cualquier archivo en `lib/screen/` o widgets reutilizables de UI.

> Última revisión de convenciones: septiembre 2026 (Flutter 3.47).
> Si el proyecto usa una versión de Flutter muy distinta, verifica primero
> el `pubspec.yaml` y `flutter --version`.

## Antes de escribir código: revisa el estado del proyecto

1. **Qué librería de diseño usa el proyecto.** Desde Flutter 3.47, Material y
   Cupertino existen también como paquetes independientes
   (`package:material_ui` y `package:cupertino_ui`), y las librerías
   integradas (`package:flutter/material.dart`) están congeladas desde 3.44
   y pendientes de deprecación formal.
   - Mira los imports existentes y **mantén el mismo estilo** en todo el
     proyecto. No mezcles `package:flutter/material.dart` con
     `package:material_ui/material_ui.dart` en archivos distintos.
   - No migres por iniciativa propia: propón la migración solo si el usuario
     la pide o si el proyecto ya empezó a usar los paquetes nuevos.
   - Para migrar: `dart fix --apply --code=migrate_design_widgets` y luego
     `flutter pub add material_ui` si el fix no lo agregó. Si una dependencia
     de terceros aún importa `flutter/material.dart`, envuelve la app con
     `MaterialUiCompatibilityBridge` dentro de `MaterialApp.builder`; ojo, no
     resuelve conflictos de tipos en firmas públicas (`ColorScheme`,
     `TextTheme`, etc.).
   - Con `material_ui`, los delegados de localización viven en el propio
     paquete: `localizationsDelegates: GlobalMaterialLocalizations.delegates`.
2. **Tema existente** (`temaClaro`/`temaOscuro`) y componentes reutilizables:
   reutiliza antes de crear.

## Principios generales

1. **Consistencia sobre creatividad**: reutiliza colores, tipografías,
   espaciados y formas ya definidos en el tema de la app. No introduzcas un
   estilo nuevo por pantalla.
2. **Jerarquía visual clara**: un título principal, subtítulos secundarios,
   contenido de soporte. El tamaño, peso y color de la tipografía deben
   reflejar la importancia de cada elemento.
3. **Espacio en blanco intencional**: el aire entre elementos comunica orden.
   Prefiere `Padding`/`SizedBox` consistentes (múltiplos de 4 u 8) sobre
   valores arbitrarios (`7`, `13`, `21`).
4. **Feedback inmediato**: toda acción del usuario (guardar, eliminar, error)
   debe tener una respuesta visual: `SnackBar`, cambio de estado, animación
   sutil o indicador de carga.
5. **Accesibilidad como requisito, no extra** (ver sección dedicada).
6. **Touch primero**: resuelve primero una excelente UI táctil; mouse y
   teclado se agregan después como aceleradores.

## Sistema de diseño (usa Theme, no valores sueltos)

- Define colores, tipografía y formas en `ThemeData` (`temaClaro`/
  `temaOscuro` en `lib/main.dart`) y consúmelos con `Theme.of(context)` en
  lugar de repetir `Color(0xFF...)` o `TextStyle` en cada pantalla.
- Prefiere los **roles de `ColorScheme`** (`primary`, `onPrimary`, `surface`,
  `onSurface`, `surfaceContainer`, `error`, etc.) sobre colores fijos. Genera
  el esquema con `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` y
  ajusta solo lo necesario.
- Si una pantalla necesita un color de acento puntual (ej. color de categoría
  en tabs), pásalo como parámetro explícito (como ya hace `HomeScreen` con
  `color`/`colors`), no lo hardcodees dentro del widget hijo.
- Tipografía: usa la familia ya configurada (`Poppins`) para toda la UI y
  toma los estilos de `Theme.of(context).textTheme` (`titleLarge`,
  `bodyMedium`, `labelSmall`...) en vez de armar `TextStyle` a mano.
  Jerarquía sugerida:
  - Título de pantalla/AppBar: 20-24sp, `FontWeight.bold`.
  - Título de tarjeta/sección: 18-20sp, `FontWeight.w600`/`bold`.
  - Texto de cuerpo: 14-16sp, `FontWeight.normal`.
  - Texto de apoyo/hint: 12-13sp, color atenuado usando
    `colorScheme.onSurfaceVariant` (no `Colors.grey` fijo).
- Radios de borde consistentes: 8-12px para tarjetas y campos de texto,
  16-24px para elementos destacados (botones flotantes, hojas modales).
- Elevación moderada: `elevation: 2-4` para tarjetas; evita sombras
  excesivas que compitan con el contenido. En Material 3, la jerarquía de
  superficies (`surfaceContainerLow/High`) comunica profundidad tan bien como
  la sombra.

### Material 3 Expressive (opcional)

Material 3 Expressive (anunciado por Google en I/O 2025) añade animaciones
más marcadas, formas más variadas y color más vivo. En Flutter todavía se
está integrando a `material_ui`; existen paquetes comunitarios (por ejemplo
`material_3_expressive`), pero son de terceros y algunos exigen versiones
recientes de Flutter/Dart.

- No lo adoptes por defecto: solo si el usuario lo pide.
- Si se adopta, hazlo vía tokens de tema, no pantalla por pantalla, para no
  romper la consistencia.

## Modo claro/oscuro

- Toda pantalla nueva debe comportarse correctamente en ambos modos. Sigue el
  patrón existente:
  ```dart
  backgroundColor: widget.modo == ThemeMode.dark
      ? const Color(0xFF070707)
      : widget.color,
  ```
  Para código nuevo, prefiere que ese fondo salga del tema
  (`colorScheme.surface`) y deja este patrón solo donde ya existe.
- No asumas `Colors.white`/`Colors.black` como texto fijo; usa `onSurface`,
  `onPrimary`, etc., o verifica `Theme.of(context).brightness`.
- Los colores de acento (`colorsLight`/`colorsDark` en `lib/main.dart`) deben
  mantener suficiente contraste contra el fondo correspondiente a su modo.
- Para transparencias usa `color.withValues(alpha: 0.5)`.
  **No uses `withOpacity`**: está deprecado por pérdida de precisión.
  Tampoco mezcles la escala de `withAlpha` (0-255) con la de
  `withValues(alpha:)` (0.0-1.0).

## Layout, adaptabilidad y estructura de pantalla

- Estructura estándar de una pantalla de formulario o detalle:
  1. `Scaffold` con `backgroundColor` sensible al tema.
  2. Contenido envuelto en `SingleChildScrollView` cuando pueda exceder la
     altura disponible (formularios, listas largas).
  3. `Card` o `Container` con borde/color de acento para agrupar el
     formulario o resumen principal (patrón ya usado en
     `IncomesScreen`/`ExpensesScreen`).
  4. Padding exterior uniforme (16-30px) y espaciado interno consistente
     entre campos (`SizedBox(height: 16-20)`).
- Envuelve el contenido con `SafeArea` cuando no lo haga ya el `Scaffold`
  (notch, barras del sistema, gestos).
- Para listas de registros (ingresos, gastos, deudas, compras), usa
  `ListView.builder` con `Card` o `ListTile` por item, evita listas sin
  separación visual entre elementos (`Divider` o `SizedBox` pequeño).
- Evita anidar `Column` dentro de `Column` sin necesidad; usa `Expanded`,
  `Flexible` o `Wrap` para resolver overflow en pantallas pequeñas.
- Divide widgets grandes en widgets pequeños y `const`: mejora el tiempo de
  rebuild y facilita adaptar el layout.
- **Diseña por tamaño de ventana, no por dispositivo ni orientación**:
  - Usa `MediaQuery.sizeOf(context)` o `LayoutBuilder`; evita
    `MediaQuery.orientation`/`OrientationBuilder` en la raíz del árbol y no
    preguntes si el dispositivo es "teléfono" o "tablet".
  - Apóyate en los *window size classes* de Material (compact < 600dp,
    medium 600-839dp, expanded ≥ 840dp) para decidir cuándo cambiar de
    layout.
  - No bloquees la orientación de la app: multiventana, plegables y
    accesibilidad pueden invalidar ese supuesto.
  - No estires formularios y campos a todo el ancho en pantallas grandes:
    limita con `ConstrainedBox(maxWidth: ...)` o usa `GridView`.
- Conserva la posición de scroll de listas con `PageStorageKey` y no pierdas
  el estado al rotar, cambiar el tamaño de ventana o plegar el dispositivo.
- Verifica que el contenido no se corte en pantallas pequeñas: prueba en
  anchos ~360px **y** con la fuente del sistema al máximo.

## Componentes de interacción

- **Formularios**: usa `Form` + `TextFormField` con `validator` explícito y
  mensajes de error claros en español, como en las pantallas existentes.
  Limpia el formulario tras un envío exitoso (`_formKey.currentState!.reset()`).
  Define `keyboardType`, `textInputAction` y `autofillHints` apropiados
  (teclado numérico para montos).
- **Botones**: un botón primario por pantalla/acción (`ElevatedButton` o
  `FilledButton`), acciones secundarias como `TextButton` u `OutlinedButton`.
  Evita mezclar más de dos jerarquías de botón en la misma vista.
- **Feedback de éxito/error**: usa `SnackBar` con color coherente al
  significado (éxito = color de acento o verde, error = `colorScheme.error`),
  no reutilices rojo para mensajes de éxito.
- **Navegación por pestañas**: sigue el patrón de `TabController` +
  `TabBar` con íconos y texto corto (una palabra) por pestaña, como en
  `lib/main.dart`.
- **Estados vacíos**: cuando una lista no tiene registros, muestra un mensaje
  o ilustración simple en vez de dejar la pantalla en blanco.
- **Estados de carga y error**: muestra indicador de carga (o *skeleton*) y un
  mensaje de error con opción de reintentar.
- **Estados interactivos**: para estilos por estado (presionado, deshabilitado,
  foco) usa `WidgetStateProperty` / `WidgetStatePropertyAll`.
  `MaterialStateProperty` está deprecado.
- **Teclado y mouse**: los widgets de Material ya soportan touch, mouse y
  teclado; en widgets personalizados agrega foco visible y atajos donde tenga
  sentido.
- **Botón atrás en Android**: respeta el gesto "atrás predictivo" (predictive
  back); no interceptes el retroceso salvo que haya cambios sin guardar.

## Accesibilidad

- **Tamaño de texto del sistema**: Flutter respeta la configuración del
  usuario. No fijes alturas rígidas en contenedores con texto; usa
  `ConstrainedBox(minHeight: ...)`, `Flexible`, `Wrap`. Prueba con la fuente
  al máximo en un teléfono pequeño y no desactives el escalado con
  `TextScaler.noScaling` sin una razón fuerte.
- **Contraste** (WCAG): mínimo 4.5:1 para texto pequeño (< 18pt normal o
  < 14pt negrita) y 3:1 para texto grande. Verifícalo en claro y en oscuro.
- **Áreas táctiles**: mínimo **48×48 dp** (Android/Material) y 44×44 pt (iOS).
  Como la app apunta a ambas plataformas, usa 48 como estándar. Para íconos
  pequeños usa `IconButton` (ya cumple) o amplía con `Padding`/`InkWell`.
- **Semántica**: agrega `tooltip` a `IconButton`, `semanticLabel` a íconos e
  imágenes significativas, y `Semantics`/`ExcludeSemantics` cuando el
  contenido sea decorativo o compuesto. No transmitas información solo con
  color (agrega ícono o texto).
- **Otras preferencias del sistema**: considera `MediaQuery.of(context)`
  (`disableAnimations`, `boldText`, `highContrast`) al animar o colorear.
- **Pruebas automáticas**: en `flutter test` usa el API de guías de
  accesibilidad:
  ```dart
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  ```

## Animaciones y micro-interacciones

- Usa animaciones cortas y con propósito (200-400ms) para transmitir cambios
  de valor (ver `AnimatedCounter`/`AnimatedTargetTotals` en `home_screen.dart`)
  o cambios de color al alternar tema.
- Evita animaciones decorativas sin relación con el estado de los datos.
- Prefiere `AnimatedContainer`, `AnimatedOpacity` o `TweenAnimationBuilder`
  (animaciones implícitas) sobre `AnimationController` manual cuando el
  efecto es simple.
- Respeta `MediaQuery.disableAnimationsOf(context)`: si está activo, reduce
  o elimina el movimiento.

## Formato de datos financieros

- Usa `intl` (`NumberFormat('#,##0.00', 'es_CO')`) para formatear montos;
  nunca concatenes números sin formato en la UI.
- Antepone la moneda de forma consistente (`COP $monto`) en todas las
  pantallas que muestren totales.
- Alinea los montos a la derecha en listas para facilitar la lectura
  vertical de cifras.
- Sugerencia (criterio propio, no viene de las guías oficiales): el peso
  colombiano se muestra normalmente sin decimales; si el proyecto no necesita
  centavos, considera `NumberFormat.currency(locale: 'es_CO', symbol: 'COP \$',
  decimalDigits: 0)`. Sea cual sea la elección, úsala igual en toda la app.

## Estilo de código Dart en UI

- Aprovecha las **dot shorthands** de Dart (`.center`, `.all(16)`) solo si el
  proyecto ya usa un SDK que las soporta y el equipo las adopta; no las
  mezcles a medias en un mismo archivo.
- Usa `const` siempre que se pueda y mantén `flutter analyze` sin avisos de
  deprecación. Aplica `dart fix --apply` para migraciones automáticas.

## Checklist antes de entregar una pantalla o widget

- [ ] Se ve correctamente en modo claro y en modo oscuro.
- [ ] Usa la tipografía Poppins y los tamaños de la jerarquía sugerida.
- [ ] Los colores provienen del tema/`ColorScheme` o de parámetros
      explícitos, no de valores hardcodeados sueltos.
- [ ] Sin APIs deprecadas (`withOpacity`, `MaterialStateProperty`).
- [ ] Imports coherentes con el resto del proyecto
      (`flutter/material.dart` **o** `material_ui`, no ambos).
- [ ] El espaciado es consistente (múltiplos de 4/8) y no hay overflow en
      ~360px ni con la fuente del sistema al máximo.
- [ ] El layout depende del tamaño de ventana (no de la orientación ni del
      tipo de dispositivo) y no se estira sin límite en pantallas grandes.
- [ ] Áreas táctiles ≥ 48×48 dp, contraste ≥ 4.5:1 (3:1 en texto grande) y
      etiquetas semánticas en íconos/botones sin texto.
- [ ] Toda acción del usuario tiene feedback visual (SnackBar, estado,
      validación de formulario), y hay estados vacío, de carga y de error.
- [ ] Los montos usan `NumberFormat` y siguen el formato `COP $monto`.
- [ ] `flutter analyze` y `flutter test` siguen pasando tras el cambio.

## Referencias en el código

- Tema y colores por modo: `lib/main.dart` (`temaClaro`, `temaOscuro`,
  `colorsLight`, `colorsDark`).
- Patrón de tarjeta con borde de acento y formulario: `lib/screen/incomes_screen.dart`.
- Patrón de resumen animado y totales: `lib/screen/home_screen.dart`.

## Referencias externas

- Migración a `material_ui`/`cupertino_ui`:
  https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui
- Accesibilidad (fuentes, contraste, áreas táctiles):
  https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
- Buenas prácticas de diseño adaptativo:
  https://docs.flutter.dev/ui/adaptive-responsive/best-practices