# FINO - Tu Asistente de Finanzas Personales

**FINO** es una aplicación multiplataforma desarrollada con Flutter para registrar tus ingresos, gastos, deudas y compras, y ver en todo momento cuánto dinero te queda. Todos los datos se guardan localmente en el dispositivo con [Hive](https://pub.dev/packages/hive).

## Características Principales

- **Resumen general (Home)**: Totales de ingresos, gastos y deudas, y un total general calculado como `ingresos - (gastos + deudas)`, expresado en pesos colombianos (COP).
- **Ingresos**: Registra, edita y elimina tus fuentes de ingreso.
- **Gastos**: Lleva el control de tus gastos con nombre y monto.
- **Deudas**: Registra lo que debes para tenerlo en cuenta en tu balance.
- **Compras**: Anota las compras que tienes pendientes o planeadas.
- **Modo claro y oscuro**: Cambia el tema desde el interruptor en la barra superior.
- **Almacenamiento local**: Sin cuentas ni conexión a internet; tus datos no salen del dispositivo.

## Hoja de Ruta

Ideas que aún **no** están implementadas:

- Fechas y categorías en cada registro, con filtros por mes.
- Gráficas de ingresos y gastos.
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

**Nota**: Asegúrate de tener Flutter instalado en tu sistema y un dispositivo o emulador configurado para ejecutar la aplicación.

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
