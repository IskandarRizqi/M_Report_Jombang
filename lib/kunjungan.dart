import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';

import 'widget/collection.dart';

class KunjunganScreen extends StatefulWidget {
  const KunjunganScreen({required this.prevPage, Key? key}) : super(key: key);
  final String prevPage;

  @override
  _KunjunganScreenState createState() => _KunjunganScreenState();
}

class _KunjunganScreenState extends State<KunjunganScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> cardDataList = [];
  List<Map<String, dynamic>> tableDataList = [];
  List<Map<String, dynamic>> filteredTableData = [];
  List<Map<String, dynamic>> paginatedTableData = [];

  bool isLoading = true;
  String search = "";
  Timer? _debounce;

  // ✅ FILTER TANGGAL
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  // ✅ FILTER KANTOR
  String selectedKantor = 'Semua Kantor';
  String selectedKantorUuid = ''; // ← Tambahkan ini untuk menyimpan UUID
  List<String> kantorList = ['Semua Kantor'];
  Map<String, String> kantorMap = {
    'Semua Kantor': ''
  }; // ← Mapping Nama -> UUID

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchKunjunganData();
  }

  // ✅ Ubah variabel Filter Kantor

  // ... (Pagination dll tetap sama) ...

  Future<void> fetchKunjunganData() async {
    try {
      setState(() => isLoading = true);

      String startStr = DateFormat('yyyy-MM-dd').format(startDate);
      String endStr = DateFormat('yyyy-MM-dd').format(endDate);

      // ✅ KIRIM PARAMETER TANGGAL & KANTOR (UUID)
      String url = '/kunjunganreport?start=$startStr&end=$endStr';
      if (selectedKantorUuid.isNotEmpty) {
        url += '&cabang_id=$selectedKantorUuid';
      }

      var response = await ApiHandler().getData(url);

      if (response.statusCode == 200 && response.body != null) {
        final jsonResponse = jsonDecode(response.body);

        setState(() {
          cardDataList =
              List<Map<String, dynamic>>.from(jsonResponse['cards'] ?? []);
          tableDataList =
              List<Map<String, dynamic>>.from(jsonResponse['data'] ?? []);

          // ✅ Parse daftar kantor dari API (agar selalu muncul semua kantor yang terdaftar)
          final rawKantorList =
              jsonResponse['kantor_list'] as Map<String, dynamic>? ?? {};
          kantorMap = {'Semua Kantor': ''}; // Reset

          rawKantorList.forEach((uuid, nama) {
            kantorMap[nama.toString()] = uuid.toString();
          });

          kantorList = kantorMap.keys.toList();

          // Reset dropdown jika kantor yang dipilih hilang (misal dihapus admin)
          if (!kantorList.contains(selectedKantor)) {
            selectedKantor = 'Semua Kantor';
            selectedKantorUuid = '';
          }

          _applyClientFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch data.');
      }
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  // ✅ Filter Client HANYA UNTUK SEARCH (Kantor sudah di-handle Server)
  void _applyClientFilters() {
    filteredTableData = tableDataList.where((item) {
      bool matchesSearch = true;
      if (search.isNotEmpty) {
        matchesSearch = (item['nama_pegawai']?.toString().toLowerCase() ?? '')
            .contains(search.toLowerCase());
      }
      return matchesSearch; // Tidak ada filter kantor lagi di sini
    }).toList();

    totalPages = (filteredTableData.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    currentPage = 1;
    updatePaginatedData();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        search = value;
        _applyClientFilters();
      });
    });
  }

  void updatePaginatedData() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    setState(() {
      paginatedTableData = filteredTableData.sublist(
          startIndex, endIndex.clamp(0, filteredTableData.length));
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

  // ✅ PICKER TANGGAL AWAL
  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: endDate,
      helpText: 'Pilih Tanggal Awal',
    );
    if (picked != null && picked != startDate) {
      setState(() => startDate = picked);
      fetchKunjunganData();
    }
  }

  // ✅ PICKER TANGGAL AKHIR
  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Akhir',
    );
    if (picked != null && picked != endDate) {
      setState(() => endDate = picked);
      fetchKunjunganData();
    }
  }

  // ✅ FORMAT TANGGAL
  String _formatDate(DateTime d) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kunjungan",
            style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF00A260),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(255, 226, 217, 217),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Marketing"),
            Tab(text: "Collection"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDataPegawaiTab(),

          // ← GANTI DENGAN INI
          CollectionScreen(
            key: ValueKey('${selectedKantorUuid}_${startDate}_${endDate}'),
            startDate: startDate,
            endDate: endDate,
            kantorUuid: selectedKantorUuid,
            kantorNama: selectedKantor,
          ),
        ],
      ),
    );
  }

  // ✅ TAB Marketing - fix scroll + tabel di bawah cards
  Widget _buildDataPegawaiTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════
          // 1. FILTER TANGGAL RANGE
          // ═══════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A260).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00A260).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range,
                    color: Color(0xFF00A260), size: 20),
                const SizedBox(width: 8),
                const Text('Periode:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A260))),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(startDate),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('s/d',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(endDate),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ═══════════════════════════════════════
          // 2. FILTER KANTOR + SEARCH
          // ═══════════════════════════════════════
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: selectedKantor,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 20, color: Colors.black), // Icon jadi hitam
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Tebal
                        color: Colors.black // Hitam
                        ),
                    items: kantorList.map((kantor) {
                      return DropdownMenuItem(
                        value: kantor,
                        child: Text(
                          kantor,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold, // ← Font tebal
                            color: Colors.black, // ← Warna hitam
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedKantor = value;
                          selectedKantorUuid = kantorMap[value] ?? '';
                        });
                        fetchKunjunganData();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Cari Nama...",
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    suffixIcon: search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 16, color: Colors.grey),
                            onPressed: () => _onSearchChanged(''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                          color: Color(0xFF00A260), width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ═══════════════════════════════════════
          // 3. SEMUA KONTEN DI BAWAH BISA SCROLL
          // ═══════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SUMMARY CARDS
                  _buildSummaryCards(),
                  const SizedBox(height: 14),

                  // INFO JUMLAH DATA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text("Hasil : ${filteredTableData.length} data",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),

                  // TABEL DATA
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFF00A260)),
                        headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                        dataTextStyle: const TextStyle(
                            fontSize: 10, color: Colors.black87),
                        columnSpacing: 14,
                        horizontalMargin: 10,
                        headingRowHeight: 42,
                        dataRowHeight: 42,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade200, width: 0.5),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade200, width: 0.5),
                        ),
                        columns: const [
                          DataColumn(
                              label: SizedBox(
                                  width: 36,
                                  child: Center(
                                      child: Text('No',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11))))),
                          DataColumn(
                              label: SizedBox(
                                  width: 120,
                                  child: Text('Tanggal',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 140,
                                  child: Text('Pegawai',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 120,
                                  child: Text('Status Pegawai',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 120,
                                  child: Text('Nasabah',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 110,
                                  child: Text('Keperluan',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 130,
                                  child: Text('Nominal',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                          DataColumn(
                              label: SizedBox(
                                  width: 150, // ← Lebar kolom keterangan
                                  child: Text('Keterangan',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)))),
                        ],
                        rows: paginatedTableData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return DataRow(
                            color: WidgetStateProperty.all(index % 2 == 0
                                ? Colors.white
                                : Colors.grey[50]),
                            cells: [
                              DataCell(Center(
                                  child: Text('${index + 1}',
                                      style: const TextStyle(fontSize: 10)))),
                              DataCell(Text(item['tanggal'] ?? '-',
                                  style: const TextStyle(fontSize: 9))),
                              DataCell(Text(item['nama_pegawai'] ?? '-',
                                  style: const TextStyle(fontSize: 10))),
                              DataCell(Text(item['status_pegawai'] ?? '-',
                                  style: const TextStyle(fontSize: 10))),
                              DataCell(Text(item['nasabah'] ?? '-',
                                  style: const TextStyle(fontSize: 10))),
                              DataCell(Text(item['keperluan'] ?? '-',
                                  style: const TextStyle(fontSize: 10))),
                              DataCell(Text(item['nominal'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(
                                  item['keterangan'] ?? '-', // ← TAMBAHKAN INI
                                  style: const TextStyle(fontSize: 10))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // PAGINATION
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: currentPage > 1 ? goToPreviousPage : null,
                          child: const Row(
                            children: [
                              Icon(Icons.chevron_left, size: 16),
                              SizedBox(width: 2),
                              Text('Back', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A260),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Hal $currentPage / $totalPages',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed:
                              currentPage < totalPages ? goToNextPage : null,
                          child: const Row(
                            children: [
                              Text('Next', style: TextStyle(fontSize: 11)),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ SINGLE CARD - TANPA ICON agar teks tidak terpotong
  Widget _buildSingleCard(Map<String, dynamic> card) {
    String title = (card['title'] ?? '').toString();
    int count = card['count'] ?? 0;

    Color textColor = const Color(0xFF1976D2);
    Color bgColor = Colors.blue.shade50;

    if (title.toLowerCase().contains('funding')) {
      textColor = const Color(0xFF2E7D32);
      bgColor = Colors.green.shade50;
    } else if (title.toLowerCase().contains('collection')) {
      textColor = const Color(0xFFE65100);
      bgColor = Colors.orange.shade50;
    }

    if (title.toLowerCase().contains('belum')) {
      textColor = const Color(0xFFD32F2F);
      bgColor = Colors.red.shade50;
    }

    String filterType = '';
    if (title.toLowerCase().contains('ao') &&
        !title.toLowerCase().contains('funding')) {
      filterType = 'ao';
    } else if (title.toLowerCase().contains('funding')) {
      filterType = 'funding';
    } else if (title.toLowerCase().contains('collection')) {
      filterType = 'collection';
    }

    String? visitStatus;
    if (title.toLowerCase().contains('belum')) {
      visitStatus = 'belum';
    } else if (title.toLowerCase().contains('kunjungan') &&
        !title.toLowerCase().contains('belum')) {
      visitStatus = 'sudah';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ TITLE TANPA ICON
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),

            // ANGKA BESAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),

            // TOMBOL DETAIL
            SizedBox(
              height: 26,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToDetail(filterType, visitStatus, count);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    List<Widget> rows = [];

    for (int i = 0; i < cardDataList.length; i += 3) {
      List<Widget> rowCards = [];
      for (int j = i; j < i + 3 && j < cardDataList.length; j++) {
        final card = cardDataList[j];
        rowCards.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildSingleCard(card),
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: rowCards),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  void _navigateToDetail(String filterType, String? visitStatus, int count) {
    if (count == 0) {
      Fluttertoast.showToast(
        msg: 'Tidak ada data untuk ditampilkan',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailKunjunganPage(
          pegawaiId: filterType,
          visitStatus: visitStatus,
          startDate: startDate, // ← Kirim tanggal
          endDate: endDate, // ← Kirim tanggal
          kantorUuid: selectedKantorUuid, // ← Kirim kantor
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DETAIL KUNJUNGAN PAGE (DAFTAR PEGAWAI)
// ═══════════════════════════════════════════════════════
class DetailKunjunganPage extends StatefulWidget {
  final String pegawaiId;
  final String? visitStatus;
  final DateTime startDate;
  final DateTime endDate;
  final String kantorUuid;

  const DetailKunjunganPage({
    Key? key,
    required this.pegawaiId,
    this.visitStatus,
    required this.startDate,
    required this.endDate,
    required this.kantorUuid,
  }) : super(key: key);

  @override
  State<DetailKunjunganPage> createState() => _DetailKunjunganPageState();
}

class _DetailKunjunganPageState extends State<DetailKunjunganPage> {
  List<Map<String, dynamic>> allPegawai = [];
  List<Map<String, dynamic>> filteredPegawai = [];
  List<Map<String, dynamic>> paginatedPegawai = [];

  bool isLoading = true;
  String searchQuery = "";
  Timer? _debounce;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    fetchDetailPegawai();
  }

  Future<void> fetchDetailPegawai() async {
    try {
      setState(() => isLoading = true);

      String startStr = DateFormat('yyyy-MM-dd').format(widget.startDate);
      String endStr = DateFormat('yyyy-MM-dd').format(widget.endDate);

      // Susun URL API
      String url =
          '/detailkunjunganreport?type=${widget.pegawaiId}&start=$startStr&end=$endStr';
      if (widget.visitStatus != null) url += '&status=${widget.visitStatus}';
      if (widget.kantorUuid.isNotEmpty)
        url += '&cabang_id=${widget.kantorUuid}';

      var response = await ApiHandler().getData(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          allPegawai =
              List<Map<String, dynamic>>.from(jsonResponse['data'] ?? []);
          _applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _applyFilters() {
    filteredPegawai = allPegawai.where((item) {
      if (searchQuery.isEmpty) return true;
      return (item['nama']?.toString().toLowerCase() ?? '')
              .contains(searchQuery.toLowerCase()) ||
          (item['nip']?.toString().toLowerCase() ?? '')
              .contains(searchQuery.toLowerCase());
    }).toList();

    totalPages = (filteredPegawai.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    currentPage = 1;
    _updatePagination();
  }

  void _updatePagination() {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    setState(() {
      paginatedPegawai =
          filteredPegawai.sublist(start, end.clamp(0, filteredPegawai.length));
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value;
        _applyFilters();
      });
    });
  }

  String _getTitle() {
    String base = 'Daftar Pegawai ';
    if (widget.pegawaiId == 'ao')
      base += 'AO';
    else if (widget.pegawaiId == 'funding')
      base += 'Funding';
    else
      base += 'Collection';
    return base;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_getTitle(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00A260),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.visitStatus != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Container(
                  color: widget.visitStatus == 'belum'
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Center(
                    child: Text(
                      widget.visitStatus == 'belum'
                          ? 'STATUS: BELUM KUNJUNGAN'
                          : 'STATUS: SUDAH KUNJUNGAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.visitStatus == 'belum'
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Cari NIP atau Nama...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _onSearchChanged(''))
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF00A260), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),

                // Info Jumlah Data
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Showing ${filteredPegawai.isEmpty ? 0 : ((currentPage - 1) * itemsPerPage) + 1} to ${filteredPegawai.length < currentPage * itemsPerPage ? filteredPegawai.length : currentPage * itemsPerPage} of ${filteredPegawai.length} entries",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),

                // ✅ TAMBAHKAN EXPANDED DAN SINGLECHILDSCROLLVIEW UNTUK SCROLL KANAN KIRI
                // ✅ TABEL PAS LAYAR HP (LANGSUNG 1 BLOK)
                Expanded(
                  child: filteredPegawai.isEmpty
                      ? const Center(
                          child: Text("Tidak ada Marketing",
                              style: TextStyle(color: Colors.grey)))
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(40.0),
                                1: FlexColumnWidth(1.0),
                                2: FlexColumnWidth(2.0),
                              },
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                    color: Colors.grey.shade200, width: 0.5),
                                verticalInside: BorderSide(
                                    color: Colors.grey.shade200, width: 0.5),
                              ),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              children: [
                                // HEADER
                                TableRow(
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF00A260)),
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 8),
                                        child: Text('No',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13))),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 8),
                                        child: Text('NIP',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13))),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 8),
                                        child: Text('Nama',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13))),
                                  ],
                                ),
                                // ISI DATA
                                ...List.generate(paginatedPegawai.length,
                                    (index) {
                                  final item = paginatedPegawai[index];
                                  final no =
                                      ((currentPage - 1) * itemsPerPage) +
                                          index +
                                          1;
                                  return TableRow(
                                    decoration: BoxDecoration(
                                        color: index % 2 == 0
                                            ? Colors.white
                                            : Colors.grey.shade50),
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 8),
                                          child: Text(no.toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87))),
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 8),
                                          child: Text(item['nip'] ?? '-',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87))),
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 8),
                                          child: Text(item['nama'] ?? '-',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87))),
                                    ],
                                  );
                                })
                              ],
                            ),
                          ),
                        ),
                ),

                // Pagination
                if (filteredPegawai.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: currentPage > 1
                              ? () {
                                  setState(() {
                                    currentPage--;
                                    _updatePagination();
                                  });
                                }
                              : null,
                          child: const Row(children: [
                            Icon(Icons.chevron_left, size: 16),
                            SizedBox(width: 4),
                            Text('Back', style: TextStyle(fontSize: 12))
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFF00A260),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              'Showing page $currentPage of $totalPages',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: currentPage < totalPages
                              ? () {
                                  setState(() {
                                    currentPage++;
                                    _updatePagination();
                                  });
                                }
                              : null,
                          child: const Row(children: [
                            Text('Next', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16)
                          ]),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 40),
              ],
            ),
    );
  }
}

