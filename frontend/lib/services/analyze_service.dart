import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Hasil dari AnalyzeService — membawa teks hasil, flag error, dan flag fallback.
class AnalyzeResult {
  final bool isError;
  final bool isFallback;
  final String text;

  const AnalyzeResult({
    required this.isError,
    required this.isFallback,
    required this.text,
  });
}

class AnalyzeService {
  // Ganti dengan URL backend production saat deploy ke cloud
  static const String baseUrl = "http://localhost:8000";

  static Future<AnalyzeResult> analyzeImage(XFile imageFile) async {
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

        // Backend mengembalikan success: false (misal gambar invalid)
        if (data['success'] == false) {
          return AnalyzeResult(
            isError: true,
            isFallback: false,
            text: data['message']?.toString() ?? 'Terjadi kesalahan pada AI.',
          );
        }

        return AnalyzeResult(
          isError: false,
          isFallback: data['fallback'] == true,
          text: data['result']?.toString() ?? 'Tidak ada hasil analisis.',
        );
      }

      // Coba baca pesan error dari server
      try {
        final errData = jsonDecode(response.body);
        return AnalyzeResult(
          isError: true,
          isFallback: false,
          text: errData['message']?.toString() ?? 'Error ${response.statusCode}',
        );
      } catch (_) {
        return AnalyzeResult(
          isError: true,
          isFallback: false,
          text: 'Error ${response.statusCode}',
        );
      }
    } catch (e) {
      return AnalyzeResult(
        isError: true,
        isFallback: false,
        text: 'Koneksi gagal. Pastikan backend berjalan.',
      );
    }
  }
}
