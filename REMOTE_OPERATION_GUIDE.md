# UPTMDigital - Guia de Operacion Remota

Este documento deja una ruta minima para ejecutar UPTMDigital en infraestructura remota de forma estable.

## 1) Backend API (.NET) - Variables obligatorias

Define estas variables en tu hosting (Render, Azure, Railway, etc.):

- `ASPNETCORE_ENVIRONMENT=Production`
- `ConnectionStrings__DefaultConnection=<cadena_postgres_principal>`
- `ConnectionStrings__NominaConnection=<cadena_postgres_nomina_o_misma>`
- `NominaConfig__UseMirrorMode=true`
- `Jwt__Key=<clave_fuerte_minimo_32_caracteres>`
- `Jwt__Issuer=UPTMDigitalAPI`
- `Jwt__Audience=UPTMDigitalUsers`
- `DatabaseResilience__CommandTimeoutSeconds=30`
- `DatabaseResilience__MaxRetryCount=5`
- `DatabaseResilience__MaxRetryDelaySeconds=10`
- `DatabaseResilience__CommandTimeoutSeconds=45`
- `DatabaseResilience__MaxRetryCount=6`
- `DatabaseResilience__MaxRetryDelaySeconds=15`
- `DatabaseResilience__ConnectionTimeoutSeconds=15`
- `DatabaseResilience__KeepAliveSeconds=30`
- `DatabaseResilience__MinPoolSize=0`
- `DatabaseResilience__MaxPoolSize=30`

### Plantilla recomendada para Render + Supabase

- `ASPNETCORE_ENVIRONMENT=Production`
- `DOTNET_SYSTEM_NET_DISABLEIPV6=1`
- `NominaConfig__UseMirrorMode=true`
- `Jwt__Issuer=UPTMDigitalAPI`
- `Jwt__Audience=UPTMDigitalUsers`

Cadena recomendada (pooler, puerto 6543):

```text
Host=aws-0-us-west-2.pooler.supabase.com;Port=6543;Database=postgres;Username=postgres.gacjsnxmldpvweuwfopx;Password=<TU_PASSWORD>;SSL Mode=Require;Trust Server Certificate=true;
```

Usa esta cadena en ambas variables:

- `ConnectionStrings__DefaultConnection`
- `ConnectionStrings__NominaConnection`

## 2) CORS para frontends remotos

Configura origenes permitidos por variable o appsettings:

- `Cors__AllowedOrigins__0=https://tu-frontend-web.com`
- `Cors__AllowedOrigins__1=http://localhost:8080`

Agrega todos los dominios reales desde donde cargara el frontend.

## 3) Health check

La API expone un endpoint de salud:

- `GET /health`

Y para confirmar que el deploy activo es el mas reciente:

- `GET /api/version`

Debe responder `200 OK` con un JSON similar a:

```json
{"status":"ok","env":"Production"}
```

### Smoke test automatizado

Ejecuta:

```powershell
.\scripts\remote-smoke-test.ps1 -BaseUrl https://uptmdigital-api.onrender.com
```

Esto valida Swagger, Health y Login.

Para recuperar y validar autenticacion/perfil en una sola ejecucion:

```powershell
.\scripts\remote-recover-auth.ps1 -BaseUrl https://uptmdigital-api.onrender.com
```

Este script realiza:

- `POST /api/setup/seed-test-users`
- login de `tester_admin`, `tester_prof`, `tester_est`
- validacion de `GET /api/profesores/me` y `GET /api/estudiantes/me`

### Ajuste rapido para timeouts intermitentes en pooler

Si aparecen errores como `Timeout during reading attempt` en login o perfil, aumenta:

- `DatabaseResilience__CommandTimeoutSeconds=45`
- `DatabaseResilience__MaxRetryCount=6`
- `DatabaseResilience__MaxRetryDelaySeconds=15`

y reinicia el servicio para aplicar cambios.

Si aun ocurre timeout, la API ahora responde `503` controlado para errores transitorios de DB, en lugar de `500` con stack trace.

## 4) Flutter - URL de API en remoto

La app ahora prioriza `API_BASE_URL`. En cada build/deploy define:

- `--dart-define=API_BASE_URL=https://tu-api-remota.com`

Ejemplo para web:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://uptmdigital-api.onrender.com
```

Ejemplo para Android:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://uptmdigital-api.onrender.com
```

### Build automatizado de APK remota

```powershell
.\scripts\build-remote-apk.ps1 -ApiBaseUrl https://uptmdigital-api.onrender.com
```

## 5) Verificacion minima de punta a punta

1. Publica API y valida `GET /health`.
2. Valida login desde Swagger o Postman.
3. Publica app Flutter con `API_BASE_URL`.
4. Prueba login real desde app remota.
5. Revisa CORS si falla solo en web.

## 5.1) Crear usuarios de prueba por rol (incluye perfiles enlazados)

Para garantizar pruebas de login y perfil por rol, ejecuta:

```http
POST /api/setup/seed-test-users
```

Credenciales creadas/actualizadas:

- `tester_admin / 123456` (Administrador)
- `tester_seg / 123456` (Seguridad)
- `tester_prof / 123456` (Profesor, con perfil enlazado)
- `tester_est / 123456` (Estudiante, con perfil enlazado)

Con esto puedes validar directamente:

- `GET /api/profesores/me` con token de `tester_prof`
- `GET /api/estudiantes/me` con token de `tester_est`

## 6) Seguridad recomendada

- No subir secretos reales a `appsettings*.json`.
- Rotar claves previamente expuestas (DB y JWT).
- Mantener HTTPS habilitado en produccion.

## 7) Bloqueador frecuente en Render + PostgreSQL (IPv6)

Si el endpoint de login responde `500` y el stack trace indica:

- `Failed to connect to [IPv6]:5432`
- `SocketException (101): Network is unreachable`

entonces configura en el servicio de Render:

- `DOTNET_SYSTEM_NET_DISABLEIPV6=1`

Tambien valida que estas usando la conexion de `pooler` (6543) y no la conexion directa (5432) para cargas de app.

Despues reinicia el servicio y vuelve a correr:

```powershell
.\scripts\remote-smoke-test.ps1 -BaseUrl https://uptmdigital-api.onrender.com
```

Si el resultado esperado es correcto, debe verse:

- `[OK] Swagger -> HTTP 200`
- `[OK] Health -> HTTP 200 ...`
- `[OK] Login -> HTTP 200 ...` o `401/404` controlado (pero no `500` por BD)
