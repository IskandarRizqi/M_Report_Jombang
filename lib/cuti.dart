import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:ehr_report/widget/tablecuti.dart';
import 'package:ehr_report/widget/widgetcuti.dart';

class EmployeeLeavePage extends StatefulWidget {
  const EmployeeLeavePage({required this.prevPage, super.key});
  final String prevPage;

  @override
  _EmployeeLeavePageState createState() => _EmployeeLeavePageState();
}

class _EmployeeLeavePageState extends State<EmployeeLeavePage> {
  late Future<List<LeaveData>> futureLeaveData;
  List<LeaveData> leaveDataList = [];
  List<LeaveData> allLeaveData = [];
  List<LeaveData> filteredLeaveData = [];
  List<LeaveData> paginatedLeaveData = [];
  int currentPage = 1;
  final int itemsPerPage = 10; // Jumlah data per halaman
  int totalPages = 1;
  bool isLoading = true;
  Timer? _debounce;
  String search = "";

  String selectedBranch = 'Semua Cabang'; // Default pilihan cabang
  String selectedMonth = 'Semua Bulan'; // Default pilihan bulan
  List<String> branches = ['Semua Cabang']; // Default cabang

  @override
  void initState() {
    super.initState();
    futureLeaveData = getDataCuti();
  }

  Future<List<LeaveData>> getDataCuti({String? query}) async {
    try {
      setState(() {
        isLoading = true;
      });
      var url = '/cutireport';
      if (query != null && query.isNotEmpty) {
        url += '?search=$query';
      }

      var dat = await ApiHandler().getData(url);

      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);
        debugPrint('API Response cuti Status Code: ${dat.statusCode}');
        debugPrint('API Response cuti Body: ${dat.body}');

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
          final Map<String, dynamic> dataMap = jsonResponse['data'];

          List<LeaveData> leaveDataList =
              dataMap.values.map((item) => LeaveData.fromJson(item)).toList();

          final branchSet = <String>{'Semua Cabang'};
          for (var leaveData in leaveDataList) {
            branchSet.add(leaveData.kantorCabang);
          }

          setState(() {
            branches = branchSet.toList();
            allLeaveData = leaveDataList;
            filteredLeaveData = leaveDataList;
            totalPages = (filteredLeaveData.length / itemsPerPage).ceil();
            updatePaginatedData();
          });

          return leaveDataList;
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception(
            'Failed to fetch leave data. Status code: ${dat.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
      return [];
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        search = value;

        if (value.isEmpty) {
          // Jika input kosong, kembalikan ke semua data yang difilter
          filteredLeaveData = allLeaveData.where((leave) {
            return selectedBranch == 'Semua Cabang' ||
                leave.kantorCabang == selectedBranch;
          }).toList();
        } else {
          // Filter berdasarkan nama dan cabang yang dipilih
          filteredLeaveData = allLeaveData.where((item) {
            bool matchesBranch = selectedBranch == 'Semua Cabang' ||
                item.kantorCabang.trim().toLowerCase() ==
                    selectedBranch.trim().toLowerCase();
            bool matchesSearch =
                item.nama.toLowerCase().contains(value.toLowerCase());
            return matchesBranch && matchesSearch;
          }).toList();
        }

        currentPage = 1;
        totalPages = (filteredLeaveData.length / itemsPerPage).ceil();
        updatePaginatedData();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void applyFilter() {
    setState(() {
      filteredLeaveData = allLeaveData.where((leave) {
        bool matchesBranch = selectedBranch == 'Semua Cabang' ||
            leave.kantorCabang == selectedBranch;
        return matchesBranch;
      }).toList();
      currentPage = 1; // Reset ke halaman pertama setelah filter diubah
      totalPages = (filteredLeaveData.length / itemsPerPage).ceil();
      updatePaginatedData();
    });
    print('Applied Filters: Branch - $selectedBranch, Month - $selectedMonth');
    print('Filtered Data Count: ${filteredLeaveData.length}');
  }

  void updatePaginatedData() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    setState(() {
      paginatedLeaveData = filteredLeaveData.sublist(
          startIndex, endIndex.clamp(0, filteredLeaveData.length));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cuti Pegawai',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00A260),
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      onChanged:
                          _onSearchChanged, // Panggil otomatis saat mengetik
                      decoration: InputDecoration(
                        labelText: "Masukan Nama",
                        labelStyle: const TextStyle(
                          fontSize: 14, // kecilkan font label
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expanded(
          //   child: FutureBuilder<List<LeaveData>>(
          //     future: futureLeaveData,
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return const Center(child: CircularProgressIndicator());
          //       } else if (snapshot.hasError) {
          //         return Center(child: Text('Error: ${snapshot.error}'));
          //       } else {
          //         return paginatedLeaveData.isEmpty
          //             ? const Center(child: Text('No data found.'))
          //             : ListView.builder(
          //                 itemCount: paginatedLeaveData.length,
          //                 itemBuilder: (context, index) {
          //                   final employee = paginatedLeaveData[index];
          //                   return EmployeeCard(employee: employee);
          //                 },
          //               );
          //       }
          //     },
          //   ),
          // ),
          Expanded(
            child: FutureBuilder<List<LeaveData>>(
              future: futureLeaveData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return paginatedLeaveData.isEmpty
                      ? const Center(child: Text('No data found.'))
                      : ListView.builder(
                          itemCount: paginatedLeaveData.length + 1, // ← +1
                          itemBuilder: (context, index) {
                            if (index == paginatedLeaveData.length) {
                              return Row(
                                // ← pagination ikut scroll
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              );
                            }
                            final employee = paginatedLeaveData[index];
                            return EmployeeCard(employee: employee);
                          },
                        );
                }
              },
            ),
          ),
// Row pagination dihapus dari sini
        ],
      ),
    );
  }
}

class LeaveData {
  final String pegawaiId;
  final String nama;
  final String profil;
  final String nip;
  // final String tanggal_pengisian;
  final String jenisCuti;
  // final int kategoriCuti;
  // final String tglMulai;
  // final String tglSelesai;
  // final int jumlahAmbil;
  // final int sisaCuti;
  // final int statusCuti;
  final String kantorCabang;
  final String jabatan;
  final String keterangan;
  // final int total;
  final int usia;

