# 📱 Guía de Instalación y Pruebas en Celular Android - PrestaControl

Esta guía detalla paso a paso cómo compilar, instalar y probar la aplicación móvil **PrestaControl** directamente en un dispositivo Android físico, apuntando al backend en producción:
- **URL Backend de Producción:** `https://prestamoservice-cohc.onrender.com`

---

## 📋 Requisitos Previos

1. **Celular Android** con Android 8.0 (Oreo) o superior.
2. **Cable USB** de buena calidad para conectar el teléfono a la PC.
3. **Flutter SDK** instalado y configurado en las variables de entorno de la computadora.
4. **Conexión a Internet** en el celular (Wi-Fi o datos móviles) para comunicarse con la API en Render.

---

## ⚡ Método 1: Instalación Directa por Cable USB (Recomendado para Desarrollo/Sustentación)

Este método instala y ejecuta la aplicación directamente desde la terminal de tu computadora en el celular conectado.

### Paso 1: Activar Opciones de Desarrollador y Depuración USB en el Celular
1. En tu celular Android, ve a **Ajustes** / **Configuración**.
2. Entra en **Acerca del teléfono** (o *Información del software*).
3. Busca la opción **Número de compilación** (o *Versión de software / Versión MIUI*) y tócala **7 veces seguidas** hasta que aparezca el mensaje: *"¡Ya eres desarrollador!"*.
4. Regresa al menú principal de Ajustes, entra en **Sistema** (o *Ajustes adicionales*) > **Opciones de desarrollador**.
5. Activa el interruptor **Depuración por USB**.
6. *(Solo Xiaomi / Redmi / POCO)*: Activa también **Instalar vía USB** y **Depuración USB (Ajustes de seguridad)**.

### Paso 2: Conectar el Celular a la Computadora
1. Conecta el celular a un puerto USB de tu computadora.
2. En la pantalla del celular aparecerá una ventana emergente:  
   *¿Permitir depuración por USB?*  
   Marca la casilla **"Permitir siempre desde esta computadora"** y pulsa **Permitir / Aceptar**.

### Paso 3: Verificar Reconocimiento del Dispositivo
Abre una terminal (PowerShell o CMD) en la carpeta del proyecto `prestacontrol_app` y ejecuta:

```bash
flutter devices
```

Deberás ver tu teléfono en la lista de dispositivos conectados, por ejemplo:
```text
1 connected device:
Xiaomi 2201117PG (mobile) • e4f9d2a1 • android-arm64 • Android 13 (API 33)
```

### Paso 4: Ejecutar en Modo Release
Ejecuta el siguiente comando para compilar e instalar la app optimizada para producción:

```bash
flutter run --release
```

Si tienes más de un dispositivo disponible (ej. emulador abierto a la vez), especifica el ID del celular con el parámetro `-d`:
```bash
flutter run -d <DEVICE_ID> --release
```

La app se compilará, se transferirá y se abrirá automáticamente en tu celular.

---

## 📦 Método 2: Generar e Instalar el Archivo APK Independiente

Este método genera un instalador `.apk` listo para compartir (por WhatsApp, Drive o Telegram) e instalar en cualquier celular sin depender de la computadora.

### Paso 1: Compilar el APK de Release
Abre la terminal en la raíz de `prestacontrol_app` y ejecuta:

```bash
flutter build apk --release
```

*Nota: La primera compilación puede demorar de 2 a 4 minutos mientras descarga dependencias de Gradle y compila el código nativo AOT.*

### Paso 2: Ubicación del Archivo Generado
Al terminar el comando, Flutter te confirmará la ruta del archivo generado:

```text
build\app\outputs\flutter-apk\app-release.apk
```

La ruta absoluta exacta en tu computadora es:
```text
c:\Users\megac\Desktop\prestacontrol_app\build\app\outputs\flutter-apk\app-release.apk
```

### Paso 3: Transferir el APK al Celular
Elige la opción que prefieras:

- **Opción A (Cable USB):** Conecta el celular en modo "Transferencia de archivos (MTP)" y copia `app-release.apk` a la carpeta `Download` del celular.
- **Opción B (WhatsApp Web / Telegram):** Envíate el archivo `app-release.apk` a ti mismo o a tu grupo de chat y descárgalo en el celular.
- **Opción C (Comando ADB directo por cable):**
  ```bash
  adb install -r build/app/outputs/flutter-apk/app-release.apk
  ```

### Paso 4: Instalar en el Dispositivo
1. Abre el explorador de archivos en tu celular o el mensaje donde recibiste el archivo.
2. Toca sobre `app-release.apk` para instalarlo.
3. Si Android muestra la advertencia *"Por motivos de seguridad, tu teléfono no tiene permiso para instalar aplicaciones desconocidas de esta fuente"*, pulsa **Ajustes** y activa **Confiar en esta fuente / Permitir desde este origen**.
4. Pulsa **Instalar**. ¡Listo! Abre **PrestaControl** desde tu lista de aplicaciones.

