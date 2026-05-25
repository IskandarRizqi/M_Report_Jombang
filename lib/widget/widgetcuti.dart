import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ehr_report/api/api.dart';

class Widgetcuti extends StatefulWidget {
  final String pegawaiId;
  const Widgetcuti({Key? key, required this.pegawaiId}) : super(key: key);

  @override
  State<Widgetcuti> createState() => _WidgetcutiState();
}

class _WidgetcutiState extends State<Widgetcuti> {
  List<Map<String, dynamic>> kpiData = [];
  bool isLoading = true;
  int maxCuti = 0;
  int countCuti = 0;
  @override
  void initState() {
    super.initState();
    fetchdatacuti();
  }

  Future<void> fetchdatacuti() async {
    debugPrint(
        'fetchWidgetkpi() dipanggil dengan pegawaiId: ${widget.pegawaiId}');
    String apiUrl = '/datacutireport/${widget.pegawaiId}';

    try {
      debugPrint('Mengirim request ke API: $apiUrl');

      var response = await ApiHandler().postData(apiUrl, null).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      // debugPrint('API Response Status Code: ${response.statusCode}');
      // debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        debugPrint('Mengirim request ke API: ${response.body}',
            wrapWidth: 1034);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          var dataMap = jsonResponse['data'];

          if (dataMap is Map<String, dynamic>) {
            setState(() {
              maxCuti = dataMap['maxcuti'] ?? 0;
              countCuti = dataMap['countcuti'] ?? 0;
              isLoading = false;
            });

            // debugPrint('Max Cuti: $maxCuti');
            // debugPrint('Count Cuti: $countCuti');
            return;
          }
        }
      } else {
        debugPrint('Request gagal dengan status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat fetch data cuti: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int sisaCuti = maxCuti - countCuti;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF00A260),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCutiColumn('Total Cuti', maxCuti),
                _buildCutiColumn('Cuti Diambil', countCuti),
                _buildCutiColumn('Sisa Cuti', sisaCuti),
              ],
            ),
    );
  }
}

Widget _buildCutiColumn(String title, int value) {
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${value}h',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    ),
  );
}
