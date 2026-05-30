import 'package:flutter/material.dart';
import '../services/history_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final HistoryService _historyService = HistoryService();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Dashboard Panen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        actions: [
          // Refresh Dashboard
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              setState(() {});
            },
          ),

          // Reset Data
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Reset Data',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Reset Data'),
                    content: const Text(
                      'Yakin ingin menghapus seluruh riwayat aktivitas dan statistik?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),

                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await _historyService.clearAll();

                if (!context.mounted) return;

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil direset')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeBanner(primary),
            const SizedBox(height: 16),
            _buildTotalActivityCard(),
            const SizedBox(height: 12),
            _buildLastUpdateCard(),
            const SizedBox(height: 24),
            _buildInsightCard(),
            const SizedBox(height: 24),
            const Text(
              'Grafik Tren Penyakit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDiseaseTrendChart(primary),
            const SizedBox(height: 24),
            const Text(
              'Rekomendasi Musim Tanam',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPlantingRecommendation(primary),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Aktivitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatCards(primary),
            const SizedBox(height: 24),
            const Text(
              'Grafik Penggunaan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSimpleChart(primary),
            const SizedBox(height: 24),
            const Text(
              'Penyakit Terbanyak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTopDisease(primary),
            const SizedBox(height: 24),
            const Text(
              'Aktivitas Terakhir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(primary),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(Color primary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, Petani Cerdas! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Berikut adalah ringkasan kebun bawang merah Anda.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalActivityCard() {
    final total =
        _historyService.chatCount +
        _historyService.analyzeCount +
        _historyService.estimateCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: Colors.green, size: 28),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Aktivitas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  '$total aktivitas tercatat',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PENYAKIT TERBANYAK
  Widget _buildLastUpdateCard() {
    final lastTime = _historyService.getLastActivityTime();

    String text;

    if (lastTime == null) {
      text = 'Belum ada aktivitas';
    } else {
      text =
          '${lastTime.day.toString().padLeft(2, '0')}/'
          '${lastTime.month.toString().padLeft(2, '0')}/'
          '${lastTime.year} '
          '${lastTime.hour.toString().padLeft(2, '0')}:'
          '${lastTime.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: Colors.blue),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Terakhir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 4),

                Text(text, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card Insight Kebun AI — menampilkan rekomendasi otomatis berdasarkan histori
  /// analisis penyakit dan Smart Score kesehatan kebun.
  Widget _buildInsightCard() {
    final insight = _historyService.getInsightMessage();
    final score = _historyService.getHealthScore();
    final topDisease = _historyService.getTopDisease();
    final hasData = topDisease != '-';

    // Tentukan warna & label sesuai skor
    final Color scoreColor;
    final String scoreLabel;
    if (score >= 80) {
      scoreColor = Colors.green.shade600;
      scoreLabel = 'Baik';
    } else if (score >= 60) {
      scoreColor = Colors.orange.shade600;
      scoreLabel = 'Perlu Perhatian';
    } else {
      scoreColor = Colors.red.shade600;
      scoreLabel = 'Kritis';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: scoreColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Insight Kebun AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Badge status skor
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: pesan insight
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insight message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 16),

                // Smart Score: Kesehatan Kebun
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kesehatan Kebun',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              ' / 100',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Progress ring visual sederhana
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 7,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scoreColor,
                            ),
                          ),
                          Center(
                            child: Text(
                              '$score%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Info tambahan jika belum ada data
                if (!hasData) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lakukan Analisis Foto untuk mengaktifkan insight personal.',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rekomendasi Musim Tanam — card modern berbasis data penyakit dominan
  /// yang diambil dari HistoryService.getPlantingRecommendation().
  Widget _buildPlantingRecommendation(Color primaryColor) {
    final rec = _historyService.getPlantingRecommendation();

    final String status = rec['status'] as String;
    final List<String> recommendations = List<String>.from(
      rec['recommendation'] as List,
    );
    final String disease = rec['disease'] as String;
    final String colorType = rec['colorType'] as String;

    // Tentukan palet warna berdasarkan colorType
    final Color mainColor;
    final Color bgColor;
    final Color borderColor;
    final IconData statusIcon;

    switch (colorType) {
      case 'red':
        mainColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade100;
        statusIcon = Icons.warning_rounded;
        break;
      case 'orange':
        mainColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade100;
        statusIcon = Icons.info_rounded;
        break;
      case 'green':
        mainColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade100;
        statusIcon = Icons.check_circle_rounded;
        break;
      default: // grey — belum ada data
        mainColor = Colors.grey.shade600;
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.eco_rounded, color: mainColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Rekomendasi Musim Tanam',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: mainColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight penyakit dominan (hanya jika ada data)
                if (disease != '-') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.coronavirus_outlined,
                          color: mainColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Penyakit Dominan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mainColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                disease,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Label rekomendasi
                Row(
                  children: [
                    Icon(Icons.checklist_rounded, color: mainColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      disease == '-' ? 'Langkah Awal' : 'Rekomendasi Tindakan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: mainColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Daftar rekomendasi
                ...recommendations.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nomor urut dalam lingkaran kecil
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: mainColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$idx',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: mainColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grafik Tren Penyakit — horizontal bar chart berbasis data riil dari HistoryService.
  /// Tidak menggunakan package chart eksternal, hanya Container + Row + Expanded.
  Widget _buildDiseaseTrendChart(Color primary) {
    final stats = _historyService.getDiseaseStatistics();
    final topDisease = _historyService.getTopDiseaseTrend();
    final topCount = _historyService.getTopDiseaseTrendCount();

    // --- EMPTY STATE ---
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada data tren penyakit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lakukan analisis foto terlebih dahulu untuk\nmelihat tren penyakit tanaman.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // Nilai terbesar sebagai 100% lebar bar
    final int maxCount = stats.values.first; // sudah diurutkan terbesar

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- CHART CARD ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul kecil dalam card
              Row(
                children: [
                  Icon(Icons.trending_up, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Frekuensi Deteksi per Penyakit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bar chart rows — tampilkan max 6 penyakit teratas
              ...stats.entries.take(6).map((entry) {
                final name = entry.key;
                final count = entry.value;
                final barFraction = maxCount == 0 ? 0.0 : count / maxCount;
                final isTop = name == topDisease;

                // Pilih warna: penyakit teratas = primaryColor, sisanya abu-abu
                final barColor = isTop ? primary : Colors.grey.shade400;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Label nama penyakit (lebar tetap)
                      SizedBox(
                        width: 120,
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isTop
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isTop ? primary : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Bar
                      Expanded(
                        child: Stack(
                          children: [
                            // Track abu-abu penuh
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            // Bar berwarna
                            FractionallySizedBox(
                              widthFactor: barFraction.clamp(0.04, 1.0),
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: barColor.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Angka kemunculan
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isTop ? primary : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Keterangan
              const SizedBox(height: 4),
              Text(
                '* Menampilkan ${stats.length > 6 ? "6 dari ${stats.length}" : stats.length.toString()} penyakit terdeteksi',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // --- INSIGHT TAMBAHAN DI BAWAH GRAFIK ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penyakit paling dominan:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topDisease,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Terdeteksi $topCount kali. Disarankan monitoring rutin setiap 2–3 hari.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(Color primary) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Chat AI',
            value: _historyService.chatCount.toString(),
            icon: Icons.chat_bubble_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Analisis',
            value: _historyService.analyzeCount.toString(),
            icon: Icons.camera_alt_outlined,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Estimasi',
            value: _historyService.estimateCount.toString(),
            icon: Icons.bar_chart_outlined,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(Color primary) {
    int maxVal = _historyService.chatCount;
    if (_historyService.analyzeCount > maxVal) {
      maxVal = _historyService.analyzeCount;
    }
    if (_historyService.estimateCount > maxVal) {
      maxVal = _historyService.estimateCount;
    }

    // Fallback jika kosong semua
    if (maxVal == 0) {
      maxVal = 10;
    }

    // Tambah sedikit margin atas untuk chart
    maxVal = (maxVal * 1.2).toInt();

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _barChartItem('Chat', _historyService.chatCount, maxVal, Colors.blue),
          _barChartItem(
            'Foto',
            _historyService.analyzeCount,
            maxVal,
            Colors.orange,
          ),
          _barChartItem(
            'Estimasi',
            _historyService.estimateCount,
            maxVal,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _barChartItem(String label, int value, int maxVal, Color color) {
    final double heightPercent = maxVal == 0 ? 0 : value / maxVal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: value == 0 ? 12 : (100 * heightPercent).clamp(12, 180),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopDisease(Color primary) {
    String topDisease = _historyService.getTopDisease();
    int topDiseaseCount = _historyService.getTopDiseaseCount();
    bool isEmpty =
        topDisease == '-' || topDisease == 'Penyakit Tidak Diketahui';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey.shade100 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmpty ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isEmpty
                      ? Colors.grey.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.coronavirus_outlined,
              color: isEmpty ? Colors.grey : Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmpty ? 'Belum Ada Data' : topDisease,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEmpty ? Colors.grey.shade700 : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmpty
                      ? 'Ayo mulai analisis foto tanaman Anda'
                      : 'Terdeteksi $topDiseaseCount kali',
                  style: TextStyle(
                    fontSize: 14,
                    color: isEmpty ? Colors.grey : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Color primary) {
    final activities = _historyService.getRecentActivities();

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Aktivitas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mulai gunakan fitur Chat AI, Analisis Foto, atau Estimasi Panen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: activities.take(5).toList().asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          bool isLast =
              idx == (activities.length > 5 ? 4 : activities.length - 1);

          IconData icon;
          Color color;

          if (item.type == 'Analisis Foto') {
            icon = Icons.camera_alt;
            color = Colors.orange;
          } else if (item.type == 'Estimasi Panen') {
            icon = Icons.bar_chart;
            color = Colors.green;
          } else {
            icon = Icons.chat_bubble;
            color = Colors.blue;
          }

          // Format waktu
          final diff = DateTime.now().difference(item.timestamp);
          String timeStr;
          if (diff.inMinutes < 1) {
            timeStr = 'Baru saja';
          } else if (diff.inMinutes < 60) {
            timeStr = '${diff.inMinutes} menit yang lalu';
          } else if (diff.inHours < 24) {
            timeStr = '${diff.inHours} jam yang lalu';
          } else {
            timeStr = '${diff.inDays} hari yang lalu';
          }

          return _activityItem(
            icon: icon,
            color: color,
            title: '${item.type}: ${item.result}',
            time: timeStr,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required bool isLast,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            time,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: Color(0xFFEEEEEE),
          ),
      ],
    );
  }
}
