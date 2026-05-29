import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hasil dari ChatService — membawa teks jawaban, flag error, dan flag fallback.
class ChatResult {
  final bool isError;
  final bool isFallback;
  final String text;

  const ChatResult({
    required this.isError,
    required this.isFallback,
    required this.text,
  });
}

class ChatService {
  // Ganti dengan URL backend production saat deploy ke cloud
  static const String baseUrl = "http://localhost:8000";

  static Future<ChatResult> sendQuestion(String question) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"question": question}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend mengembalikan success: false (misal gambar invalid)
        if (data["success"] == false) {
          return ChatResult(
            isError: true,
            isFallback: false,
            text: data["message"]?.toString() ?? "Terjadi kesalahan pada AI.",
          );
        }

        return ChatResult(
          isError: false,
          isFallback: data["fallback"] == true,
          text: data["answer"]?.toString() ?? "Tidak ada jawaban.",
        );
      }

      return ChatResult(
        isError: true,
        isFallback: false,
        text: "Server mengembalikan error ${response.statusCode}.",
      );
    } catch (e) {
      return ChatResult(
        isError: true,
        isFallback: false,
        text: "Koneksi gagal. Pastikan backend berjalan.",
      );
    }
  }
}
