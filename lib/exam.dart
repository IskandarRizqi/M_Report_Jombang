import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';

class ExamApp extends StatefulWidget {
  const ExamApp({Key? key}) : super(key: key);

  @override
  _ExamAppState createState() => _ExamAppState();
}

class _ExamAppState extends State<ExamApp> {
  late Future<List<Exam>> futureExam;
  List<Exam> allExamData = [];
  List<Exam> filteredExamData = [];
  List<Exam> paginatedExamData = [];
  int currentPage = 1;
  final int itemsPerPage = 10; // Jumlah data per halaman
  int totalPages = 1;
  String selectedBranch = 'Semua Cabang'; // Default pilihan cabang
  String selectedMonth = 'Semua Bulan'; // Default pilihan bulan
  List<String> branches = ['Semua Cabang']; // Default cabang

  final List<String> months = [
    'Semua Bulan',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  List<Exam> exams = []; // Awalnya kosong untuk data dari API
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    futureExam = getExamData(); // Memuat data saat widget diinisialisasi
  }

  Future<List<Exam>> getExamData() async {
    try {
      String month = months.indexOf(selectedMonth).toString();
      String year = DateTime.now().year.toString();
      var url = '/examreport?month=$month&year=$year';
      print('Fetching data with filters - Month: $month, Year: $year');
      var dat = await ApiHandler().getData(url);
      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          List<Exam> examDataList =
              data.map((item) => Exam.fromJson(item)).toList();
          examDataList.sort((a, b) => a.nama.compareTo(b.nama));

          // final branchSet = <String>{'Semua Cabang'};
          // for (var examData in examDataList) {
          //   branchSet.add(examData.kantorCabang);
          // }
          List<String> allBranches = ['Semua Cabang'];
          if (jsonResponse.containsKey('semua_kantor')) {
            final List<dynamic> kantor = jsonResponse['semua_kantor'];
            allBranches = ['Semua Cabang', ...kantor.map((k) => k.toString())];
          }

          setState(() {
            branches = allBranches.toList();
            allExamData = examDataList;
            filteredExamData = examDataList;
            totalPages = (filteredExamData.length / itemsPerPage).ceil();
            updatePaginatedData();
            isLoading = false;
            exams = examDataList;
          });
          return examDataList;
        } else {
          throw Exception('invalid data format');
        }
      } else {
        throw Exception(
            'Failed to fetch exam data. status code ${dat.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Eror: $e');
      return [];
    }
  }

  void applyFilter() {
    setState(() {
      filteredExamData = allExamData.where((exam) {
        bool matchesBranch = selectedBranch == 'Semua Cabang' ||
            exam.kantorCabang == selectedBranch;
        bool matchesMonth = selectedMonth == 'Semua Bulan' ||
            DateTime.parse(exam.tanggal_pengisian).month ==
                months.indexOf(selectedMonth);
        return matchesBranch && matchesMonth;
      }).toList();
      filteredExamData
          .sort((a, b) => a.nama.compareTo(b.nama)); // Urutkan berdasarkan nama
      currentPage = 1;
      totalPages = (filteredExamData.length / itemsPerPage).ceil();
      updatePaginatedData();
    });
    print('Applied Filters: Branch - $selectedBranch, Month - $selectedMonth');
    print('Filtered Data Count: ${filteredExamData.length}');
  }

  void updatePaginatedData() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    setState(() {
      paginatedExamData = filteredExamData.sublist(
          startIndex, endIndex.clamp(0, filteredExamData.length));
    });
  }

  void goToNextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        updatePaginatedData();
      });
    }
  }

  void goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        updatePaginatedData();
      });
    }
  }

  void showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exam',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF007BFF),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedBranch,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    items: branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(
                          branch,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBranch = value!;
                        applyFilter();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedMonth,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 14, // font bulan 14
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    items: months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(
                          month,
                          style: const TextStyle(
                            fontSize: 14, // font item dropdown bulan
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                        applyFilter();
                      });
                    },
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'List Akses Exam',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: exams.isEmpty
                ? const Center(
                    child: Text(
                      "Data Kosong",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ) // Indikator loading
                : SingleChildScrollView(
                    // Membungkus dengan SingleChildScrollView untuk scroll vertikal
                    scrollDirection: Axis.vertical,

                    child: Table(
                      border: TableBorder.all(
                          color: Colors.grey.shade300, width: 1.5),
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FixedColumnWidth(120),
                        2: FixedColumnWidth(120),
                        3: FixedColumnWidth(100),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.shade100,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          children: [
                            tableCell('No', isHeader: true),
                            tableCell('Nama', isHeader: true),
                            tableCell('Jabatan', isHeader: true),
                            tableCell('Skor', isHeader: true),
                          ],
                        ),
                        ...paginatedExamData.asMap().entries.map((entry) {
                          int index = entry.key + 1;
                          Exam exam = entry.value;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.grey.shade100
                                  : Colors.white,
                            ),
                            children: [
                              tableCell(index.toString()),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPage(exam: exam),
                                    ),
                                  );
                                },
                                child: tableCell(exam.nama),
                              ),
                              tableCell(exam.jabatan),
                              tableCell(exam.nilai),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: goToPreviousPage,
                child: const Text('Back'),
              ),
              Text('Page $currentPage of $totalPages'),
              TextButton(
                onPressed: goToNextPage,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String createdAt) {
    try {
      DateTime date =
          DateTime.parse(createdAt); // Parse string menjadi DateTime
      return DateFormat('dd MMM yyyy')
          .format(date); // Format tanggal menjadi "dd MMM yyyy"
    } catch (e) {
      return 'Invalid Date'; // Jika gagal, tampilkan 'Invalid Date'
    }
  }

  List<Exam> _getUniqueExam() {
    final Set<String> seenNames = {};
    final List<Exam> uniqueExams = [];

    for (var exam in exams) {
      if (!seenNames.contains(exam.nama)) {
        seenNames.add(exam.nama);
        uniqueExams.add(exam);
      }
    }
    return uniqueExams;
  }

  int _getAccessCount(String name) {
    return exams.where((exam) => exam.nama == name).length;
  }

  Widget tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class Exam {
  final String nama;
  final String jabatan;
  final String profil;
  final String usia;
  final String created_at;
  final String nip;
  final String kategori;
  final String kantorCabang;
  final String tanggal_pengisian;
  final String nilai;

  Exam(
      {required this.nama,
      required this.jabatan,
      required this.profil,
      required this.usia,
      required this.created_at,
      required this.nip,
      required this.kategori,
      required this.kantorCabang,
      required this.tanggal_pengisian,
      required this.nilai});
  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      nama: json['nama'] ?? '',
      jabatan: json['jabatan'] ?? '',
      profil: json['profil'] ?? '',
      usia: json['usia'].toString(),
      created_at: json['created_at'].toString() ?? '',
      nip: json['nip'].toString(),
      kategori: json['kategori'] ?? '',
      kantorCabang: json['kantor_cabang'] ?? '',
      tanggal_pengisian: json['tanggal_pengisian'] ?? '',
      nilai: json['nilai'] ?? '',
    );
  }
}

