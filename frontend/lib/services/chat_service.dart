import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {

  // Flutter Web
  static const String baseUrl = "http://localhost:8000";

  static Future<String> sendQuestion(
      String question) async {

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": question,
        }),
      );

      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");

      if (response.statusCode == 200) {

        final data =
            jsonDecode(response.body);

        return data["answer"] ??
            "Tidak ada jawaban";
      }

      return "Error ${response.statusCode}";
    }
    catch (e) {

      print("ERROR : $e");

      return "Koneksi gagal : $e";
    }
  }
}