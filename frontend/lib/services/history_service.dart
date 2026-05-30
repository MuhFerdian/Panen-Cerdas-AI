import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityItem {
  final String type;
  final String result;
  final DateTime timestamp;

  ActivityItem({
    required this.type,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    type: json['type'],
    result: json['result'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class HistoryService {
  static const String _keyChatCount = 'stat_chat_count';
  static const String _keyAnalyzeCount = 'stat_analyze_count';
  static const String _keyEstimateCount = 'stat_estimate_count';
  static const String _keyActivities = 'activities_list';

  // Singleton pattern for easy usage
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  late SharedPreferences _prefs;
  bool _isInit = false;

  Future<void> init() async {
    if (!_isInit) {
      _prefs = await SharedPreferences.getInstance();
      _isInit = true;
    }
  }

  // --- STATS ---

  int get chatCount => _prefs.getInt(_keyChatCount) ?? 0;
  int get analyzeCount => _prefs.getInt(_keyAnalyzeCount) ?? 0;
  int get estimateCount => _prefs.getInt(_keyEstimateCount) ?? 0;

  // --- LOGGING ---

  Future<void> logChat(String topic) async {
    await init();
    _prefs.setInt(_keyChatCount, chatCount + 1);
    await _addActivity(
      ActivityItem(type: 'Chat AI', result: topic, timestamp: DateTime.now()),
    );
  }

  Future<void> logAnalyze(String diseaseName) async {
    await init();
    _prefs.setInt(_keyAnalyzeCount, analyzeCount + 1);
    await _addActivity(
      ActivityItem(
        type: 'Analisis Foto',
        result: diseaseName,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> logEstimate(String resultText) async {
    await init();
    _prefs.setInt(_keyEstimateCount, estimateCount + 1);
    await _addActivity(
      ActivityItem(
        type: 'Estimasi Panen',
        result: resultText,
        timestamp: DateTime.now(),
      ),
    );
  }

  // --- ACTIVITIES ---

  Future<void> _addActivity(ActivityItem item) async {
    final list = getRecentActivities();
    list.insert(0, item); // add to top
    if (list.length > 50) {
      list.removeLast(); // keep max 50 items
    }

    final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyActivities, jsonList);
  }

  List<ActivityItem> getRecentActivities() {
    if (!_isInit) return [];
    final jsonList = _prefs.getStringList(_keyActivities);
    if (jsonList == null) return [];

    return jsonList
        .map((str) => ActivityItem.fromJson(jsonDecode(str)))
        .toList();
  }

  // --- ANALYSIS OF TOP DISEASE ---
  String getTopDisease() {
    final list = getRecentActivities();

    final analyzeActivities = list
        .where((a) => a.type == 'Analisis Foto')
        .toList();

    if (analyzeActivities.isEmpty) return '-';

    final Map<String, int> counts = {};

    for (var a in analyzeActivities) {
      // Abaikan penyakit fallback/default yang menandakan gambar tidak dikenali
      if (a.result.toLowerCase().contains('tidak dikenali')) {
        continue;
      }
      counts[a.result] = (counts[a.result] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return '-';
    }

    String topDisease = '-';
    int maxCount = 0;

    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topDisease = entry.key;
      }
    }

    return topDisease;
  }

  /// JUMLAH KEMUNCULAN PENYAKIT TERBANYAK
  int getTopDiseaseCount() {
    final list = getRecentActivities();

    final analyzeActivities = list
        .where((a) => a.type == 'Analisis Foto')
        .toList();

    final Map<String, int> counts = {};

    for (var a in analyzeActivities) {
      if (a.result.toLowerCase().contains('tidak dikenali')) {
        continue;
      }

      counts[a.result] = (counts[a.result] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return 0;
    }

    return counts.values.reduce((curr, next) => curr > next ? curr : next);
  }

  // Tanggal aktivitas terakhir (bisa untuk analisis kapan pengguna paling aktif)
  DateTime? getLastActivityTime() {
    final activities = getRecentActivities();

    if (activities.isEmpty) {
      return null;
    }

    return activities.first.timestamp;
  }

  // --- INSIGHT KEBUN AI ---

  /// Mengembalikan pesan insight berdasarkan penyakit teratas yang terdeteksi.
  /// Tidak mengubah format data SharedPreferences.
  String getInsightMessage() {
    final top = getTopDisease();

    if (top == '-') {
      return 'Belum terdapat cukup data analisis. Silakan lakukan analisis foto tanaman untuk mendapatkan rekomendasi kebun.';
    }

    // Cocokkan berdasarkan substring agar fleksibel (misal: nama bisa berubah sedikit)
    final lower = top.toLowerCase();

    if (lower.contains('thrips')) {
      return 'Risiko Serangan Thrips meningkat. Disarankan melakukan monitoring daun setiap 2–3 hari dan melakukan penyemprotan preventif.';
    } else if (lower.contains('fusarium')) {
      return 'Gejala Layu Fusarium sering muncul. Periksa drainase lahan dan kurangi kelembapan tanah berlebih.';
    } else if (lower.contains('busuk') || lower.contains('botrytis')) {
      return 'Busuk Umbi terdeteksi beberapa kali. Pastikan penyimpanan hasil panen memiliki sirkulasi udara yang baik.';
    } else if (lower.contains('alternaria') || lower.contains('bercak')) {
      return 'Bercak Ungu (Alternaria) muncul dalam histori Anda. Atur jarak tanam agar tidak terlalu rapat dan jaga kebersihan lahan.';
    } else if (lower.contains('ulat')) {
      return 'Serangan Ulat Bawang terdeteksi. Pasang perangkap feromon dan periksa kelompok telur secara manual secara rutin.';
    } else if (lower.contains('antraknosa') ||
        lower.contains('bujang') ||
        lower.contains('patah')) {
      return 'Antraknosa (Mati Bujang) terdeteksi. Hentikan penyiraman berlebih dan semprotkan fungisida berbahan tebukonazol.';
    } else {
      return 'Penyakit "$top" sering terdeteksi. Segera konsultasikan dengan penyuluh pertanian dan terapkan langkah penanganan yang sesuai.';
    }
  }

  /// Menghitung Skor Kesehatan Kebun berdasarkan frekuensi kemunculan penyakit.
  /// Rumus: 100 - (jumlah kemunculan penyakit × 10), minimal 50.
  int getHealthScore() {
    final count = getTopDiseaseCount();
    final score = 100 - (count * 10);
    return score.clamp(50, 100);
  }

  // --- RESET DATA ---
  Future<void> clearAll() async {
    await init();

    await _prefs.remove(_keyChatCount);
    await _prefs.remove(_keyAnalyzeCount);
    await _prefs.remove(_keyEstimateCount);
    await _prefs.remove(_keyActivities);
  }
}