Widget _buildKolChip(String kol) {
  Color bg = Colors.grey.shade200;
  Color txt = Colors.grey.shade800;
  switch (kol.toLowerCase()) {
    case 'lancar':
      bg = Colors.green.shade100;
      txt = Colors.green.shade800;
      break;
    case 'dalam perhatian khusus':
    case 'dpk':
      bg = Colors.yellow.shade100;
      txt = Colors.yellow.shade800;
      break;
    case 'kurang lancar':
    case 'kl':
      bg = Colors.orange.shade100;
      txt = Colors.orange.shade800;
      break;
    case 'diragukan':
      bg = Colors.red.shade100;
      txt = Colors.red.shade800;
      break;
    case 'macet':
      bg = Colors.red.shade300;
      txt = Colors.white;
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text(kol,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: txt)),
  );
}

// ═══════════════════════════════════════════════════════
// MODEL NASABAH
// ═══════════════════════════════════════════════════════
class Nasabah {
  final String nama;
  final String kolektibilitas;
  final int pokok;
  final int bunga;
  final int denda;
  final int totalTagihan;

  Nasabah({
    required this.nama,
    required this.kolektibilitas,
    required this.pokok,
    required this.bunga,
    required this.denda,
    required this.totalTagihan,
  });

  factory Nasabah.fromJson(Map<String, dynamic> json) {
    return Nasabah(
      nama: json['nama'] ?? '',
      kolektibilitas: json['kolektibilitas'] ?? '',
      pokok: json['pokok'] is int
          ? json['pokok']
          : int.tryParse(json['pokok'].toString()) ?? 0,
      bunga: json['bunga'] is int
          ? json['bunga']
          : int.tryParse(json['bunga'].toString()) ?? 0,
      denda: json['denda'] is int
          ? json['denda']
          : int.tryParse(json['denda'].toString()) ?? 0,
      totalTagihan: json['total_tagihan'] is int
          ? json['total_tagihan']
          : int.tryParse(json['total_tagihan'].toString()) ?? 0,
    );
  }

  String formatRupiah(int number) {
    return NumberFormat("#,###", "id_ID").format(number);
  }
}
