import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ehr_report/api/api.dart';

class Pertumbuhankinerja extends StatefulWidget {
  final String pegawaiId;
  const Pertumbuhankinerja({Key? key, required this.pegawaiId})
      : super(key: key);

  @override
  State<Pertumbuhankinerja> createState() => _PertumbuhankinerjaState();
}

class _PertumbuhankinerjaState extends State<Pertumbuhankinerja> {
  List<Map<String, dynamic>> kpiData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPertumbuhanKinerja();
  }

  Future<void> fetchPertumbuhanKinerja() async {
    String apiUrl = '/pertumbuhankinerjabar/${widget.pegawaiId}';

    // ✅ Pakai tahun berjalan, tampilkan sampai bulan sekarang
    final now = DateTime.now();
    final int tahun = now.year;
    final int bulanSekarang = now.month;

    final List<Map<String, dynamic>> template =
        List.generate(bulanSekarang, (i) {
      final month = i + 1;
      return {
        'kpi_date': '$tahun-${month.toString().padLeft(2, '0')}-01',
        'penambah': 0,
        'pengurang': 0,
        'kedisiplinan': 0,
      };
    });

    try {
      var response = await ApiHandler().getData(apiUrl);
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        List dataList = [];
        if (jsonResponse is List) {
          dataList = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          dataList = jsonResponse['data'] as List;
        }

        debugPrint('dataList length: ${dataList.length}');

        for (var item in dataList) {
          final date = DateTime.parse(item['kpi_date']);
          final index = date.month - 1;
          debugPrint('month: ${date.month}, index: $index');
          if (index >= 0 && index < template.length) {
            template[index]['penambah'] =
                (item['penambah'] as num?)?.toInt() ?? 0;
            template[index]['pengurang'] =
                (item['pengurang'] as num?)?.toInt() ?? 0;
            template[index]['kedisiplinan'] =
                (item['kedisiplinan'] as num?)?.toInt() ?? 0;
            debugPrint('template[$index] = ${template[index]}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() {
      kpiData = template;
      isLoading = false;
    });
  }

  String _bulan(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF007BFF), 'Penambah'),
              const SizedBox(width: 12),
              _legend(Colors.red, 'Pengurang'),
              const SizedBox(width: 12),
              _legend(Colors.green, 'Kedisiplinan'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250, // ✅ pakai SizedBox bukan AspectRatio
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                groupsSpace: 8,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['Penambah', 'Pengurang', 'Kedisiplinan'];
                      return BarTooltipItem(
                        '${labels[rodIndex]}\n${rod.toY.toInt()}%',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 == 0) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < kpiData.length) {
                          final date =
                              DateTime.parse(kpiData[index]['kpi_date']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_bulan(date.month),
                                style: const TextStyle(fontSize: 9)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                    left: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: kpiData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  // ✅ minimum 0.1 agar bar tetap render meski nilai 0
                  final penambah = ((data['penambah'] as num).toDouble());
                  final pengurang = ((data['pengurang'] as num).toDouble());
                  final kedisiplinan =
                      ((data['kedisiplinan'] as num).toDouble());

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: penambah,
                        color: penambah > 0
                            ? const Color(0xFF007BFF)
                            : Colors.grey.withOpacity(0.2),
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: pengurang,
                        color: pengurang > 0
                            ? Colors.red
                            : Colors.grey.withOpacity(0.2),
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: kedisiplinan,
                        color: kedisiplinan > 0
                            ? Colors.green
                            : Colors.grey.withOpacity(0.2),
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