  LeaveData(
      {required this.pegawaiId,
      required this.nama,
      required this.profil,
      required this.nip,
      // required this.tanggal_pengisian,
      required this.jenisCuti,
      // required this.kategoriCuti,
      // required this.tglMulai,
      // required this.tglSelesai,
      // required this.jumlahAmbil,
      // required this.sisaCuti,
      // required this.statusCuti,
      required this.kantorCabang,
      required this.jabatan,
      required this.keterangan,
      // required this.total,
      required this.usia});

  factory LeaveData.fromJson(Map<String, dynamic> json) {
    return LeaveData(
        pegawaiId: json['pegawai_id'] ?? 'unknown',
        nama: json['nama'] ?? 'unknown',
        profil: json['profil'] ?? '',
        nip: json['nip'] ?? '',
        // tanggal_pengisian: json['tanggal_pengisian'],
        jenisCuti: json['jenis_cuti'] ?? '',
        // kategoriCuti: json['kategori_cuti'],
        // tglMulai: json['tgl_mulai'],
        // tglSelesai: json['tgl_selesai'],
        // jumlahAmbil: json['jumlah_ambil'] ?? '',
        // sisaCuti: json['sisa_cuti'] ?? '',
        // statusCuti: json['status_cuti'] ?? '',
        kantorCabang: json['kantor_cabang'] ?? '',
        jabatan: json['jabatan'] ?? '',
        keterangan: json['keterangan'] ?? "",
        // total: json['total'] ?? '',
        usia: json['usia'] ?? 0);
  }
}

class EmployeeCard extends StatelessWidget {
  final LeaveData employee;

