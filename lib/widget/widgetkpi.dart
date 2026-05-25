import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ehr_report/api/api.dart';

class Widgetkpi extends StatefulWidget {
  final String pegawaiId;
  const Widgetkpi({Key? key, required this.pegawaiId}) : super(key: key);

  @override
  State<Widgetkpi> createState() => _WidgetkpiState();
}

class _WidgetkpiState extends State<Widgetkpi> {
  List<Map<String, dynamic>> kpiData2 = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWidgetkpi();
  }

  Future<void> fetchWidgetkpi() async {
    String apiUrl = '/widgetkpireport/${widget.pegawaiId}';

    try {
      var response = await ApiHandler().getData(apiUrl);
      debugPrint('Response widgetkpi: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          var data = jsonResponse['data'];

          if (data.containsKey('kpiringkas') &&
              data['kpiringkas'] is Map<String, dynamic>) {
            var kpiringkas = data['kpiringkas'] as Map<String, dynamic>;

            if (kpiringkas.containsKey('radd') &&
                kpiringkas['radd'] is Map<String, dynamic>) {
              var radd = kpiringkas['radd'] as Map<String, dynamic>;

              // ✅ Ambil key pertama
              String? matchingKey =
                  radd.keys.isNotEmpty ? radd.keys.first : null;

              if (matchingKey != null) {
                var selectedData = radd[matchingKey];
                if (mounted) {
                  setState(() {
                    kpiData2 = [
                      {'bulan': matchingKey, 'data': selectedData}
                    ];
                    isLoading = false;
                  });
                }
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String)
      return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildKPIIndicators(),
      ),
    );
  }

  Widget _buildKPIIndicators() {
    if (kpiData2.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nilai KPI masih kosong', style: TextStyle(fontSize: 13)),
        ),
      );
    }

    var kpiValues = kpiData2.first['data'];
    String bulan = kpiData2.first['bulan'] ?? '';

    double nilaiKpi = _parseDouble(kpiValues['KPI']);
    double nilaiDisiplin = _parseDouble(kpiValues['Kedisiplinan']);
    String indikator = kpiValues['Indikator']?.toString() ?? '-'; // ← string

    return Column(
      children: [
        Text(
          'Nilai KPI ($bulan)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ← KPI tanpa persen
            _buildCircularIndicator('KPI', nilaiKpi, const Color(0xFF007BFF)),
            // ← Kedisiplinan tanpa persen
            _buildCircularIndicator(
                'Kedisiplinan', nilaiDisiplin, Colors.green),
            // ← Indikator sebagai teks
            _buildIndicatorCircle('Indikator', indikator, Colors.orange),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

// ← Ubah tampilan: hapus % dari nilai
  Widget _buildCircularIndicator(String title, double value, Color color) {
    double percentage = value.clamp(0, 100);
    String displayValue = value.toStringAsFixed(0); // ← tanpa %

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5,
              ),
            ),
            Text(
              displayValue, // ← tanpa %
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildIndicatorCircle(String title, String text, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: 1, // full bulat
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
