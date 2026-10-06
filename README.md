# FINO

Aplicacion Flutter para registrar y consultar ingresos, gastos, deudas y
compras desde un unico lugar. FINO funciona de forma local: los datos se
persisten en el dispositivo mediante Hive y no requiere una cuenta ni un
backend.

## Funcionalidades

- Resumen de ingresos, gastos y deudas en la pantalla de inicio.
- Alta y eliminacion de ingresos.
- Alta y eliminacion de gastos.
- Alta y eliminacion de deudas.
- Alta y eliminacion de compras.
- Navegacion por pestañas entre las cinco secciones principales.
- Tema claro y tema oscuro.
- Persistencia local con cajas Hive tipadas.

## Requisitos

- Flutter instalado y configurado.
- Dart incluido en la version de Flutter instalada.
- Un dispositivo fisico, emulador o navegador compatible.

Comprueba el entorno con:

```bash
flutter doctor
flutter --version
```

## Instalacion

```bash
git clone https://github.com/yamiddevofic/fino_app.git
cd fino_app
flutter pub get
flutter run
```

Para elegir un dispositivo concreto:

```bash
flutter devices
flutter run -d <device-id>
```

## Estructura del proyecto

```text
lib/
  main.dart                 # Inicializacion de Hive, providers y aplicacion
  models/                   # Modelos persistidos y adaptadores Hive
  provider/                 # Estado y operaciones sobre las cajas Hive
  screen/                  # Pantallas de la aplicacion
test/                       # Pruebas automatizadas
assets/                     # Iconos, tipografias y otros recursos
```

La aplicacion se inicia desde `lib/main.dart`. Antes de montar la interfaz,
registra los adaptadores, abre las cajas Hive y configura los providers con
`MultiProvider`.

## Persistencia

FINO utiliza las siguientes cajas locales:

| Caja | Modelo |
| --- | --- |
| `incomesBox` | `Income` |
| `expensesBox` | `Expense` |
| `buysBox` | `Buy` |
| `debtBox` | `Debt` |

Los datos permanecen en el dispositivo donde se ejecuta la aplicacion. No hay
sincronizacion entre dispositivos, autenticacion ni almacenamiento remoto.

## Comprobaciones de desarrollo

Ejecuta estas comprobaciones antes de enviar cambios:

```bash
flutter analyze
flutter test
```

Para regenerar los adaptadores de Hive despues de modificar un modelo:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Limitaciones conocidas

- La persistencia es exclusivamente local y no incluye copias de seguridad en
  un servidor.
- No se incluyen autenticacion, sincronizacion remota, notificaciones ni
  historial independiente de compras.
- El repositorio no contiene actualmente un archivo `LICENSE`.

## Contribuciones

1. Crea un fork del repositorio.
2. Crea una rama descriptiva para tu cambio.
3. Implementa el cambio respetando la arquitectura existente.
4. Ejecuta `flutter analyze` y `flutter test`.
5. Abre un Pull Request con el contexto, las comprobaciones ejecutadas y las
   limitaciones relevantes.

Consulta `AGENTS.md` para conocer las convenciones de trabajo del repositorio.

## Licencia

La licencia del proyecto aun no esta formalizada en un archivo del repositorio.

## Contacto

- GitHub: https://github.com/yamiddevofic/fino_app
- LinkedIn: [Yamid Horacio Rodriguez](https://www.linkedin.com/in/yamid-rodriguez)
