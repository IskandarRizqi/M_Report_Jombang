import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ehr_report/api/api.dart';

class Widgethalamanutama extends StatefulWidget {
  const Widgethalamanutama({super.key});

  @override
  State<Widgethalamanutama> createState() => _WidgethalamanutamaState();
}

class _WidgethalamanutamaState extends State<Widgethalamanutama> {
  List<Map<String, dynamic>> halamanData = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchWidgetkpi();
  }

  Future<void> fetchWidgetkpi() async {
    String apiUrl = '/widgetdashboardreport}';

    try {
      var response = await ApiHandler().getData(apiUrl);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        debugPrint(
            'API Response widget Status Code: ${jsonResponse.statusCode}');
        debugPrint('API Response widget Body: ${jsonResponse.body}');
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          var dataList = jsonResponse['data'];

          setState(() {
            halamanData = (dataList as List)
                .map((item) => {
                      'total_pegawai': item['total_pegawai'],
                      'total_absen_hari_ini': item['total_absen_hari_ini'],
                      'total_terlambat': item['total_terlambat'],
                      'total_pegawai_laki': item['total_pegawai_laki'],
                      'total_pegawai_perempuan':
                          item['total_pegawai_perempuan'],
                      'total_absen_kemarin': item['total_absen_kemarin'],
                      'total_terlambat_kemarin':
                          item['total_terlambat_kemarin'],
                    })
                .toList();

            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
