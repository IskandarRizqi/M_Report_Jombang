import 'dart:convert';
import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/absen.dart';
import 'package:ehr_report/api/api.dart';
import 'package:ehr_report/cuti.dart';
import 'package:ehr_report/elibrary.dart';
import 'package:ehr_report/exam.dart';
import 'package:ehr_report/handler/imageNetwork.dart';
import 'package:ehr_report/kpi.dart';
import 'package:ehr_report/kunjungan.dart';
import 'package:ehr_report/lembur.dart';
import 'package:ehr_report/pagelogin.dart';
import 'package:ehr_report/widget/widgethalamanutama.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assumed to have a login page

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {required this.prevPage, this.alertPop, this.infoPop, super.key});

  final String prevPage;
  final String? alertPop;
  final String? infoPop;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> halamanData = [];
  bool isLoading = true;
  int totalPegawai = 0;
  int totalAbsenHariIni = 0;
  int totalCutiHariIni = 0;
  int totalTerlambat = 0;
  int totalPerempuan = 0;
  int totalLaki = 0;
  int totalAbsenKemarin = 0;
  int totalTerlambatKemarin = 0;
  int totalCutiKemarin = 0;
  int totalMasukLuarLokasiHariIni = 0;
  int totalMasukLuarLokasiKemarin = 0;
  int totalKeluarLuarLokasiHariIni = 0;
  int totalKeluarLuarLokasiKemarin = 0;
  String _username = '-';
  String namaPegawai = '';
  String nip = '';
  String jabatan = '';
  String shortName = "";
  DateTime? pickedDate;

  Image _profimg = Image.asset(
    'assets/images/def_img.png',
    width: 100,
    height: 100,
    fit: BoxFit.fill,
  );
  @override
  void initState() {
    super.initState();
    getuser(); // Panggil fungsi untuk memuat data pengguna
    fetchWidgetkpi();
    fetchHalamanProfil();
  }

  Future<void> fetchWidgetkpi() async {
    try {
      setState(() {
        isLoading = true;
      });

      var url =
          '/widgetdashboardreport?tanggal=${pickedDate != null ? DateFormat('yyyy-MM-dd').format(pickedDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now())}';
      var dat = await ApiHandler().getData(url);
      debugPrint('API Response widget Status Code: ${dat.statusCode}');
      debugPrint('API Response widget Body: ${dat.body}');

      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);

        setState(() {
          totalPegawai = jsonResponse['total_pegawai'] ?? 0;
          totalAbsenHariIni = jsonResponse['total_absen_hari_ini'] ?? 0;
          totalTerlambat = jsonResponse['total_terlambat'] ?? 0;
          totalPerempuan = jsonResponse['total_pegawai_perempuan'] ?? 0;
          totalLaki = jsonResponse['total_pegawai_laki'] ?? 0;
          totalAbsenKemarin = jsonResponse['total_absen_kemarin'] ?? 0;
          totalTerlambatKemarin = jsonResponse['total_terlambat_kemarin'] ?? 0;
          totalCutiHariIni = jsonResponse['totalCutiHariIni'] ?? 0;
          totalCutiKemarin = jsonResponse['totalCutiHariKemarin'] ?? 0;
          totalMasukLuarLokasiHariIni =
              jsonResponse['totalMasukLuarLokasiHariIni'] ?? 0;
          totalMasukLuarLokasiKemarin =
              jsonResponse['totalMasukLuarLokasiKemarin'] ?? 0;
          totalKeluarLuarLokasiHariIni =
              jsonResponse['totalKeluarLuarLokasiHariIni'] ?? 0;
          totalKeluarLuarLokasiKemarin =
              jsonResponse['totalKeluarLuarLokasiKemarin'] ?? 0;
          shortName = jsonResponse['short_name'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Invalid data format');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> fetchHalamanProfil() async {
    try {
      setState(() {
        isLoading = true;
      });

      var url = '/halamanprofil';
      var dat = await ApiHandler().getData(url);
      debugPrint('API Response profil Status Code: ${dat.statusCode}');
      debugPrint('API Response profil widget Body: ${dat.body}',
          wrapWidth: 2034);

      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);

        if (jsonResponse.containsKey('data')) {
          final Map<String, dynamic> data = jsonResponse['data'];

          setState(() {
            namaPegawai = data['nama'] ?? '';
            jabatan = data['jabatan'] ?? '';
            nip = data['nip'] ?? '';
            isLoading = false;
          });

          debugPrint('Nama Pegawai: $namaPegawai');
          debugPrint('nip$nip');
          debugPrint('jabatan $jabatan');
        } else {
          throw Exception('Data tidak ditemukan dalam respons API');
        }
      } else {
        throw Exception('Invalid data format');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _doLogout() async {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('You will be logged out of this app'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () async {
                      var res = await ApiHandler().authOut();
                    },
                    child: const Text('Accept')),
              ],
            ));
  }

  void _showDetailPegawai(String title, String tanggal, String type) async {
    if (tanggal == 'kemarin') {
      tanggal = DateFormat('yyyy-MM-dd').format(DateTime.parse(
              pickedDate != null
                  ? pickedDate.toString()
                  : DateTime.now().toString())
          .subtract(const Duration(days: 1)));
    }
    // Fetch data dulu, EasyLoading otomatis muncul dari getData
    var response = await ApiHandler()
        .getData('/detailabsensidashboard?tanggal=$tanggal&type=$type');
    bool isKeterangan =
        true; //true sembunyikan kolom keterangan, false tampilkan kolom keterangan

    if (type == 'cuti') {
      isKeterangan = false;
    }

    if (type == 'masuk_luar_lokasi') {
      isKeterangan = false;
    }

    if (type == 'keluar_luar_lokasi') {
      isKeterangan = false;
    }

    List<dynamic> data = [];
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      data = jsonResponse['data'] ?? [];
    }
    debugPrint('Data cuti: detailabsensidashboard?tanggal=$tanggal&type=$type');
    debugPrint('Data cuti: $data');

    // Baru tampilkan bottom sheet setelah data siap
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A260),
                  ),
                ),
              ),
              const Divider(),
              // Tabel
              Expanded(
                child: data.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Table(
                            border:
                                TableBorder.all(color: Colors.grey.shade300),
                            columnWidths: isKeterangan
                                ? const {
                                    0: FixedColumnWidth(40),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(2),
                                  }
                                : const {
                                    0: FixedColumnWidth(40),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                  },
                            children: [
                              // Header
                              TableRow(
                                decoration: const BoxDecoration(
                                    color: Color(0xFF00A260)),
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('No',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('NIP',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Nama',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Visibility(
                                      visible: !isKeterangan,
                                      child: const Text(
                                        'Keterangan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              // Data
                              ...List.generate(data.length, (index) {
                                final item = data[index];
                                return TableRow(
                                  decoration: BoxDecoration(
                                      color: index % 2 == 0
                                          ? Colors.white
                                          : Colors.grey.shade50),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text('${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                          item['nip']?.toString() ?? '-',
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                          item['nama']?.toString() ?? '-',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Visibility(
                                        visible: !isKeterangan,
                                        child: Text(
                                          item['keterangan']?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDateYesterday = DateFormat(
      "EEEE, dd MMMM yyyy",
      "id_ID",
    ).format(
      pickedDate != null
          ? pickedDate!.subtract(const Duration(days: 1))
          : DateTime.now().subtract(const Duration(days: 1)),
    );

    String formattedDate = DateFormat(
      "EEEE, dd MMMM yyyy",
      "id_ID",
    ).format(
      pickedDate ?? DateTime.now(),
    );

    return Scaffold(
        body: SingleChildScrollView(
            child: Stack(
                clipBehavior: Clip.none, // ← tambah ini
                children: [
          // Blue Background with gradient
          Container(
            height: 300, // Height for the blue header
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00A260),
                  Color(0xFF00A260),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Dashboard Row with Logout Icon on the right
                Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // IconButton(
                      //   icon: Icon(Icons.refresh, color: Colors.white),
                      //   onPressed: () {
                      //     fetchWidgetkpi(); // Panggil fungsi untuk refresh data
                      //   },
                      // ),

                      const SizedBox(width: 40),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _doLogout(),
                      ),
                    ],
                  ),
                ),
                Text(
                  shortName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Profile Row
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 65,
                          height: 65,
                          color: Colors.white,
                          child: _profimg,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaPegawai,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              jabatan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              nip,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
              ],
            ),
          ),

          // White Container with Rounded Top
          Positioned(
            top: 230,
            left: 0,
            right: 0,
            child: Container(
              height: 2000,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Menu Row Positioned to meet the white container's curve
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enables horizontal scrolling
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  buildMenuItem(
                      'assets/images/kpi.png', 'KPI', const KPIPage(), context),
                  buildMenuItem(
                      'assets/images/absensi.png',
                      'Absensi',
                      const AbsensiPage(
                        prevPage: '',
                      ),
                      context),
                  buildMenuItem(
                      'assets/images/cuti.png',
                      'Cuti',
                      const EmployeeLeavePage(
                        prevPage: '',
                      ),
                      context),
                  // buildMenuItem('assets/images/exam.png', 'Exam', ExamApp(),
                  //     context), // New menu item,
                  // buildMenuItem('assets/images/library.png', 'Elibrary',
                  //     ElibraryApp(), context),
                  buildMenuItem(
                      'assets/images/lembur.png',
                      'Lembur',
                      const LemburPage(
                        prevPage: '',
                      ),
                      context),
                  buildMenuItem(
                      'assets/images/kunjungan.png',
                      'Kunjungan',
                      const KunjunganScreen(
                        prevPage: '',
                      ),
                      context),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          // Performance Growth Section
          Padding(
            padding: const EdgeInsets.only(top: 280),
            child: Column(
              children: [
                // Performance Growth Section
                Container(
                  padding: const EdgeInsets.all(10),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: pickedDate != null
                                      ? DateFormat('dd-MM-yyyy')
                                          .format(pickedDate!)
                                      : DateFormat('dd-MM-yyyy')
                                          .format(DateTime.now()),
                                ),
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Pilih tanggal',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: const Icon(Icons.calendar_today,
                                      size: 18),
                                ),
                                onTap: () async {
                                  DateTime? selected = await showDatePicker(
                                    context: context,
                                    initialDate: pickedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );

                                  if (selected != null) {
                                    setState(() {
                                      pickedDate = selected;
                                      fetchWidgetkpi();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // SizedBox(
                          //   height: 30,
                          //   child: IconButton(
                          //     padding: EdgeInsets.zero,
                          //     constraints: BoxConstraints(),
                          //     icon: Icon(Icons.refresh, color: Colors.black),
                          //     onPressed: () {
                          //       fetchWidgetkpi();
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Statistik Pegawai",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  )),

                              /// Row agar selalu 3 card dalam satu baris
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoCard(
                                      "Total Pegawai",
                                      "$totalPegawai Orang",
                                      Icons.group,
                                      Colors.blue),
                                  _buildInfoCard(
                                      "Pegawai Pria",
                                      "$totalLaki Orang",
                                      Icons.male,
                                      Colors.blue),
                                  _buildInfoCard(
                                      "Pegawai Wanita",
                                      "$totalPerempuan Orang",
                                      Icons.female,
                                      Colors.pink),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoCard(
                                        "Total Absen",
                                        "$totalAbsenHariIni Orang",
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                      _buildInfoCard(
                                        "Pegawai Terlambat",
                                        "$totalTerlambat Orang",
                                        Icons.warning_amber_rounded,
                                        Colors.orange,
                                        onTap: () => _showDetailPegawai(
                                          'Terlambat - $formattedDate',
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate ?? DateTime.now()),
                                          'terlambat',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Tidak Absen",
                                        "${totalPegawai - totalAbsenHariIni - totalCutiHariIni} Orang",
                                        Icons.cancel,
                                        Colors.red,
                                        onTap: () => _showDetailPegawai(
                                          'Tidak Absen - $formattedDate',
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate ?? DateTime.now()),
                                          'tidak_absen',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoCard(
                                        "Cuti / Izin",
                                        "$totalCutiHariIni Orang",
                                        Icons.event_available,
                                        Colors.green,
                                        onTap: () => _showDetailPegawai(
                                          'Cuti / Izin - $formattedDate',
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate ?? DateTime.now()),
                                          'cuti',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Masuk Luar Lokasi",
                                        "$totalMasukLuarLokasiHariIni Orang",
                                        Icons.login_rounded,
                                        Colors.blue,
                                        onTap: () => _showDetailPegawai(
                                          'Masuk Luar Lokasi - $formattedDate',
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate ?? DateTime.now()),
                                          'masuk_luar_lokasi',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Keluar Luar Lokasi",
                                        "$totalKeluarLuarLokasiHariIni Orang",
                                        Icons.logout_rounded,
                                        Colors.purple,
                                        onTap: () => _showDetailPegawai(
                                          'Keluar Luar Lokasi - $formattedDate',
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate ?? DateTime.now()),
                                          'keluar_luar_lokasi',
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                formattedDateYesterday,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoCard(
                                        "Total Absen",
                                        "$totalAbsenKemarin Orang",
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                      _buildInfoCard(
                                        "Pegawai Terlambat",
                                        "$totalTerlambatKemarin Orang",
                                        Icons.warning_amber_rounded,
                                        Colors.orange,
                                        onTap: () => _showDetailPegawai(
                                          'Terlambat - $formattedDateYesterday',
                                          'kemarin',
                                          'terlambat',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Tidak Absen",
                                        "${totalPegawai - totalAbsenKemarin - totalCutiKemarin} Orang",
                                        Icons.cancel,
                                        Colors.red,
                                        onTap: () => _showDetailPegawai(
                                          'Tidak Absen - $formattedDateYesterday',
                                          'kemarin',
                                          'tidak_absen',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoCard(
                                        "Cuti / Izin",
                                        "$totalCutiKemarin Orang",
                                        Icons.event_available,
                                        Colors.green,
                                        onTap: () => _showDetailPegawai(
                                          'Cuti / Izin - $formattedDateYesterday',
                                          'kemarin',
                                          'cuti',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Masuk Luar Lokasi",
                                        "$totalMasukLuarLokasiKemarin Orang",
                                        Icons.login_rounded,
                                        Colors.blue,
                                        onTap: () => _showDetailPegawai(
                                          'Masuk Luar Lokasi - $formattedDateYesterday',
                                          'kemarin',
                                          'masuk_luar_lokasi',
                                        ),
                                      ),
                                      _buildInfoCard(
                                        "Keluar Luar Lokasi",
                                        "$totalKeluarLuarLokasiKemarin Orang",
                                        Icons.logout_rounded,
                                        Colors.purple,
                                        onTap: () => _showDetailPegawai(
                                          'Keluar Luar Lokasi - $formattedDateYesterday',
                                          'kemarin',
                                          'keluar_luar_lokasi',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ])));
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.white,
          child: SizedBox(
            height: 105, // tinggi semua card disamakan
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMenuItem(
      String iconPath, String label, Widget targetPage, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Card(
        elevation: 3, // Memberikan efek shadow pada Card
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15), // Membuat sudut rounded untuk Card
        ),
        child: Container(
          width: 65, // Menyesuaikan lebar untuk ikon dan teks
          height: 65, // Menyesuaikan tinggi untuk ikon dan teks
          padding: const EdgeInsets.all(10), // Memberikan padding di dalam Card
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Mengatur konten di tengah
            children: [
              Image.asset(iconPath,
                  width: 30, height: 25, fit: BoxFit.contain), // Ikon
              const SizedBox(height: 5), // Jarak antara ikon dan teks
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8, // Ukuran font untuk teks label
                  fontWeight: FontWeight.bold, // Memberikan font tebal
                ),
                textAlign: TextAlign.center, // Mengatur teks di tengah
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Circular progress builder
  Widget _buildCircularProgress(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 77,
                height: 77,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Circular ratio builder
  Widget _buildCircularRatio(
      String label, String description, double progress) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 75,
                height: 75,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void getuser() async {
    SharedPreferences locStor = await SharedPreferences.getInstance();
    var usr = locStor.getString('user');
    print('Data user dari SharedPreferences: $usr');
    var usrName = '-';
    if (usr != null && usr != '') {
      var usrDec = jsonDecode(usr);
      usrName = usrDec['name'];
    }
    var img = await ImageNetwork().getimageprofil();
    if (widget.alertPop != null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'PERINGATAN!',
        desc: widget.alertPop,
        btnCancel: null,
        btnOkOnPress: () {},
      ).show();
    }
    if (widget.infoPop != null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'INFO!',
        desc: widget.infoPop,
        btnCancel: null,
        btnOkOnPress: () {},
      ).show();
    }
    setState(() {
      // _fab = FloatingButtonAttendance(currentMenu: 'home');
      _profimg = img;
      _username = usrName;
      print('Username updated: $_username');
      print('image updated: $img');
      // _jabatan = usrJabatan;
      // _startTime = st;
      // _endTime = et;
      // _menu = rowmenu;
    });
  }
}
