import 'dart:convert';
import 'package:http/http.dart' as http;

// Model data hasil estimasi dari Gemini
class HarvestResult {
  final String estimasiHariPanen;
  final double estimasiHasilKg;
  final String tingkatRisiko;
  final String faktorRisiko;
  final List<String> rekomendasi;
  final String catatanPenting;

  HarvestResult({
    required this.estimasiHariPanen,
    required this.estimasiHasilKg,
    required this.tingkatRisiko,
    required this.faktorRisiko,
    required this.rekomendasi,
    required this.catatanPenting,
  });

  factory HarvestResult.fromJson(Map<String, dynamic> json) {
    return HarvestResult(
      estimasiHariPanen: json['estimasi_hari_panen']?.toString() ?? '-',
      estimasiHasilKg: _toDouble(json['estimasi_hasil_kg']),
      tingkatRisiko: json['tingkat_risiko']?.toString() ?? 'Sedang',
      faktorRisiko: json['faktor_risiko']?.toString() ?? '',
      rekomendasi: _toStringList(json['rekomendasi']),
      catatanPenting: json['catatan_penting']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  static List<String> _toStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }
}

class EstimateService {
  // Ganti dengan URL backend production saat deploy ke cloud
  static const String baseUrl = "http://localhost:8000";

  static Future<Map<String, dynamic>> estimateHarvest({
    required double luasLahan,
    required int umurTanaman,
    required int jumlahBibit,
    required String kondisiTanaman,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/estimate-harvest"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "luas_lahan": luasLahan,
              "umur_tanaman": umurTanaman,
              "jumlah_bibit": jumlahBibit,
              "kondisi_tanaman": kondisiTanaman,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Backend mengembalikan success: false → kembalikan sebagai error
        if (body['success'] == false) {
          return {
            'status': 'error',
            'message': body['message']?.toString() ?? 'Terjadi kesalahan pada AI.',
          };
        }

        return body;
      }

      // Coba baca pesan error dari server
      try {
        final err = jsonDecode(response.body);
        return {
          "status": "error",
          "message": err["detail"] ?? "Error ${response.statusCode}"
        };
      } catch (_) {
        return {"status": "error", "message": "Error ${response.statusCode}"};
      }
    } catch (e) {
      return {
        "status": "error",
        "message": "Koneksi gagal. Pastikan backend berjalan.\n\nDetail: $e",
      };
    }
  }
}
