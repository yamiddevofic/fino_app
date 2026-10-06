# FINO - Tu Asistente de Finanzas Personales

**FINO** es una aplicación multiplataforma desarrollada con Flutter para registrar tus ingresos, gastos, deudas y compras, y ver en todo momento cuánto dinero te queda. Funciona de forma local: los datos se guardan en el dispositivo con [Hive](https://pub.dev/packages/hive), sin cuenta ni servidor.

## Características Principales

- **Resumen**: Balance general (`ingresos − (gastos + deudas)`) con un anillo que indica qué parte de los ingresos ya está comprometida, desglose por sección, gráfica de ingresos y gastos de los últimos 6 meses y movimientos recientes.
- **Ingresos, gastos, deudas y compras**: Cada registro tiene monto, descripción, categoría, fecha y una nota opcional. Toca un registro para editarlo y deslízalo a la izquierda para borrarlo (con opción de deshacer).
- **Deudas canceladas**: Toca el icono de una deuda para marcarla como cancelada. Sigue contando en el balance (ese dinero ya salió) y el resumen muestra cuánto falta por pagar.
- **Lista de compras**: Marca las compras como hechas y registra las que aún no tienen precio para definirlo después.
- **Filtro por mes**: Cada sección muestra el total del mes elegido.
- **Montos en pesos colombianos**: Acepta `1.500.000`, `1500,50` o `$ 20.000`.
- **Modo claro y oscuro**: Sigue el tema del sistema hasta que eliges uno desde la barra superior; la elección se recuerda.
- **Diseño para móvil**: Navegación inferior, fondo animado sutil e ilustraciones SVG. Las animaciones se desactivan si el sistema pide reducir el movimiento.

## Hoja de Ruta

Ideas que aún **no** están implementadas:

- Registrar abonos parciales a una deuda.
- Exportar y respaldar los datos.

## Capturas de Pantalla

*Próximamente.*

## Instalación

Necesitas Flutter 3.35 o superior (el CI usa 3.47.6), Java 17 y un dispositivo, emulador o navegador. Comprueba el entorno con `flutter doctor`.

```bash
git clone https://github.com/yamiddevofic/fino_app.git
cd fino_app
flutter pub get
flutter run
```

Para elegir un dispositivo concreto usa `flutter devices` y `flutter run -d <device-id>`. Para generar la APK: `flutter build apk --release` (queda en `build/app/outputs/flutter-apk/`).

## Desarrollo

```bash
dart format lib test   # formato
flutter analyze        # análisis estático
flutter test           # pruebas
```

GitHub Actions ejecuta estos tres pasos en cada push, compila la versión web y genera una APK que se descarga desde la pestaña **Actions** (artefacto `fino-apk`).

Consulta `AGENTS.md` para conocer las convenciones de trabajo del repositorio.

### Estructura

```text
lib/
  main.dart            # Hive, providers, tema y navegación
  models/              # FinanceRecord y su adaptador, un modelo por sección,
                       # RecordKind (textos, colores, categorías) y ajustes
  provider/            # RecordProvider<T>, genérico sobre una caja de Hive
  screen/              # Inicio y la pantalla común de las cuatro secciones
  theme/, widgets/     # Sistema de diseño, gráficas y componentes animados
  utils/               # Formato y lectura de montos en COP
test/                  # Pruebas de providers, montos, datos antiguos e interfaz
assets/                # Ilustraciones SVG, tipografía Poppins e icono
```

### Persistencia

| Caja | Modelo | typeId |
| --- | --- | --- |
| `expensesBox` | `Expense` | 0 |
| `incomesBox` | `Income` | 1 |
| `buysBox` | `Buy` | 2 |
| `debtBox` | `Debt` | 3 |
| `settingsBox` | `Settings` | 5 |

Los adaptadores de los registros están escritos a mano en `lib/models/finance_record.dart`; la tabla de campos está documentada ahí. Al agregar un campo, usa un número nuevo y nunca reutilices uno existente: los datos guardados por versiones anteriores deben poder leerse (hay pruebas en `test/legacy_data_test.dart`).

## Limitaciones Conocidas

- La persistencia es exclusivamente local: no hay copias de seguridad, sincronización entre dispositivos ni autenticación.
- No hay notificaciones ni recordatorios.

## Contribuciones

1. Haz fork del repositorio.
2. Crea una rama con una descripción clara del cambio.
3. Implementa el cambio respetando la arquitectura existente.
4. Ejecuta `dart format`, `flutter analyze` y `flutter test`.
5. Abre un Pull Request con el contexto, las comprobaciones ejecutadas y las limitaciones relevantes.

## Licencia

La licencia del proyecto aún no está formalizada en un archivo del repositorio.

## Contacto

- Correo Electrónico: contacto@yamid.dev
- GitHub: https://github.com/yamiddevofic/fino_app
- LinkedIn: [Yamid Horacio Rodríguez](https://www.linkedin.com/in/yamid-rodriguez)
