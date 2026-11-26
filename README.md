# FINO - Tu Asistente de Finanzas Personales

**FINO** es una aplicación multiplataforma desarrollada con Flutter para registrar tus ingresos, gastos, deudas y compras, y ver en todo momento cuánto dinero te queda. Guarda primero en el dispositivo con [Hive](https://pub.dev/packages/hive), así que funciona sin internet, y sincroniza con [Supabase](https://supabase.com) para tener los mismos datos en el celular y en el navegador.

## Características Principales

- **Resumen**: Balance general (`ingresos − gastos`) con un anillo que indica qué parte de los ingresos ya se gastó, balance proyectado tras pagar lo pendiente, desglose por sección, gráfica de los últimos 6 meses y movimientos recientes.
- **Ingresos, gastos, deudas y compras**: Cada registro tiene monto, descripción, categoría, fecha y una nota opcional. Toca un registro para editarlo y deslízalo a la izquierda para borrarlo (con opción de deshacer).
- **Deudas y compras pendientes**: No afectan el balance mientras estén pendientes. Al tocar su icono para marcarlas como pagadas o compradas se registra el gasto automáticamente (categoría «Deudas» o «Compras»); si se desmarcan, ese gasto se elimina. Es la misma lógica de apps como Money Lover o Wallet.
- **Compras sin precio**: Se pueden registrar con «precio por definir»; al marcarlas como compradas la app pide el precio.
- **Categorías propias**: Crea categorías desde el formulario con «+ Nueva»; mantén presionada una categoría propia para eliminarla.
- **Cuenta y sincronización**: Inicia sesión una vez por dispositivo con correo y contraseña; la app sube tus cambios a Supabase y baja los de tus otros dispositivos. Sin conexión sigue funcionando y sincroniza al volver la red. El icono de nube de la barra superior muestra el estado y permite sincronizar o cerrar sesión. También se puede usar sin cuenta.
- **PIN**: Tras iniciar sesión la app pide un PIN de 4 dígitos para abrirse, también al volver después de más de un minuto en segundo plano. Si lo olvidas, «¿Olvidaste tu PIN?» pide la contraseña de la cuenta para crear uno nuevo.
- **Exportar e importar datos**: Desde el menú de la barra superior (⋮) guarda un respaldo en un archivo JSON con todos los registros (ingresos, gastos, deudas y compras) y tus categorías propias. Al importar se muestra el contenido del respaldo y se elige entre **Combinar** (agrega lo que falta y omite los registros y categorías que ya existen, así que importar dos veces el mismo archivo no duplica nada) o **Reemplazar** (borra los datos actuales). En ambos casos las deudas y compras pagadas siguen enlazadas con su gasto.
- **Filtro por mes**: Cada sección muestra el total del mes elegido.
- **Montos en pesos colombianos**: Acepta `1.500.000`, `1500,50` o `$ 20.000`.
- **Modo oscuro por defecto**: La app empieza en modo oscuro; puedes cambiar a claro desde la barra superior y la elección se recuerda.
- **Diseño para móvil**: Navegación inferior, fondo animado sutil e ilustraciones SVG. Las animaciones se desactivan si el sistema pide reducir el movimiento.

## Hoja de Ruta

Ideas que aún **no** están implementadas:

- Registrar abonos parciales a una deuda.
- Elegir un icono para las categorías propias.
- Exportar a CSV para abrir los datos en una hoja de cálculo.

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

El icono (una F con los colores de ingresos, deudas y compras y una alcancía) se genera desde `assets/branding/` con `dart run flutter_launcher_icons`; el logo de la barra superior es la misma marca en `assets/svg/logo.svg`.

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
assets/                # Ilustraciones SVG, tipografía Poppins y fuente
                       # del icono (assets/branding, no se empaqueta)
```

### Persistencia

| Caja | Modelo | typeId |
| --- | --- | --- |
| `expensesBox` | `Expense` | 0 |
| `incomesBox` | `Income` | 1 |
| `buysBox` | `Buy` | 2 |
| `debtBox` | `Debt` | 3 |
| `settingsBox` | `Settings` | 5 |
| `categoriesBox` | Lista de textos por sección | — |
| `syncOutbox` | Cambios pendientes de subir | — |
| `syncState` | Cuenta y cursores de la sincronización | — |
| `securityBox` | Hash del PIN | — |

### Supabase

El proyecto y la clave publicable están en `lib/config.dart`; la clave puede ir en la app porque las políticas de seguridad por filas (RLS) limitan cada cuenta a sus datos. El esquema está en `supabase/migrations/`: tablas `records` y `categories`, con `updated_at` fijado por el servidor como cursor de sincronización y `deleted_at` para propagar los borrados. La lógica está en `lib/provider/sync_service.dart` y `lib/provider/sync_outbox.dart`.

Los adaptadores de los registros están escritos a mano en `lib/models/finance_record.dart`; la tabla de campos está documentada ahí. Al agregar un campo, usa un número nuevo y nunca reutilices uno existente: los datos guardados por versiones anteriores deben poder leerse (hay pruebas en `test/legacy_data_test.dart`).

## Limitaciones Conocidas

- Si el mismo registro se edita en dos dispositivos sin conexión, al sincronizar gana el último que se sube.
- Importar el mismo respaldo en dos dispositivos distintos duplica los registros en la cuenta: impórtalo solo en uno y deja que se sincronice.
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