---

## 🧪 Plan de Pruebas para la Sustentación: Aislamiento Multitenant (2 Prestamistas)

Para demostrar en la evaluación que la arquitectura es segura, multitenant y basada en tokens JWT con aislamiento estricto por usuario:

### 👤 Prestamista 1: Carlos Mendoza
1. **Registro / Inicio de Sesión:**
   - Abre la aplicación en el celular.
   - Pestaña **Registrarse**:
     - **Nombre:** `Carlos Mendoza`
     - **Correo:** `carlos@prestacontrol.com`
     - **Contraseña:** `123456`
   - Pulsa **Crear Cuenta**. Ingresarás a la pantalla principal.
2. **Crear Préstamos:**
   - Pulsa el botón **+ Nuevo Préstamo**.
   - Préstamo 1 (Pendiente):
     - **Cliente:** `Roberto Gómez`
     - **DNI:** `45892134`
     - **Monto:** `1000`
     - **Interés (%):** `10`  *(Total a cobrar: S/ 1,100.00)*
     - **Fecha de Vencimiento:** Seleccionar 15 días a futuro.
     - Pulsa **Registrar Préstamo**.
   - Préstamo 2 (Prueba de Moroso / Vencido):
     - **Cliente:** `Marcos Vílchez`
     - **DNI:** `10928374`
     - **Monto:** `500`
     - **Interés (%):** `20`  *(Total a cobrar: S/ 600.00)*
     - **Fecha de Vencimiento:** Seleccionar una fecha en el pasado (ej. ayer o el mes pasado).
     - Pulsa **Registrar Préstamo**.
3. **Verificaciones visuales de la Rúbrica para Prestamista 1:**
   - Observa que el préstamo de *Marcos Vílchez* aparece destacado con **borde y fondo rojo, y la etiqueta roja "VENCIDO"** (Reto de Morosos cumplido).
   - Observa la tarjeta superior de **Resumen de Cartera**: Capital S/ 1,500.00, Total por Cobrar S/ 1,700.00, Ganancia S/ 200.00.
   - Pulsa el icono de check verde en *Roberto Gómez* para marcarlo como **Cobrado**. Pasa a la pestaña "Cobrados" y el resumen se actualiza en tiempo real.
4. **Cerrar Sesión:**
   - Pulsa el icono de salida en la esquina superior derecha y confirma **Salir**. El token se destruye del almacenamiento seguro (`flutter_secure_storage`).

---

### 👤 Prestamista 2: Ana Lucía Torres
1. **Registro / Inicio de Sesión:**
   - En la pantalla de bienvenida, pestaña **Registrarse**:
     - **Nombre:** `Ana Torres`
     - **Correo:** `ana@prestacontrol.com`
     - **Contraseña:** `123456`
   - Pulsa **Crear Cuenta**.
2. **Validación Crucial de Aislamiento de Cartera:**
   - **¡La lista de préstamos de Ana está completamente vacía!**
   - El Resumen de Cartera muestra S/ 0.00.
   - Los préstamos de *Roberto Gómez* y *Marcos Vílchez* de Carlos **NO** son visibles para Ana. El backend en Spring Boot filtra estrictamente por el `userId` extraído del token JWT.
3. **Crear Préstamo Propio de Ana:**
   - Pulsa **+ Nuevo Préstamo**.
   - **Cliente:** `Farmacia San Pedro`
   - **DNI:** `78234190`
   - **Monto:** `2500`
   - **Interés (%):** `15`
   - Pulsa **Registrar Préstamo**.
   - Ana ahora ve únicamente su préstamo registrado.
4. **Prueba de Persistencia al Cerrar la App:**
   - Cierra completamente la app (remuévela de la lista de apps recientes de Android).
   - Vuelve a abrir **PrestaControl**.
   - La sesión de Ana **persiste automáticamente** sin pedir contraseña, gracias a la lectura del token JWT en `FlutterSecureStorage`.
5. **Cerrar Sesión:**
   - Cierra sesión con Ana. Inicia sesión con Carlos (`carlos@prestacontrol.com` / `123456`) y confirma que sus 2 préstamos siguen intactos en su cuenta.

---

## 💡 Notas Técnicas Importantes sobre el Servidor de Producción (Render)

- **Despertar del Servidor (Cold Start):**  
  El backend está alojado en el plan gratuito de Render. Si no ha recibido peticiones en los últimos 15 minutos, la instancia entra en modo reposo (*spin down*). Al hacer la primera petición (login o registro), tardará entre **30 y 50 segundos** en responder mientras levanta el contenedor.
- **Manejo en la App:**  
  La app cuenta con un timeout de **60 segundos** y muestra un mensaje amigable:  
  *"Conectando con el servidor, puede tardar unos segundos..."*. Si demora la primera vez, no te preocupes: una vez despierte, todas las demás operaciones serán instantáneas.