class DetailPage extends StatefulWidget {
  final Exam exam;

  const DetailPage({Key? key, required this.exam}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Map<String, dynamic>> exam = []; // Data pegawai yang akan ditampilkan
  bool isLoading = false; // Indikator loading

  @override
  void initState() {
    super.initState();
    // fetchEmployeeData(); // Memuat data pegawai berdasarkan nama yang diterima
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007BFF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Loading indicator
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(30),
                                  image: DecorationImage(
                                    image: exam.profil.isNotEmpty
                                        ? (exam.profil.startsWith('http')
                                            ? NetworkImage(
                                                exam.profil) // URL gambar
                                            : AssetImage(exam.profil)
                                                as ImageProvider) // Path lokal
                                        : const AssetImage(
                                            'assets/images/default.jpg'), // Gambar default
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.nama,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exam.jabatan,
                                    style: const TextStyle(
                                        fontSize: 14, color: Color(0xFF007BFF)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NIP: ${exam.nip}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Usia: ${exam.usia} Tahun',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Kantor: ${exam.kantorCabang}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Kategori: ${exam.kategori}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Nilai: ${exam.nilai}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Tanggal Pengisian: ${DateFormat('dd MMM yyyy').format(DateTime.parse(exam.tanggal_pengisian))}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14, // Ubah ukuran font menjadi 14
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
