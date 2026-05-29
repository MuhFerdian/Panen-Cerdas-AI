import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service untuk men-generate dokumen PDF hasil analisis tanaman
class PdfService {
  /// Generate PDF document berdasarkan data hasil analisis
  static Future<Uint8List> generateAnalysisPdf({
    required Map<String, dynamic> data,
    required bool isFallback,
  }) async {
    final pdf = pw.Document();

    // Ekstrak data
    final penyakit = data['penyakit']?.toString() ?? 'Tidak Diketahui';
    final confidence = data['confidence']?.toString() ?? '0';
    final keparahan = data['keparahan']?.toString() ?? '-';
    final status = data['status']?.toString() ?? '-';
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

    // Warna tema
    final PdfColor primaryColor = PdfColor.fromHex('#2E7D32'); // Hijau Tua
    final PdfColor secondaryColor = PdfColor.fromHex('#4CAF50'); // Hijau Muda
    final PdfColor bgLight = PdfColor.fromHex('#F1F8E9');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 24),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primaryColor, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Panen Cerdas AI',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Laporan Analisis Tanaman',
                  style: pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Identitas Analisis
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: secondaryColor, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Identifikasi Penyakit',
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    penyakit,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem('Tingkat Keyakinan', '$confidence%'),
                      _buildInfoItem('Keparahan', keparahan),
                      _buildInfoItem('Status', status),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Waktu Analisis & Mode
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Waktu Analisis: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  isFallback
                      ? 'Mode: Offline (Database Lokal)'
                      : 'Mode: Online (AI)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: isFallback ? PdfColors.orange700 : primaryColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // Detail Analisis
            _buildSection(primaryColor, 'Gejala Terdeteksi', gejala),
            _buildSection(primaryColor, 'Penyebab', penyebab),

            // Solusi (List)
            _buildListSection(primaryColor, 'Solusi Penanganan', solusi),

            // Pencegahan (List)
            _buildListSection(primaryColor, 'Langkah Pencegahan', pencegahan),

            // Pupuk
            _buildSection(primaryColor, 'Rekomendasi Pupuk', pupuk),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildSection(PdfColor color, String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildListSection(
    PdfColor color,
    String title,
    List<String> items,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          if (items.isEmpty)
            pw.Text('-', style: const pw.TextStyle(fontSize: 12))
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '• ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              item,
                              style: const pw.TextStyle(
                                fontSize: 12,
                                lineSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
