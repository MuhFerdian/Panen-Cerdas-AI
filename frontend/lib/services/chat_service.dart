import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hasil dari ChatService — membawa teks jawaban dan flag error.
class ChatResult {
  final bool isError;
  final String text;

  const ChatResult({required this.isError, required this.text});
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

        // Backend mengembalikan success: false → tampilkan pesan error
        if (data["success"] == false) {
          return ChatResult(
            isError: true,
            text: data["message"]?.toString() ?? "Terjadi kesalahan pada AI.",
          );
        }

        return ChatResult(
          isError: false,
          text: data["answer"]?.toString() ?? "Tidak ada jawaban.",
        );
      }

      return ChatResult(
        isError: true,
        text: "Server mengembalikan error ${response.statusCode}.",
      );
    } catch (e) {
      return ChatResult(
        isError: true,
        text: "Koneksi gagal. Pastikan backend berjalan.",
      );
    }
  }
}