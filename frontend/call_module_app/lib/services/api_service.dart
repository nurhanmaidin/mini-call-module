import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  // ── Helper: build headers with token ──────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // ── JOBS ──────────────────────────────────────────────────────────────────

  // Get all jobs (filtered by role on the backend)
  static Future<List<dynamic>> getJobs() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/jobs'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // CS: Create a new job
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/jobs'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return jsonDecode(response.body);
  }

  // Manager: Assign job to technician
  static Future<Map<String, dynamic>> assignJob(
    int jobId,
    int technicianId,
  ) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/jobs/$jobId/assign'),
      headers: await _headers(),
      body: jsonEncode({'technician_id': technicianId}),
    );
    return jsonDecode(response.body);
  }

  // Technician: Update job status
  static Future<Map<String, dynamic>> updateStatus(
    int jobId,
    String newStatus,
  ) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/jobs/$jobId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': newStatus}),
    );
    return jsonDecode(response.body);
  }

  // Manager: Get dashboard stats
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/dashboard'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // Manager: Get list of technicians (for assign dropdown)
  static Future<List<dynamic>> getTechnicians() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/jobs/technicians'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // CS: Upload photo for a job
  static Future<Map<String, dynamic>> uploadPhoto(int jobId, File photo) async {
    final token = await AuthService.getToken();

    // Multipart request — different from normal JSON request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/jobs/$jobId/upload'),
    );

    // Add the auth token
    request.headers['Authorization'] = 'Bearer $token';

    // Attach the photo file
    // 'photo' must match the key name in Flask: request.files['photo']
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // Manager: Download CSV export
  static Future<void> downloadCsv() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/dashboard/export/csv'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Save file to device downloads folder
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/jobs_export.csv';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open the file automatically
      await OpenFilex.open(filePath);
    } else {
      throw Exception('Failed to download CSV');
    }
  }
}
