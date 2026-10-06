# FINO - Tu Asistente de Finanzas Personales

**FINO** es una aplicación multiplataforma desarrollada con Flutter para registrar tus ingresos, gastos, deudas y compras, y ver en todo momento cuánto dinero te queda. Todos los datos se guardan localmente en el dispositivo con [Hive](https://pub.dev/packages/hive).

## Características Principales

- **Resumen**: Balance general (`ingresos − (gastos + deudas)`) con un anillo que indica qué parte de los ingresos ya está comprometida, desglose por sección, gráfica de ingresos y gastos de los últimos 6 meses y movimientos recientes.
- **Ingresos, gastos, deudas y compras**: Cada registro tiene monto, descripción, categoría, fecha y una nota opcional. Toca un registro para editarlo y deslízalo a la izquierda para borrarlo (con opción de deshacer).
- **Filtro por mes**: Cada sección muestra el total del mes elegido.
- **Montos en pesos colombianos**: Acepta `1.500.000`, `1500,50` o `$ 20.000`.
- **Modo claro y oscuro**: Sigue el tema del sistema; se puede cambiar desde la barra superior.
- **Diseño para móvil**: Navegación inferior, fondo animado sutil e ilustraciones SVG. Las animaciones se desactivan si el sistema pide reducir el movimiento.
- **Almacenamiento local**: Sin cuentas ni conexión a internet; tus datos no salen del dispositivo.

## Hoja de Ruta

Ideas que aún **no** están implementadas:

- Marcar deudas como pagadas o registrar abonos parciales.
- Recordar el tema elegido entre sesiones.
- Exportar y respaldar los datos.

## Capturas de Pantalla

*Próximamente.*

## Instalación

Para probar **FINO** en tu dispositivo localmente, sigue estos pasos:

1. **Clonar el repositorio**:

   ```bash
   git clone https://github.com/yamiddevofic/fino_app.git
   ```

2. **Navegar al directorio del proyecto**:

   ```bash
   cd fino_app
   ```

3. **Instalar las dependencias**:

   ```bash
   flutter pub get
   ```

4. **Ejecutar la aplicación**:

   ```bash
   flutter run
   ```

**Nota**: Necesitas Flutter 3.35 o superior (el CI usa 3.47.6), Java 17 y un dispositivo o emulador configurado.

## Desarrollo

```bash
dart format lib test   # formato
flutter analyze        # análisis estático
flutter test           # pruebas
```

GitHub Actions ejecuta estos tres pasos en cada push, compila la versión web y genera una APK que se descarga desde la pestaña **Actions** (artefacto `fino-apk`).

### Estructura

- `lib/models/`: `FinanceRecord` (base común y adaptador de Hive), un modelo por sección y `RecordKind` con los textos, colores y categorías de cada sección.
- `lib/provider/record_provider.dart`: provider genérico sobre una caja de Hive.
- `lib/screen/records_screen.dart`: pantalla común de las cuatro secciones.
- `lib/theme/`, `lib/widgets/`: sistema de diseño, gráficas y componentes animados.

## Contribuciones

¡Las contribuciones son bienvenidas! Si deseas colaborar en el desarrollo de FINO, por favor sigue estos pasos:

1. Haz fork del repositorio.
2. Crea una nueva rama con una descripción clara de la funcionalidad o corrección que implementarás.
3. Realiza tus cambios y asegúrate de que las pruebas existentes pasen correctamente.
4. Envía un Pull Request detallando los cambios realizados.

## Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.

## Contacto

Para más información o consultas, puedes contactarme a través de:

- Correo Electrónico: contacto@yamid.dev
- LinkedIn: [Yamid Horacio Rodríguez](https://www.linkedin.com/in/yamid-rodriguez)
