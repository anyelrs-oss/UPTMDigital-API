import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uptmdigital_app/models/anuncio.dart';
import 'package:uptmdigital_app/models/mensaje.dart';
import 'dart:convert';

class ApiService {
  static final ApiService instance = ApiService._();
  factory ApiService() => instance;
  ApiService._();

  final Dio _dio = Dio();
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // In-memory cache with TTL (Time To Live)
  final Map<String, _CacheEntry> _memoryCache = {};
  static const Duration _defaultCacheTTL = Duration(minutes: 10);
  static const Duration _listCacheTTL = Duration(minutes: 5);

  // Prioridad 1: URL explícita en build/deploy (recomendado para operación remota).
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  // Prioridad 2: selector simple de entorno.
  static const String _envMode = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'render',
  );

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl;
    }

    switch (_envMode) {
      case 'render':
        return "https://uptmdigital-api.onrender.com";
      case 'somee':
        return "http://uptmdigitalapi.somee.com";
      case 'local':
      default:
        if (kIsWeb) return "http://localhost:8080";
        // 10.0.2.2 apunta al host local desde el emulador Android.
        return "http://10.0.2.2:5286";
    }
  }

  Future<void> init() async {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Adjuntar motivo de borrado si existe en el almacenamiento temporal
          String? reason = await storage.read(key: 'pending_delete_reason');
          if (reason != null) {
            options.headers['X-Reason'] = reason;
            await storage.delete(key: 'pending_delete_reason'); // Limpiar después de usar
          }

          handler.next(options);
        },
      ),
    );

    // Wake up server in background
    getHealth();
  }

  Future<bool> getHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'nombreUsuario': username, 'contrasena': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final role = response.data['rol'];
        final userId = response.data['idUsuario'];

        await storage.write(key: 'jwt_token', value: token);
        await storage.write(key: 'user_role', value: role);
        await storage.write(key: 'user_id', value: userId?.toString() ?? '');
        await storage.write(key: 'username', value: username);

        return {'success': true, 'role': role, 'token': token};
      }
      return {'success': false, 'message': 'Credenciales inválidas'};
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final msg =
            e.response!.data['Message'] ??
            e.response!.data['message'] ??
            'Error de autenticación';
        return {'success': false, 'message': msg};
      }
      return {'success': false, 'message': 'Falla de conexión con el servidor'};
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Error inesperado'};
    }
  }

  Future<Map<String, dynamic>> register(
    String cedula,
    String username,
    String password,
  ) async {
    try {
      // Aumentamos el timeout específicamente para el registro debido a la vinculación de perfiles
      final response = await _dio.post(
        '/api/auth/register',
        data: {'cedula': cedula, 'username': username, 'contrasena': password},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Registro exitoso: ${response.data}');
        return {'success': true, ...response.data};
      }
      return {'success': false, 'message': 'Error desconocido'};
    } on DioException catch (e) {
      debugPrint('Error en registro (Dio): ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return {
          'success': false, 
          'message': 'El servidor está tardando mucho en vincular su perfil. Por favor, intente iniciar sesión en unos momentos.',
          'isTimeout': true
        };
      }
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Error en el registro',
        };
      }
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  /// Pre-validación de cédula contra la Base Maestro
  Future<Map<String, dynamic>> checkCedula(String cedula) async {
    try {
      final response = await _dio.get('/api/auth/check-cedula/$cedula');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'nombres': response.data['nombres'],
          'apellidos': response.data['apellidos'],
          'rol': response.data['rol'],
          'carrera': response.data['carrera'],
          'yaTieneCuenta': response.data['yaTieneCuenta'],
        };
      }
      return {'success': false, 'message': 'No encontrada'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': false,
          'message': 'Cédula no encontrada en el registro institucional.',
        };
      }
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Error de conexión',
      };
    }
  }

  Future<List<dynamic>> getEstudiantes({String? search, String? carrera, int page = 1, int limit = 20}) async {
    // Don't cache filtered/search results, only page 1
    final cacheKey = 'cache_estudiantes_p${page}';
    
    if (page == 1 && search == null && carrera == null) {
      final cached = await _getCached<List>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final params = {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (carrera != null) 'carrera': carrera,
      };
      final response = await _dio.get('/api/estudiantes', queryParameters: params);

      if (response.statusCode == 200) {
        if (page == 1 && search == null && carrera == null) {
          await _setCached(cacheKey, response.data, ttl: _listCacheTTL);
        }
        return response.data;
      }
    } catch (e) {
      if (page == 1 && search == null && carrera == null) {
        final cached = await _getCached<List>(cacheKey);
        if (cached != null) return cached;
      }
    }
    return [];
  }

  Future<bool> createStudent(Map<String, dynamic> studentData) async {
    try {
      await _dio.post('/api/estudiantes', data: studentData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStudent(int id, Map<String, dynamic> studentData) async {
    try {
      await _dio.put('/api/estudiantes/$id', data: studentData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStudent(int id) async {
    try {
      await _dio.delete('/api/estudiantes/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- PROFESORES ---

  Future<List<dynamic>> getProfesores({String? search, String? departamento, int page = 1, int limit = 20}) async {
    final cacheKey = 'cache_profesores_p${page}';
    
    if (page == 1 && search == null && departamento == null) {
      final cached = await _getCached<List>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final params = {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (departamento != null) 'departamento': departamento,
      };
      final response = await _dio.get('/api/profesores', queryParameters: params);
      if (response.statusCode == 200) {
        if (page == 1 && search == null && departamento == null) {
          await _setCached(cacheKey, response.data, ttl: _listCacheTTL);
        }
        return response.data;
      }
    } catch (e) {
      if (page == 1 && search == null && departamento == null) {
        final cached = await _getCached<List>(cacheKey);
        if (cached != null) return cached;
      }
    }
    return [];
  }

  Future<bool> createProfesor(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/profesores', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfesor(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/profesores/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProfesor(int id) async {
    try {
      await _dio.delete('/api/profesores/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- ASIGNATURAS ---

  Future<List<dynamic>> getAsignaturas() async {
    const cacheKey = 'cache_asignaturas';
    
    final cached = await _getCached<List>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.get('/api/asignaturas');
      if (response.statusCode == 200) {
        await _setCached(cacheKey, response.data, ttl: _defaultCacheTTL);
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching asignaturas: $e');
      // Try to return cached data even if expired
      final fallback = await _getCached<List>(cacheKey);
      if (fallback != null) return fallback;
    }
    return [];
  }

  Future<bool> createAsignatura(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/asignaturas', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAsignatura(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/asignaturas/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAsignatura(int id) async {
    try {
      await _dio.delete('/api/asignaturas/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- INSCRIPCIONES ---

  Future<List<dynamic>> getInscripciones() async {
    try {
      final response = await _dio.get('/api/inscripciones');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<bool> createInscripcion(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/inscripciones', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateInscripcion(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/inscripciones/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteInscripcion(int id) async {
    try {
      await _dio.delete('/api/inscripciones/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- NOTAS ---

  Future<List<dynamic>> getNotas({String? search, int? asignaturaId}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null) params['search'] = search;
      if (asignaturaId != null) params['asignaturaId'] = asignaturaId.toString();

      final response = await _dio.get('/api/notas', queryParameters: params);
      return response.data as List;
    } catch (e) {
      return [];
    }
  }

  Future<bool> createNota(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/notas', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createNotasMasivo(int asignaturaId, int evaluacionId, Map<int, double> notas) async {
    try {
      final notasList = notas.entries.map((e) => {
        "estudianteId": e.key,
        "calificacion": e.value
      }).toList();

      await _dio.post('/api/notas/masivo', data: {
        "asignaturaId": asignaturaId,
        "evaluacionId": evaluacionId,
        "notas": notasList
      });
      return true;
    } catch (e) {
      debugPrint("Error al subir notas masivas: $e");
      return false;
    }
  }

  Future<bool> updateNota(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/notas/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNota(int id) async {
    try {
      await _dio.delete('/api/notas/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- ASISTENCIAS ---

  Future<List<dynamic>> getAsistencias() async {
    try {
      final response = await _dio.get('/api/asistencias');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAsistencia(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/asistencias', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAsistencia(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/asistencias/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAsistencia(int id) async {
    try {
      await _dio.delete('/api/asistencias/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- CONSTANCIAS ---

  Future<List<dynamic>> getConstancias() async {
    try {
      final response = await _dio.get('/api/constancias');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<bool> createConstancia(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/constancias', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateConstancia(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/constancias/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteConstancia(int id) async {
    try {
      await _dio.delete('/api/constancias/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Borra toda la información de sesión del dispositivo.
  /// Llamar siempre cuando el usuario hace logout explícito.
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'username');
  }

  /// Retorna true si hay un token guardado en el dispositivo.
  /// No valida el token contra el servidor (basta para auto-login).
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  /// Retorna el rol guardado localmente ('Estudiante', 'Profesor', etc.).
  /// Útil para saber a qué dashboard redirigir sin llamar al servidor.
  Future<String?> getSavedRole() async {
    return await storage.read(key: 'user_role');
  }

  /// Retorna el username guardado localmente.
  Future<String?> getSavedUsername() async {
    return await storage.read(key: 'username');
  }

  // --- DASHBOARD HELPERS ---

  Future<Map<String, dynamic>?> getUserMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        // Normalizar los datos para el CarnetScreen
        Map<String, dynamic> userData = {
          'idUsuario': data['idUsuario'],
          'nombreUsuario': data['nombreUsuario'],
          'cedula': data['cedula'],
          'rol': data['rol'],
        };

        if (data['perfil'] != null) {
          userData.addAll(Map<String, dynamic>.from(data['perfil']));
          
          // Guardar IDs específicos para facilitar el acceso en otras pantallas
          if (userData.containsKey('idEstudiante')) {
            await storage.write(key: 'estudiante_id', value: userData['idEstudiante'].toString());
          }
          if (userData.containsKey('idProfesor')) {
            await storage.write(key: 'profesor_id', value: userData['idProfesor'].toString());
          }
        }

        await storage.write(key: 'cached_user_me', value: jsonEncode(userData));
        return userData;
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_user_me');
      if (cached != null) return jsonDecode(cached);
    }
    return null;
  }

  Future<List<dynamic>> getStudentGradesMe() async {
    try {
      final response = await _dio.get('/api/estudiantes/me/notas');
      if (response.statusCode == 200) {
        await storage.write(key: 'cached_my_grades', value: jsonEncode(response.data));
        return response.data;
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_my_grades');
      if (cached != null) return jsonDecode(cached);
    }
    return [];
  }

  Future<List<dynamic>> getStudentInscripcionesMe() async {
    try {
      final response = await _dio.get('/api/estudiantes/me/inscripciones');
      if (response.statusCode == 200) {
        await storage.write(key: 'cached_my_inscripciones', value: jsonEncode(response.data));
        return response.data;
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_my_inscripciones');
      if (cached != null) return jsonDecode(cached);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getStudentMe() async {
    try {
      final response = await _dio.get('/api/estudiantes/me');
      if (response.statusCode == 200) {
        // Guardamos en caché local para carga instantánea la próxima vez
        await storage.write(key: 'cached_student_data', value: jsonEncode(response.data));
        return response.data;
      }
      return null;
    } catch (e) {
      // Si falla la red, intentamos devolver lo que tenemos en caché
      final cached = await storage.read(key: 'cached_student_data');
      if (cached != null) {
        return jsonDecode(cached);
      }
      return null;
    }
  }

  Future<List<Anuncio>> getAnuncios() async {
    try {
      final response = await _dio.get('/api/anuncios');
      if (response.statusCode == 200) {
        final List data = response.data;
        await storage.write(key: 'cached_anuncios', value: jsonEncode(data));
        return data.map((e) => Anuncio.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching anuncios: $e");
      final cached = await storage.read(key: 'cached_anuncios');
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => Anuncio.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<List<Mensaje>> getMensajes(int asignaturaId) async {
    try {
      final response = await _dio.get('/api/mensajes/$asignaturaId');
      if (response.statusCode == 200) {
        final List data = response.data;
        await storage.write(key: 'cached_messages_$asignaturaId', value: jsonEncode(data));
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_messages_$asignaturaId');
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<List<Mensaje>> getMensajesPrivados(int peerUserId) async {
    try {
      final response = await _dio.get('/api/mensajes/privado/$peerUserId');
      if (response.statusCode == 200) {
        final List data = response.data;
        await storage.write(key: 'cached_messages_priv_$peerUserId', value: jsonEncode(data));
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_messages_priv_$peerUserId');
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<List<Mensaje>> getMensajesCarrera(int carreraId) async {
    try {
      final response = await _dio.get('/api/mensajes/carrera/$carreraId');
      if (response.statusCode == 200) {
        final List data = response.data;
        await storage.write(key: 'cached_messages_carrera_$carreraId', value: jsonEncode(data));
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_messages_carrera_$carreraId');
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => Mensaje.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<List<dynamic>> getMisChats() async {
    try {
      final response = await _dio.get('/api/mensajes/mis-chats');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMensaje(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/mensajes', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> generarPinAsistencia(int? carreraId) async {
    try {
      final response = await _dio.post('/api/coordinadores/generar-pin', data: {'carreraId': carreraId});
      return response.statusCode == 200 ? response.data : {'pin': null};
    } catch (e) {
      return {'pin': null};
    }
  }

  Future<List<dynamic>> getPinesActivos() async {
    try {
      final response = await _dio.get('/api/coordinadores/pines-activos');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      debugPrint("Error fetching active pins: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCoordinadorMe() async {
    try {
      final response = await _dio.get('/api/coordinadores/me');
      if (response.statusCode == 200) {
        await storage.write(key: 'cached_coord_data', value: jsonEncode(response.data));
        return response.data;
      }
    } catch (e) {
      final cached = await storage.read(key: 'cached_coord_data');
      if (cached != null) return jsonDecode(cached);
    }
    return null;
  }

  Future<bool> validarPinDocente(String pin) async {
    try {
      final response = await _dio.post('/api/asistencias/validar-pin', data: {'pin': pin});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registrarAsistenciaQR(int estudianteId, int asignaturaId) async {
    try {
      final response = await _dio.post(
        '/api/asistencias/qr',
        data: {"estudianteId": estudianteId, "asignaturaId": asignaturaId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- EVALUACIONES ---

  Future<List<dynamic>> getEvaluaciones(int asignaturaId) async {
    try {
      final response = await _dio.get('/api/evaluaciones/asignatura/$asignaturaId');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createEvaluacion(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/evaluaciones', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- ARANCELES ---

  Future<bool> validarArancel(String cedula, String factura) async {
    try {
      final response = await _dio.post('/api/aranceles/validar', data: {
        'cedula': cedula,
        'numeroFactura': factura,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getArancelStatus(String cedula) async {
    try {
      final response = await _dio.get('/api/aranceles/status/$cedula');
      return response.statusCode == 200 ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getReporteAsistenciaDocente() async {
    try {
      final response = await _dio.get('/api/reportes/asistencia-docente');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  // --- Admin Data ---

  Future<List<dynamic>> getCarreras() async => _getBlockCached("carreras");
  Future<List<dynamic>> getSemestres() async => _getBlockCached("semestres");
  Future<List<dynamic>> getPeriodos() async => _getBlockCached("periodos");

  Future<List<dynamic>> _getBlockCached(String endpoint) async {
    final cacheKey = 'cache_$endpoint';
    
    final cached = await _getCached<List>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.get('/api/admindata/$endpoint');
      if (response.statusCode == 200) {
        await _setCached(cacheKey, response.data, ttl: _defaultCacheTTL);
        return response.data as List;
      }
    } catch (e) {
      debugPrint('Error fetching $endpoint: $e');
      final fallback = await _getCached<List>(cacheKey);
      if (fallback != null) return fallback;
    }
    return [];
  }

  @deprecated
  Future<List<dynamic>> _getBlock(String endpoint) async {
    try {
      final response = await _dio.get('/api/admindata/$endpoint');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addCarrera(String nombre) async =>
      _addBlock("carreras", {"nombre": nombre});
  Future<bool> addSemestre(String nombre) async =>
      _addBlock("semestres", {"nombre": nombre});
  Future<bool> addPeriodo(String nombre) async =>
      _addBlock("periodos", {"nombre": nombre, "activo": true});

  Future<bool> _addBlock(String endpoint, Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/admindata/$endpoint', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAdminData(String endpoint, int id) async {
    try {
      await _dio.delete('/api/admindata/$endpoint/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- HORARIOS ---

  Future<List<dynamic>> getHorarios(int asignaturaId) async {
    try {
      final response = await _dio.get('/api/horarios/asignatura/$asignaturaId');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createHorario(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/horarios', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteHorario(int id) async {
    try {
      await _dio.delete('/api/horarios/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getInscripcionesByAsignatura(int asignaturaId) async {
    try {
      final response = await _dio.get(
        '/api/inscripciones/asignatura/$asignaturaId',
      );
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      debugPrint("Error fetching enrollments: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registrarAcceso(
    String cedula,
    String tipo,
  ) async {
    try {
      final response = await _dio.post(
        '/api/controlacceso/registrar',
        data: {"cedula": cedula, "tipo": tipo},
      );
      if (response.statusCode == 200) {
        return {
          "success": true,
          "nombre": response.data['nombre'],
          "rol": response.data['rol'],
          "hora": response.data['fecha'],
        };
      }
      return {"success": false, "message": "Error desconocido"};
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          "success": false,
          "message": e.response?.data?.toString() ?? "Error",
        };
      }
      return {"success": false, "message": "Error de conexión"};
    }
  }

  Future<List<dynamic>> getHistorialAccesos() async {
    try {
      final response = await _dio.get('/api/controlacceso/historial');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> registrarAperturaAula(String cedula, String aula) async {
    try {
      final response = await _dio.post(
        '/api/controlacceso/apertura',
        data: {"cedula": cedula, "ubicacion": aula},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error opening classroom: $e");
      return false;
    }
  }

  // --- USUARIOS (Admin) ---

  Future<List<dynamic>> getUsuarios({String? search, String? rol, bool? activo, int page = 1, int limit = 20}) async {
    final cacheKey = 'cache_usuarios_p${page}';
    
    if (page == 1 && search == null && rol == null && activo == null) {
      final cached = await _getCached<List>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (rol != null) params['rol'] = rol;
      if (activo != null) params['activo'] = activo.toString();

      final response = await _dio.get('/api/usuarios', queryParameters: params);

      if (response.statusCode == 200) {
        if (page == 1 && search == null && rol == null && activo == null) {
          await _setCached(cacheKey, response.data, ttl: _listCacheTTL);
        }
        return response.data as List;
      }
    } catch (e) {
      if (page == 1 && search == null && rol == null && activo == null) {
        final cached = await _getCached<List>(cacheKey);
        if (cached != null) return cached;
      }
    }
    return [];
  }

  Future<bool> updateUsuario(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/usuarios/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUsuario(int id) async {
    try {
      await _dio.delete('/api/usuarios/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPasswordUsuario(int id, String newPassword) async {
    try {
      await _dio.post('/api/usuarios/$id/reset-password', data: {"nuevaContrasena": newPassword});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getRoles() async {
    try {
      final response = await _dio.get('/api/admindata/roles');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAuditLogs() async {
    try {
      final response = await _dio.get('/api/audit');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAnuncio(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/anuncios', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAulas({String? edificio, String? estado}) async {
    try {
      final params = <String, dynamic>{};
      if (edificio != null) params['edificio'] = edificio;
      if (estado != null) params['estado'] = estado;
      final response = await _dio.get('/api/aulas', queryParameters: params);
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> solicitarApertura(int aulaId, String? motivo) async {
    try {
      final response = await _dio.post('/api/aulas/solicitar-apertura', data: {
        'aulaId': aulaId,
        'motivo': motivo,
      });
      return response.statusCode == 200 ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getSolicitudesApertura({String? estado}) async {
    try {
      final params = <String, dynamic>{};
      if (estado != null) params['estado'] = estado;
      final response = await _dio.get('/api/aulas/solicitudes', queryParameters: params);
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> marcarEnCamino(int solicitudId) async {
    try {
      await _dio.put('/api/aulas/solicitudes/$solicitudId/en-camino');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completarApertura(int solicitudId) async {
    try {
      await _dio.put('/api/aulas/solicitudes/$solicitudId/completar');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- SETTINGS ---

  Future<String?> getGlobalSetting(String clave) async {
    try {
      final response = await _dio.get('/api/settings/$clave');
      return response.statusCode == 200 ? response.data['valor'].toString() : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setGlobalSetting(String clave, String valor) async {
    try {
      final response = await _dio.post('/api/settings', data: {'clave': clave, 'valor': valor});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> extractEvaluationPlan(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'plan.pdf'),
      });
      final response = await _dio.post('/api/planevaluacion/extract-pdf', data: formData);
      return response.statusCode == 200 ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> liberarAula(int aulaId) async {
    try {
      await _dio.put('/api/aulas/$aulaId/liberar');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- CACHE HELPERS ---

  /// Get data from cache (in-memory + disk) with TTL check
  Future<T?> _getCached<T>(String key) async {
    // Check in-memory cache first (fastest)
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        return entry.data as T?;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Check disk cache as fallback
    try {
      final cached = await storage.read(key: key);
      if (cached != null) {
        final data = jsonDecode(cached);
        // Restore to memory cache
        _memoryCache[key] = _CacheEntry(data, _defaultCacheTTL);
        return data as T?;
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  /// Set data in cache (in-memory + disk)
  Future<void> _setCached<T>(String key, T data, {Duration? ttl}) async {
    ttl ??= _defaultCacheTTL;
    
    // Set in-memory cache
    _memoryCache[key] = _CacheEntry(data, ttl);

    // Set disk cache
    try {
      final encoded = data is String ? data : jsonEncode(data);
      await storage.write(key: key, value: encoded);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Clear cache by prefix
  Future<void> _clearCacheByPrefix(String prefix) async {
    _memoryCache.removeWhere((key, _) => key.startsWith(prefix));
  }
}

/// Cache entry with TTL support
class _CacheEntry {
  final dynamic data;
  final DateTime expiration;

  _CacheEntry(this.data, Duration ttl) 
    : expiration = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiration);
}
