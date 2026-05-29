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
