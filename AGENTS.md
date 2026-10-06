# Guia de trabajo para agentes

Este documento define las reglas practicas para agentes y colaboradores que
modifiquen FINO. El objetivo es mantener cambios pequenos, verificables y
coherentes con la arquitectura actual.

## Contexto del proyecto

FINO es una aplicacion Flutter de finanzas personales con persistencia local.
La aplicacion no tiene backend ni sincronizacion remota.

- Punto de entrada: `lib/main.dart`.
- UI: `lib/screen/`.
- Modelos Hive: `lib/models/`.
- Estado y acceso a datos: `lib/provider/`.
- Pruebas: `test/`.
- Recursos: `assets/`.

## Reglas de implementacion

- Inspecciona primero los archivos relacionados y conserva los patrones que ya
  usa el proyecto.
- Prefiere el cambio minimo que resuelva el problema; no hagas refactors
  generales sin necesidad concreta.
- Mantiene la separacion entre pantallas, providers y modelos.
- Usa los providers existentes para modificar datos y notificar cambios a la
  UI; evita acceder directamente a Hive desde una pantalla.
- Si cambias un modelo Hive, conserva los `typeId` y `field` existentes para no
  romper datos persistidos.
- Regenera los archivos `.g.dart` cuando cambien las anotaciones o campos de un
  modelo.
- Registra nuevas cajas y adaptadores en `lib/main.dart` cuando corresponda.
- Usa nombres descriptivos y comentarios solo cuando aclaren una decision o
  una parte no obvia del codigo.
- Evita agregar dependencias si la funcionalidad puede resolverse con las
  dependencias actuales.
- Mantiene los archivos en ASCII salvo que exista una razon clara para usar
  otros caracteres.

## Flujo de trabajo

1. Revisa `git status` y no sobrescribas cambios existentes de otros
   colaboradores.
2. Lee el codigo y las pruebas relacionadas antes de editar.
3. Implementa el cambio y actualiza las pruebas afectadas.
4. Ejecuta las comprobaciones requeridas.
5. Revisa `git diff` y confirma que solo se modificaron archivos necesarios.

## Comandos de verificacion

Desde la raiz del repositorio:

```bash
flutter pub get
flutter analyze
flutter test
```

Si se modifican modelos Hive:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Para ejecutar la aplicacion:

```bash
flutter devices
flutter run -d <device-id>
```

No marques un cambio como terminado si `flutter analyze` o `flutter test`
fallan. Si una comprobacion no puede ejecutarse por una limitacion del entorno,
documenta el motivo y el comando exacto en el resumen del trabajo.

## Pruebas

- Reemplaza pruebas heredadas que ya no representen la UI actual.
- Las pruebas widget deben montar las dependencias que necesita la pantalla,
  incluidos providers y cajas Hive cuando sean necesarios.
- Usa un directorio temporal o una configuracion aislada para persistencia en
  pruebas; no dependas de datos reales del usuario.
- Verifica comportamiento observable, no detalles internos innecesarios.
- Agrega una prueba de regresion cuando corrijas un bug reproducible.

## Git y cambios

- No reviertas ni reformatees cambios ajenos.
- No incluyas secretos, archivos generados de compilacion, `.dart_tool/` ni
  `build/` en los cambios.
- Mantiene los commits, si se solicitan, enfocados en una sola responsabilidad.
- Usa mensajes de commit breves y descriptivos.
- No hagas `git reset --hard`, `git checkout --` ni operaciones destructivas.
- No cierres issues sin validar primero el criterio de aceptacion y dejar un
  comentario con la comprobacion realizada.

## Criterio de finalizacion

Antes de entregar un cambio, confirma lo siguiente:

- El comportamiento solicitado esta implementado.
- Las pruebas relevantes fueron actualizadas o se justifico por que no aplica.
- `flutter analyze` no reporta problemas.
- `flutter test` finaliza correctamente.
- El diff no contiene cambios accidentales.
- La documentacion refleja cualquier cambio de uso, limitacion o comando.
