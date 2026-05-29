import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AnalyzeService {
  // Ganti dengan URL backend production saat deploy ke cloud
  static const String baseUrl = "http://localhost:8000";

  static Future<String> analyzeImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Deteksi tipe MIME dari ekstensi file
      final ext = imageFile.name.split('.').last.toLowerCase();
      final mimeSubtype = ext == 'png' ? 'png' : 'jpeg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/analyze-image"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["result"] ?? "Tidak ada hasil analisis.";
      }

      // Tampilkan pesan error dari server jika ada
      try {
        final errData = jsonDecode(response.body);
        return "❌ Error: ${errData["detail"] ?? response.statusCode}";
      } catch (_) {
        return "❌ Error ${response.statusCode}";
      }
    } catch (e) {
      return "❌ Koneksi gagal. Pastikan backend berjalan.\n\nDetail: $e";
    }
  }
}
