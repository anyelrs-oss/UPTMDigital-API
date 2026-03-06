import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uptmdigital_app/models/anuncio.dart';
import 'package:uptmdigital_app/models/mensaje.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  factory ApiService() => instance;
  ApiService._();

  final Dio _dio = Dio();
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Control de entorno: usar --dart-define=API_ENV=render para apuntar a la nube
  static const String _envMode = String.fromEnvironment('API_ENV', defaultValue: 'local');

  static String get baseUrl {
    switch (_envMode) {
      case 'render':
        return "https://TU-API.onrender.com"; // <-- ACTUALIZAR CON TU URL REAL DE RENDER
      case 'somee':
        return "http://uptmdigitalapi.somee.com";
      case 'local':
      default:
        if (kIsWeb) return "http://localhost:5286";
        return "http://192.168.0.102:5286";
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
          handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'nombreUsuario': username,
        'contrasena': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final role = response.data['rol'];
        final userId = response.data['idUsuario'];

        if (kIsWeb) {
            // Web doesn't always support secure storage consistently in dev, use simple storage or just await
            await storage.write(key: 'jwt_token', value: token);
            await storage.write(key: 'user_role', value: role);
            await storage.write(key: 'user_id', value: userId.toString());
        } else {
            await storage.write(key: 'jwt_token', value: token);
            await storage.write(key: 'user_role', value: role);
            await storage.write(key: 'user_id', value: userId.toString());
        }

        return {'success': true, 'role': role, 'token': token};
      }
      return {'success': false, 'message': 'Credenciales inválidas'};
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
          final msg = e.response!.data['Message'] ?? e.response!.data['message'] ?? 'Error de autenticación';
          return {'success': false, 'message': msg};
      }
      return {'success': false, 'message': 'Falla de conexión con el servidor'};
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Error inesperado'};
    }
  }

  Future<Map<String, dynamic>> register(String cedula, String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'cedula': cedula,
        'username': username,
        'contrasena': password,
      });

      if (response.statusCode == 200) {
        return {'success': true, ...response.data};
      }
      return {'success': false, 'message': 'Error desconocido'};
    } on DioException catch (e) {
        if (e.response != null) {
            return {'success': false, 'message': e.response?.data['message'] ?? 'Error en el registro'};
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
        return {'success': false, 'message': 'Cédula no encontrada en el registro institucional.'};
      }
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Error de conexión'};
    }
  }

  Future<List<dynamic>> getEstudiantes() async {
    try {
      final response = await _dio.get('/api/estudiantes');
      return response.data;
    } catch (e) {
      return [];
    }
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

  Future<List<dynamic>> getProfesores() async {
    try {
      final response = await _dio.get('/api/profesores');
      return response.data;
    } catch (e) {
      return [];
    }
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
    try {
      final response = await _dio.get('/api/asignaturas');
      return response.data;
    } catch (e) {
      return [];
    }
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

  Future<List<dynamic>> getNotas() async {
    try {
      final response = await _dio.get('/api/notas');
      return response.data;
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

  Future<void> logout() async => await storage.delete(key: 'jwt_token');

  // --- DASHBOARD HELPERS ---

  Future<Map<String, dynamic>?> getProfessorMe() async {
    try {
      final response = await _dio.get('/api/profesores/me');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentMe() async {
    try {
      final response = await _dio.get('/api/estudiantes/me');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<Anuncio>> getAnuncios() async {
    try {
      final response = await _dio.get('/api/anuncios');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Anuncio.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching anuncios: $e");
    }
    return [];
  }

  Future<List<Mensaje>> getMensajes(int asignaturaId) async {
    try {
      final response = await _dio.get('/api/mensajes/$asignaturaId');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Mensaje.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
    return [];
  }

  Future<bool> sendMensaje(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/mensajes', data: data);
      return true;
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

  // --- Admin Data ---

  Future<List<dynamic>> getCarreras() async => _getBlock("carreras");
  Future<List<dynamic>> getSemestres() async => _getBlock("semestres");
  Future<List<dynamic>> getPeriodos() async => _getBlock("periodos");

  Future<List<dynamic>> _getBlock(String endpoint) async {
    try {
      final response = await _dio.get('/api/admindata/$endpoint');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addCarrera(String nombre) async => _addBlock("carreras", {"nombre": nombre});
  Future<bool> addSemestre(String nombre) async => _addBlock("semestres", {"nombre": nombre});
  Future<bool> addPeriodo(String nombre) async => _addBlock("periodos", {"nombre": nombre, "activo": true});

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
      final response = await _dio.get('/api/inscripciones/asignatura/$asignaturaId');
      return response.statusCode == 200 ? response.data as List : [];
    } catch (e) {
       print("Error fetching enrollments: $e");
       return [];
    }
  }
  Future<Map<String, dynamic>> registrarAcceso(String cedula, String tipo) async {
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
          "hora": response.data['fecha']
        };
      }
      return {"success": false, "message": "Error desconocido"};
    } on DioException catch (e) {
      if (e.response != null) {
        return {"success": false, "message": e.response?.data?.toString() ?? "Error"};
      }
      return {"success": false, "message": "Error de conexión"};
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
      print("Error opening classroom: $e");
      return false;
    }
  }
}
