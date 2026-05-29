import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../services/analyze_service.dart';
import '../services/history_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_page.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage>
    with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  AnalyzeResult? _result;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _result = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final result = await AnalyzeService.analyzeImage(_selectedImage!);

    if (!result.isError) {
      try {
        String cleanText = result.text
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();
        final data = jsonDecode(cleanText);
        final penyakit =
            data['penyakit']?.toString() ?? 'Penyakit Tidak Diketahui';
        HistoryService().logAnalyze(penyakit);
      } catch (_) {
        HistoryService().logAnalyze('Analisis Selesai');
      }
    }

    setState(() {
      _result = result;
      _loading = false;
    });

    // Snackbar hanya untuk error nyata (bukan fallback — fallback tetap berguna)
    if (result.isError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(result.text)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      appBar: AppBar(
        title: const Text(
          '🌿 Analisis Foto Tanaman',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (_selectedImage != null || _result != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reset',
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.1),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Foto tanaman bawang merah Anda, lalu AI akan mendiagnosa penyakit dan memberikan solusi.',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Upload / Preview area
            GestureDetector(
              onTap: _loading ? null : _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _imageBytes != null ? 260 : 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _imageBytes != null
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.4),
                    width: 2,
                    style: _imageBytes != null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: _imageBytes != null
                      ? Colors.transparent
                      : primaryColor.withValues(alpha: 0.04),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          // Overlay tap to change
                          if (!_loading)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ganti Foto',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : ScaleTransition(
                        scale: _pulseAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Tap untuk pilih foto tanaman',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Format: JPG atau PNG',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Analisis
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedImage != null && !_loading)
                    ? _analyzeImage
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: _selectedImage != null ? 4 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Menganalisis gambar...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.biotech_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Analisis Tanaman',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Hasil Analisis
            if (_result != null) ...[
              const SizedBox(height: 28),
              _buildResultCards(primaryColor),
              const SizedBox(height: 16),
              _buildExportButton(primaryColor),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(Color primary) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          Map<String, dynamic>? data;
          try {
            String cleanText = _result!.text
                .replaceAll(RegExp(r'```json|```'), '')
                .trim();
            data = jsonDecode(cleanText);
          } catch (_) {}

          if (data == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Hanya format JSON terstruktur yang dapat diekspor ke PDF.',
                ),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewPage(
                title: 'Preview PDF',
                buildPdf: () => PdfService.generateAnalysisPdf(
                  data: data!,
                  isFallback: _result!.isFallback,
                ),
              ),
            ),
          );
        },
        icon: Icon(Icons.picture_as_pdf, color: primary),
        label: Text(
          'Export PDF',
          style: TextStyle(
            color: primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCards(Color primary) {
    Map<String, dynamic>? data;
    try {
      // Bersihkan jika ada format code block markdown
      String cleanText = _result!.text
          .replaceAll(RegExp(r'```json|```'), '')
          .trim();
      data = jsonDecode(cleanText);
    } catch (e) {
      // Jika parsing gagal, fallback ke raw text/markdown
      data = null;
    }

    if (data == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hasil Analisis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_result?.isFallback == true) ...[
                    const Spacer(),
                    _offlineBadge(),
                    const SizedBox(width: 8),
                    _localDbBadge(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: MarkdownBody(data: _result!.text),
            ),
          ],
        ),
      );
    }

    // JSON berhasil di-parse
    final penyakit = data['penyakit']?.toString() ?? 'Tidak diketahui';
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
    final keparahan = data['keparahan']?.toString() ?? 'Tidak Diketahui';
    final status = data['status']?.toString() ?? 'Tidak Diketahui';
    final gejala = data['gejala']?.toString() ?? '-';
    final penyebab = data['penyebab']?.toString() ?? '-';
    final solusi =
        (data['solusi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    final pencegahan =
        (data['pencegahan'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final pupuk = data['pupuk']?.toString() ?? '-';

    Color statusColor;
    if (status.toLowerCase().contains('merah') ||
        status.toLowerCase().contains('segera')) {
      statusColor = Colors.red;
    } else if (status.toLowerCase().contains('kuning') ||
        status.toLowerCase().contains('perhatian')) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    Color keparahanColor;
    if (keparahan.toLowerCase().contains('berat')) {
      keparahanColor = Colors.red;
    } else if (keparahan.toLowerCase().contains('sedang')) {
      keparahanColor = Colors.orange;
    } else {
      keparahanColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.analytics_outlined, color: primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Hasil Analisis AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const Spacer(),
            if (_result?.isFallback == true) ...[
              _offlineBadge(),
              const SizedBox(width: 8),
              _localDbBadge(),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // 1. Card Identifikasi & Confidence
        Card(
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: confidence / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: primary,
                        strokeWidth: 6,
                      ),
                      Center(
                        child: Text(
                          '${confidence.toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Penyakit Terdeteksi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        penyakit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildChip(keparahan, keparahanColor),
                          _buildChip(status, statusColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Gejala
        _buildSectionCard(
          title: 'Gejala',
          icon: Icons.visibility_outlined,
          color: Colors.blue,
          content: Text(gejala, style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 12),

        // 3. Penyebab
        _buildSectionCard(
          title: 'Penyebab',
          icon: Icons.bug_report_outlined,
          color: Colors.orange,
          content: Text(penyebab, style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 12),

        // 4. Solusi
        if (solusi.isNotEmpty)
          _buildSectionCard(
            title: 'Solusi Penanganan',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: solusi
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(s, style: const TextStyle(height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),

        // 5. Pencegahan
        if (pencegahan.isNotEmpty)
          _buildSectionCard(
            title: 'Pencegahan',
            icon: Icons.shield_outlined,
            color: Colors.teal,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pencegahan
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(s, style: const TextStyle(height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),

        // 6. Pupuk
        _buildSectionCard(
          title: 'Rekomendasi Pupuk & Pestisida',
          icon: Icons.eco_outlined,
          color: Colors.green.shade700,
          content: Text(pupuk, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _offlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Mode Offline',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _localDbBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storage_rounded, size: 12, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            'Database Lokal',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
