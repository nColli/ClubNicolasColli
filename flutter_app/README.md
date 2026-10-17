# ClubNicolasColli — App móvil (Flutter)

App para que los socios del club reserven espacios deportivos desde el celular. Usa **Firebase Auth** (registro, inicio de sesión y recuperación de contraseña), **Firebase Cloud Messaging** (recordatorios push de reservas) y la **API REST** del backend para todo lo demás.

**Requisitos previos:**

- Flutter (canal stable) con Dart 3.12.2 o superior, y `flutter doctor` sin errores para Android.
- Android Studio con un emulador cuya imagen de sistema incluya **Google Play** (sin Google Play Services no llegan los push).
- Node.js, para instalar el Firebase CLI.
- El backend funcionando, en local o en Render, y su proyecto de Firebase creado: ver [backend/README.md](../backend/README.md). La app tiene que usar **el mismo proyecto de Firebase** que el backend.

Todos los comandos se ejecutan desde la carpeta `flutter_app/`.

---

## 1. Instalar dependencias

```bash
cd flutter_app
flutter pub get
```

| Paquete | Para qué |
|---|---|
| `firebase_core` | Inicializar Firebase |
| `firebase_auth` | Registro, login y recuperación de contraseña |
| `firebase_messaging` | Notificaciones push |
| `http` | Llamadas a la API REST |

---

## 2. Configurar Firebase

El repositorio ya trae la configuración del proyecto de Firebase original (`clubnicolascolli`) en tres archivos generados:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

Si se usa un backend propio con otro proyecto de Firebase, hay que regenerarlos para ese proyecto: la API rechaza (401) los tokens emitidos por un proyecto distinto al de su cuenta de servicio.

### 2.1 Instalar el Firebase CLI y el FlutterFire CLI (una sola vez)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

`flutterfire` queda en `~/.pub-cache/bin` (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`). Si la terminal no lo encuentra, agregar esa carpeta al `PATH`.

### 2.2 Vincular la app con el proyecto

```bash
flutterfire configure --project=<id-del-proyecto> --platforms=android
```

`<id-del-proyecto>` es el *ID del proyecto* que figura en **Configuración del proyecto → General** de la consola de Firebase (el mismo valor que `FIREBASE_PROJECT_ID` del backend).

El comando registra la app Android (paquete `com.example.flutter_app`) en el proyecto y regenera los tres archivos de arriba. Si pregunta si sobrescribir archivos existentes, responder que sí.

Para iOS se puede agregar `ios` a `--platforms`, pero los push en iOS además requieren una cuenta de Apple Developer y una clave APNs cargada en Firebase, que este proyecto no tiene configuradas.

### 2.3 Qué más tiene que estar habilitado

- **Correo electrónico/contraseña** en **Authentication → Método de acceso** (paso 1.1 del backend). Si no está habilitado, el registro muestra "El registro con email no está habilitado."
- La recuperación de contraseña usa la plantilla de email de Firebase y no necesita configuración. El email puede llegar a la carpeta de spam.

---

## 3. Elegir la API

La URL de la API se define al compilar, con `--dart-define=API_URL=...` ([lib/src/config/api_config.dart](lib/src/config/api_config.dart)). Si no se indica, la app usa `http://10.0.2.2:8000`, que es el `localhost` de la PC visto desde el emulador de Android.

| Escenario | Comando |
|---|---|
| Emulador + API local | `flutter run` |
| Celular físico + API local | `flutter run --dart-define=API_URL=http://<IP-de-la-PC>:8000` (la API tiene que correr con `--host 0.0.0.0`) |
| API desplegada en Render | `flutter run --dart-define=API_URL=https://<nombre-del-servicio>.onrender.com` |

La URL va sin `/` al final. Las conexiones HTTP sin TLS solo están permitidas en compilaciones *debug*; un APK *release* tiene que apuntar a la URL `https://` de Render.

---

## 4. Ejecutar

1. Iniciar el emulador desde **Android Studio → Device Manager**, o desde la terminal:

   ```bash
   flutter emulators                 # lista los emuladores
   flutter emulators --launch <id>
   flutter devices                   # el emulador tiene que aparecer acá
   ```

2. Correr la app con el comando del paso 3 que corresponda, por ejemplo:

   ```bash
   flutter run --dart-define=API_URL=https://<nombre-del-servicio>.onrender.com
   ```

3. En Android 13 o superior, aceptar el permiso de notificaciones la primera vez que se entra al inicio.

Si la API está en el plan Free de Render y estuvo inactiva, abrir antes `https://<nombre-del-servicio>.onrender.com/health` en el navegador y esperar a que responda: la app corta los requests a los 20 segundos.

### Probar el flujo completo

1. **Registrarse** con nombre, apellido, DNI, fecha de nacimiento, email y contraseña (mínimo 8 caracteres).
2. **Sedes** → elegir una sede → filtrar por deporte → **VER HORARIOS / RESERVAR** en un espacio → elegir fecha, duración y horario → **CONTINUAR** → **CONFIRMAR RESERVA**.
3. **Notificación push:** reservar un turno que empiece en la próxima hora completa. En menos de 5 minutos llega el recordatorio "1 h antes" (la API revisa cada 5 minutos). Con la app abierta se muestra dentro de la app; en segundo plano o cerrada, en la barra de notificaciones de Android.
4. **Reservas** → ver las próximas y el historial → abrir una y **Cancelar reserva**.
5. **Perfil** → editar los datos (todos menos el email) → **Cerrar sesión**.
6. En el login, **¿Olvidaste tu contraseña?** → llega un email de Firebase para elegir una contraseña nueva.

---

## 5. Tests

```bash
flutter test
```

Cubren el parseo de los modelos, el armado de turnos, validadores, formateadores, el reloj de Argentina, las rutas y un widget ([test/](test/)).

---

## 6. Generar el APK

```bash
flutter build apk --release --dart-define=API_URL=https://<nombre-del-servicio>.onrender.com
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Se instala en el emulador o en un celular conectado con `flutter install` (o arrastrando el archivo a la ventana del emulador). Está firmado con la clave de debug: sirve para instalarlo y probarlo, no para publicarlo en Google Play.

---

## Problemas comunes

| Síntoma | Causa y solución |
|---|---|
| "No se pudo conectar con el servidor" con la API local | La API no está corriendo o no está en el puerto 8000. Comprobar <http://localhost:8000/health> en la PC. En un celular físico: usar la IP de la PC y `fastapi dev app/main.py --host 0.0.0.0`. |
| "El servidor no responde" contra Render | El servicio estaba suspendido (plan Free). Abrir `/health` en el navegador, esperar y reintentar. |
| "Tu sesión expiró. Volvé a iniciar sesión." apenas se inicia sesión | La app y la API usan proyectos de Firebase distintos. Repetir el paso 2.2 con el proyecto del backend. |
| "El registro con email no está habilitado." | Habilitar **Correo electrónico/contraseña** en Firebase Authentication. |
| No llegan los push | El emulador no tiene Google Play, se rechazó el permiso de notificaciones (habilitarlo en **Ajustes → Apps**), o la API de Render estaba suspendida en el momento del aviso. |
| `flutterfire: command not found` | Agregar `~/.pub-cache/bin` (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`) al `PATH`. |
| `File google-services.json is missing` al compilar | Ejecutar `flutterfire configure` (paso 2.2). |
| `flutter.sdk not set in local.properties` | Ese archivo lo genera Flutter: ejecutar `flutter pub get` dentro de `flutter_app/`. |
