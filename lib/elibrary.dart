import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';

class ElibraryApp extends StatefulWidget {
  const ElibraryApp({Key? key}) : super(key: key);

  @override
  _ElibraryAppState createState() => _ElibraryAppState();
}

class _ElibraryAppState extends State<ElibraryApp> {
  late Future<List<Employee>> futureEmployee;
  List<Employee> allLibraryData = [];
  List<Employee> filteredLibraryData = [];
  List<Employee> paginatedLibraryData = [];
  int currentPage = 1;
  final int itemsPerPage = 10; // Jumlah data per halaman
  List<String> branches = ['Semua Cabang'];
  int totalPages = 1;
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

  String selectedBranch = 'Semua Cabang';
  String selectedMonth = 'Semua Bulan';
  List<Employee> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    futureEmployee = getLibraryData();
  }

  Future<List<Employee>> getLibraryData() async {
    try {
      String month = months
          .indexOf(selectedMonth)
          .toString(); // Mendapatkan bulan sebagai string
      String year = DateTime.now().year.toString();
      var url = '/libraryreport?month=$month&year=$year';
      print('Fetching data with filters - Month: $month, Year: $year');
      var dat = await ApiHandler().getData(url);
      //    print('Status Code: ${dat.statusCode}');
      // print('Response Body: ${dat.body}');
      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);
        print('Decoded JSON: $jsonResponse');
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          print('Raw Data: $data');
          List<Employee> libraryDataList =
              data.map((item) => Employee.fromJson(item)).toList();
          libraryDataList.sort((a, b) => a.nama.compareTo(b.nama));

          final branchSet = <String>{'Semua Cabang'};
          for (var libraryData in libraryDataList) {
            branchSet.add(libraryData.kantorCabang);
          }
          setState(() {
            branches = branchSet.toList();
            allLibraryData = libraryDataList;
            filteredLibraryData = libraryDataList;
            totalPages = (filteredLibraryData.length / itemsPerPage).ceil();
            updatePaginatedData();
            isLoading = false;
            employees = libraryDataList;
          });
          return libraryDataList;
        } else {
          throw Exception('invalid data format');
        }
      } else {
        throw Exception(
            'Failed to fetch library data. status code: ${dat.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Eror: $e');
      return [];
    }
  }

  void applyFilter() {
    setState(() {
      filteredLibraryData = allLibraryData.where((library) {
        bool matchesBranch = selectedBranch == 'Semua Cabang' ||
            library.kantorCabang == selectedBranch;
        bool matchesMonth = selectedMonth == 'Semua Bulan' ||
            DateTime.parse(library.created_at).month ==
                months.indexOf(selectedMonth);
        return matchesBranch && matchesMonth;
      }).toList();
      filteredLibraryData
          .sort((a, b) => a.nama.compareTo(b.nama)); // Urutkan berdasarkan nama
      currentPage = 1;
      totalPages = (filteredLibraryData.length / itemsPerPage).ceil();
      updatePaginatedData();
    });
    print('Applied Filters: Branch - $selectedBranch, Month - $selectedMonth');
    print('Filtered Data Count: ${filteredLibraryData.length}');
  }

  void updatePaginatedData() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    setState(() {
      paginatedLibraryData = filteredLibraryData.sublist(
          startIndex, endIndex.clamp(0, filteredLibraryData.length));
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

  Widget tableCellWithIcon(IconData iconData, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: IconButton(
        icon: Icon(iconData, color: const Color(0xFF007BFF)),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-library',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF007BFF),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: getLibraryData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('No data available'))
              : Column(
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
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            items: months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(
                                  month,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value!;
                                applyFilter(); // Panggil applyFilter untuk memperbarui data berdasarkan bulan yang dipilih
                              });
                            },
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'List Akses Perpustakaan',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Table(
                              border: TableBorder.all(
                                  color: Colors.grey.shade300, width: 1.5),
                              columnWidths: const {
                                0: FixedColumnWidth(40),
                                1: FixedColumnWidth(120),
                                2: FixedColumnWidth(120),
                                3: FixedColumnWidth(80),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.shade100,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  children: [
                                    tableCell('No', isHeader: true),
                                    tableCell('Nama', isHeader: true),
                                    tableCell('Tanggal Akses', isHeader: true),
                                    tableCell('Detail', isHeader: true),
                                  ],
                                ),
                                ...paginatedLibraryData
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key + 1;
                                  Employee employee = entry.value;
                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: index.isEven
                                          ? Colors.grey.shade100
                                          : Colors.white,
                                    ),
                                    children: [
                                      tableCell(index.toString()),
                                      tableCell(employee.nama),
                                      tableCell(
                                          _formatDate(employee.created_at)),
                                      tableCellWithIcon(
                                        Icons.document_scanner_outlined,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailPage(
                                                  employee: employee),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
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

  // Mengambil daftar unik berdasarkan nama
  List<Employee> _getUniqueEmployees() {
    final Set<String> seenNames = {};
    final List<Employee> uniqueEmployees = [];

    for (var employee in employees) {
      if (!seenNames.contains(employee.nama)) {
        seenNames.add(employee.nama);
        uniqueEmployees.add(employee);
      }
    }
    return uniqueEmployees;
  }

  // Menghitung berapa kali nama muncul
  int _getAccessCount(String name) {
    return employees.where((employee) => employee.nama == name).length;
  }

  Widget tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
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

class Employee {
  final String nama;
  final String jabatan;
  final String profil;
  final String usia;
  final String created_at;
  final String nip;
  final String namaBuku;
  final String kantorCabang;

  Employee({
    required this.nama,
    required this.jabatan,
    required this.profil,
    required this.usia,
    required this.created_at,
    required this.nip,
    required this.namaBuku,
    required this.kantorCabang,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      nama: json['nama'] ?? '',
      jabatan: json['jabatan'] ?? '',
      profil: json['profil'] ?? '',
      usia: json['usia'].toString(),
      created_at: json['created_at'].toString() ?? '',
      nip: json['nip'].toString(),
      namaBuku: json['nama_buku'] ?? '',
      kantorCabang: json['kantor_cabang'] ?? '',
    );
  }
}

class DetailPage extends StatelessWidget {
  final Employee employee;

  const DetailPage({Key? key, required this.employee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(40),
                    image: DecorationImage(
                      image: employee.profil.isNotEmpty
                          ? (employee.profil.startsWith('http')
                              ? NetworkImage(employee.profil) // URL gambar
                              : AssetImage(employee.profil)
                                  as ImageProvider) // Path lokal
                          : const AssetImage(
                              'assets/images/default.jpg'), // Gambar default
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.nama,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.jabatan,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('NIP: ${employee.nip}'),
                    const SizedBox(height: 4),
                    Text('Usia: ${employee.usia}'),
                    const SizedBox(height: 4),
                    Text('Kantor: ${employee.kantorCabang}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Menampilkan buku yang dipinjam oleh karyawan
            Expanded(
              child: Table(
                border:
                    TableBorder.all(color: Colors.grey.shade300, width: 1.5),
                columnWidths: const {
                  0: FractionColumnWidth(0.11), // Untuk kolom "No"
                  1: FractionColumnWidth(0.89), // Untuk kolom "Nama Buku"
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                        color: Colors.blueAccent.shade100,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12))),
                    children: [
                      tableCell('No', isHeader: true),
                      tableCell('Nama Buku', isHeader: true),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(),
                    children: [
                      tableCell('1'),
                      tableCell(employee.namaBuku), // Nama buku yang dipinjam
                    ],
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
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
