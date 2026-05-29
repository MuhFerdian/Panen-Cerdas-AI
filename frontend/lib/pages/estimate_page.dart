import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/estimate_service.dart';

class EstimatePage extends StatefulWidget {
  const EstimatePage({super.key});

  @override
  State<EstimatePage> createState() => _EstimatePageState();
}

class _EstimatePageState extends State<EstimatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _luasController = TextEditingController();
  final _umurController = TextEditingController();
  final _bibitController = TextEditingController();

  String _kondisi = 'Baik';
  bool _loading = false;
  bool _isFallback = false;
  HarvestResult? _harvestResult;
  String? _rawFallback;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _luasController.dispose();
    _umurController.dispose();
    _bibitController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _harvestResult = null;
      _rawFallback = null;
      _errorMessage = null;
    });
    _animController.reset();

    final response = await EstimateService.estimateHarvest(
      luasLahan: double.parse(_luasController.text),
      umurTanaman: int.parse(_umurController.text),
      jumlahBibit: int.parse(_bibitController.text),
      kondisiTanaman: _kondisi,
    );

    setState(() => _loading = false);

    if (response['status'] == 'success') {
      setState(() {
        _isFallback = response['fallback'] == true;
        _harvestResult = HarvestResult.fromJson(response['data']);
      });
      _animController.forward();
    } else if (response['status'] == 'fallback') {
      setState(() {
        _isFallback = false;
        _rawFallback = response['raw']?.toString() ?? '';
      });
      _animController.forward();
    } else {
      setState(() => _errorMessage = response['message']?.toString() ?? 'Terjadi kesalahan.');
    }
  }

  void _reset() {
    setState(() {
      _isFallback = false;
      _harvestResult = null;
      _rawFallback = null;
      _errorMessage = null;
    });
    _animController.reset();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'rendah':
        return const Color(0xFF2E7D32);
      case 'tinggi':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'rendah':
        return Icons.check_circle_rounded;
      case 'tinggi':
        return Icons.dangerous_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String? _validatePositiveInt(String? v, String field, {int max = 9999999}) {
    if (v == null || v.isEmpty) return 'Masukkan $field';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Harus berupa angka positif';
    if (n > max) return 'Nilai terlalu besar (maks $max)';
    return null;
  }

  String? _validatePositiveDouble(String? v, String field) {
    if (v == null || v.isEmpty) return 'Masukkan $field';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Harus berupa angka positif';
    return null;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      appBar: AppBar(
        title: const Text(
          '📊 Estimasi Panen',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          if (_harvestResult != null || _rawFallback != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Hitung Ulang',
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormCard(primary),
            const SizedBox(height: 16),
            _buildCalculateButton(primary),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(),
            ],
            if (_harvestResult != null || _rawFallback != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _harvestResult != null
                      ? _buildResults(primary)
                      : _buildRawFallback(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Form Card ───────────────────────────────────────────────────────────

  Widget _buildFormCard(Color primary) {
    return Card(
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.agriculture_rounded, color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Lahan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Isi semua data di bawah ini',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Luas Lahan
              _inputField(
                controller: _luasController,
                label: 'Luas Lahan',
                hint: 'Contoh: 500',
                suffix: 'm²',
                icon: Icons.square_foot_rounded,
                primary: primary,
                allowDecimal: true,
                validator: (v) => _validatePositiveDouble(v, 'luas lahan'),
              ),
              const SizedBox(height: 14),

              // Umur Tanaman
              _inputField(
                controller: _umurController,
                label: 'Umur Tanaman',
                hint: 'Contoh: 45',
                suffix: 'hari',
                icon: Icons.calendar_today_rounded,
                primary: primary,
                allowDecimal: false,
                validator: (v) => _validatePositiveInt(v, 'umur tanaman', max: 120),
              ),
              const SizedBox(height: 14),

              // Jumlah Bibit
              _inputField(
                controller: _bibitController,
                label: 'Jumlah Bibit',
                hint: 'Contoh: 1000',
                suffix: 'bibit',
                icon: Icons.eco_rounded,
                primary: primary,
                allowDecimal: false,
                validator: (v) => _validatePositiveInt(v, 'jumlah bibit'),
              ),
              const SizedBox(height: 20),

              // Kondisi Tanaman
              Text(
                'Kondisi Tanaman',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _kondisiChip('Baik', Icons.thumb_up_rounded, const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _kondisiChip('Sedang', Icons.thumbs_up_down_rounded, const Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  _kondisiChip('Buruk', Icons.thumb_down_rounded, const Color(0xFFC62828)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required Color primary,
    required bool allowDecimal,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
        ),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _kondisiChip(String label, IconData icon, Color color) {
    final isSelected = _kondisi == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kondisi = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? color : Colors.grey[400], size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Calculate Button ────────────────────────────────────────────────────

  Widget _buildCalculateButton(Color primary) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _calculate,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI sedang menghitung...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Hitung Estimasi Panen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Error Banner ────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result Cards ─────────────────────────────────────────────────────────

  Widget _buildResults(Color primary) {
    final r = _harvestResult!;
    final rColor = _riskColor(r.tingkatRisiko);
    final rIcon = _riskIcon(r.tingkatRisiko);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section label
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Hasil Estimasi Panen',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            // Badge Mode Offline
            if (_isFallback) ...[
              const SizedBox(width: 10),
              _offlineBadge(),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // ── Main Summary Card (gradient) ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  icon: Icons.access_time_rounded,
                  label: 'Waktu Panen',
                  value: r.estimasiHariPanen,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _summaryMetric(
                  icon: Icons.scale_rounded,
                  label: 'Estimasi Hasil',
                  value: '${r.estimasiHasilKg.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Risk Card ─────────────────────────────────────────────────────
        Card(
          elevation: 2,
          shadowColor: rColor.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(rIcon, color: rColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tingkat Risiko',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: rColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: rColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          r.tingkatRisiko,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: rColor,
                          ),
                        ),
                      ),
                      if (r.faktorRisiko.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.faktorRisiko,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Rekomendasi Card ──────────────────────────────────────────────
        if (r.rekomendasi.isNotEmpty)
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: const Color(0xFFF9A825), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rekomendasi Tindakan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...r.rekomendasi.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                    fontSize: 13, height: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Catatan Penting Card ──────────────────────────────────────────
        if (r.catatanPenting.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Penting',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.catatanPenting,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
      ],
    );
  }

  Widget _summaryMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 26),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ─── Raw Fallback ─────────────────────────────────────────────────────────

  Widget _buildRawFallback() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.article_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                'Hasil dari AI',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(_rawFallback ?? '', style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }

  // ─── Offline Badge ─────────────────────────────────────────────────

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
}