  const EmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigasi ke halaman detail cuti
                  Get.to(() => CutiDetailPage(
                      leaveData: employee, pegawaiId: employee.pegawaiId));
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A260),
                        borderRadius: BorderRadius.circular(30),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black),
                          ),
                          Text(
                            employee.jabatan,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF00A260)),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'NIP: ${employee.nip}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Kantor: ${employee.kantorCabang}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CutiDetailPage extends StatefulWidget {
  final LeaveData leaveData;
  final String pegawaiId;

  const CutiDetailPage(
      {required this.leaveData, required this.pegawaiId, super.key});

  @override
  State<CutiDetailPage> createState() => _CutiDetailPageState();
}

class _CutiDetailPageState extends State<CutiDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Cuti',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A260),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profil Gambar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A260),
                    borderRadius: BorderRadius.circular(40),
                    image: DecorationImage(
                      image: widget.leaveData.profil.isNotEmpty
                          ? (widget.leaveData.profil.startsWith('http')
                              ? NetworkImage(
                                  widget.leaveData.profil) // URL gambar
                              : AssetImage(widget.leaveData.profil)
                                  as ImageProvider) // Path lokal
                          : const AssetImage(
                              'assets/images/default.jpg'), // Gambar default
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                    width: 10), // Memberikan jarak antara gambar dan teks
                // Teks Profil
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.leaveData.nama,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow
                            .ellipsis, // Tambahkan ini agar teks yang panjang dipotong
                        maxLines: 1, // Batasi ke 1 baris
                      ),
                      Text(
                        widget.leaveData.jabatan,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF00A260), // ← warna hijau
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      Text(
                        'NIP: ${widget.leaveData.nip}',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Usia: ${widget.leaveData.usia}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Kantor: ${widget.leaveData.kantorCabang}',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Text('Jenis Cuti: ${leaveData.jenisCuti}', style: const TextStyle(fontSize: 16)),
            // Text(
            //   'Tanggal Mulai: ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(leaveData.tglMulai))}',
            //   style: const TextStyle(fontSize: 16),
            // ),
            // Text(
            //   'Tanggal Selesai: ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(leaveData.tglSelesai))}',
            //   style: const TextStyle(fontSize: 16),
            // ),
            // const SizedBox(height: 10),
            // Text('Keterangan: ${leaveData.keterangan}', style: const TextStyle(fontSize: 16)),
            // // Anda bisa menambahkan informasi lebih lanjut di sini
            Widgetcuti(pegawaiId: widget.pegawaiId),
            //   Padding(padding: const EdgeInsets.all(10.0),
            //   child: Container(
            //     padding: const EdgeInsets.all(16.0),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF007BFF),

            //       borderRadius: BorderRadius.circular(8.0),
            //     ),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Column(
            //           children: [
            //         //     Text(
            //         //       '${leaveData.total.toString()}h',
            //         //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //         // ),
            //         const SizedBox(height: 4),
            //           const Text(
            //             'Total Cuti',
            //             style: TextStyle(fontSize: 12, color: Colors.white),
            //           ),
            //         ],
            //       ),
            //       Column(
            //         children: [
            //           // Text(
            //           //   '${leaveData.jumlahAmbil.toString()}h',
            //           //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //           // ),
            //           const SizedBox(height: 4),
            //           const Text(
            //             'Cuti Diambil',
            //             style: TextStyle(fontSize: 12, color: Colors.white),
            //           ),
            //         ],
            //       ),
            //       Column(
            //         children: [
            //           // Text(
            //           //   '${leaveData.sisaCuti.toString()}h',
            //           //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //           // ),
            //           const SizedBox(height: 4),
            //           const Text(
            //             'Sisa Cuti',
            //             style: TextStyle(fontSize: 12, color: Colors.white),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // )
            //   ),
            Tablecuti(pegawaiId: widget.pegawaiId),
          ],
        ),
      ),
    );
  }
}
