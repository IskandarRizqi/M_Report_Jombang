import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';

class CollectionScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String kantorUuid;
  final String kantorNama;

  const CollectionScreen({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.kantorUuid,
    required this.kantorNama,
  }) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Map<String, dynamic>> cardDataList = [];
  List<Map<String, dynamic>> tableDataList = [];
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> paginatedData = [];

  bool isLoading = true;
  String search = "";
  Timer? _debounce;

  late DateTime startDate;
  late DateTime endDate;
  String selectedKantor = 'Semua Kantor';
  String selectedKantorUuid = '';
  List<String> kantorList = ['Semua Kantor'];
  Map<String, String> kantorMap = {'Semua Kantor': ''};

  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate;
    endDate = widget.endDate;
    selectedKantorUuid = widget.kantorUuid;
    selectedKantor = widget.kantorNama;
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);

      String startStr = DateFormat('yyyy-MM-dd').format(startDate);
      String endStr = DateFormat('yyyy-MM-dd').format(endDate);

      String url = '/rekapkolektor?start=$startStr&end=$endStr';
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

          final rawKantorList =
              jsonResponse['kantor_list'] as Map<String, dynamic>? ?? {};
          kantorMap = {'Semua Kantor': ''};
          rawKantorList.forEach((uuid, nama) {
            kantorMap[nama.toString()] = uuid.toString();
          });
          kantorList = kantorMap.keys.toList();

          if (!kantorList.contains(selectedKantor)) {
            selectedKantor = 'Semua Kantor';
            selectedKantorUuid = '';
          }

          _applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG);
    }
  }

  void _applyFilters() {
    filteredData = tableDataList.where((item) {
      if (search.isEmpty) return true;
      return (item['ditagih_oleh']?.toString().toLowerCase() ?? '')
          .contains(search.toLowerCase());
    }).toList();

    totalPages = (filteredData.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    currentPage = 1;
    _updatePagination();
  }

  void _updatePagination() {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    setState(() {
      paginatedData =
          filteredData.sublist(start, end.clamp(0, filteredData.length));
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        search = value;
        _applyFilters();
      });
    });
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: DateTime(2020),
        lastDate: endDate,
        helpText: 'Pilih Tanggal Awal');
    if (picked != null && picked != startDate) {
      setState(() => startDate = picked);
      fetchData();
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: endDate,
        firstDate: startDate,
        lastDate: DateTime(2030),
        helpText: 'Pilih Tanggal Akhir');
    if (picked != null && picked != endDate) {
      setState(() => endDate = picked);
      fetchData();
    }
  }

  String _formatDate(DateTime d) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(d);

  void _navigateToDetail(String filterType, String? visitStatus, int count) {
    if (count == 0) {
      Fluttertoast.showToast(
          msg: 'Tidak ada data untuk ditampilkan',
          backgroundColor: Colors.orange,
          textColor: Colors.white);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailCollectionPage(
                pegawaiId: filterType,
                visitStatus: visitStatus,
                startDate: startDate,
                endDate: endDate,
                kantorUuid: selectedKantorUuid)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FILTER PERIODE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFF00A260).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00A260).withValues(alpha: 0.3))),
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
                    child:
                        _buildDateBox(_formatDate(startDate), _pickStartDate)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('s/d',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey))),
                Expanded(
                    child: _buildDateBox(_formatDate(endDate), _pickEndDate)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. FILTER KANTOR + SEARCH
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButton<String>(
                    value: selectedKantor,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 20, color: Colors.black),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    items: kantorList
                        .map((kantor) => DropdownMenuItem(
                            value: kantor,
                            child: Text(kantor,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedKantor = value;
                          selectedKantorUuid = kantorMap[value] ?? '';
                        });
                        fetchData();
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
                            onPressed: () => _onSearchChanged(''))
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color(0xFF00A260), width: 1.5)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. KONTEN UTAMA
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCards(),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text("Results : ${filteredData.length} data",
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
                              borderRadius: BorderRadius.circular(8)),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF00A260)),
                              headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                              dataTextStyle: const TextStyle(
                                  fontSize: 10, color: Colors.black87),
                              columnSpacing: 14,
                              horizontalMargin: 10,
                              headingRowHeight: 42,
                              dataRowHeight: 50,
                              border: TableBorder(
                                  horizontalInside: BorderSide(
                                      color: Colors.grey.shade200, width: 0.5),
                                  verticalInside: BorderSide(
                                      color: Colors.grey.shade200, width: 0.5)),
                              columns: const [
                                DataColumn(
                                    label: SizedBox(
                                        width: 30,
                                        child: Center(child: Text('No')))),
                                DataColumn(
                                    label: SizedBox(
                                        width: 100, child: Text('Tanggal'))),
                                DataColumn(
                                    label: SizedBox(
                                        width: 120,
                                        child: Text('Ditagih Oleh'))),
                                DataColumn(
                                    label: SizedBox(
                                        width: 100, child: Text('Cabang'))),
                                // DataColumn(
                                //     label: SizedBox(
                                //         width: 120, child: Text('Nasabah'))),
                                DataColumn(
                                    label: SizedBox(
                                        width: 120,
                                        child: Text('Bayar Angsuran'))),
                              ],
                              rows: paginatedData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return DataRow(
                                  color: WidgetStateProperty.all(index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey[50]),
                                  cells: [
                                    DataCell(Center(
                                        child: Text('${index + 1}',
                                            style: const TextStyle(
                                                fontSize: 10)))),
                                    DataCell(Text(item['tanggal'] ?? '-',
                                        style: const TextStyle(fontSize: 9))),
                                    DataCell(Text(item['ditagih_oleh'] ?? '-',
                                        style: const TextStyle(fontSize: 10))),
                                    DataCell(Text(item['kantor_cabang'] ?? '-',
                                        style: const TextStyle(fontSize: 10))),
                                    // DataCell(Text(item['nasabah'] ?? '-',
                                    //     style: const TextStyle(fontSize: 10))),
                                    DataCell(Text(item['bayar_angsuran'] ?? '-',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500))),
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
                                      SizedBox(width: 2),
                                      Text('Back',
                                          style: TextStyle(fontSize: 11))
                                    ])),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF00A260),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(
                                        'Hal $currentPage / $totalPages',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600))),
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
                                      Text('Next',
                                          style: TextStyle(fontSize: 11)),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right, size: 16)
                                    ])),
                              ]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildCards() {
    return Row(
      children: cardDataList.map((card) {
        String title = (card['title'] ?? '').toString();
        int count = card['count'] ?? 0;
        bool isBelum = title.toLowerCase().contains('belum');
        Color textColor =
            isBelum ? const Color(0xFFD32F2F) : const Color(0xFF1976D2);
        Color bgColor = isBelum ? Colors.red.shade50 : Colors.blue.shade50;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                          color: bgColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(count.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 26,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToDetail(
                            'collection', isBelum ? 'belum' : 'sudah', count),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6))),
                        child: const Text('Detail',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DETAIL COLLECTION PAGE
// ═══════════════════════════════════════════════════════
class DetailCollectionPage extends StatefulWidget {
  final String pegawaiId;
  final String? visitStatus;
  final DateTime startDate;
  final DateTime endDate;
  final String kantorUuid;

  const DetailCollectionPage(
      {Key? key,
      required this.pegawaiId,
      this.visitStatus,
      required this.startDate,
      required this.endDate,
      required this.kantorUuid})
      : super(key: key);

  @override
  State<DetailCollectionPage> createState() => _DetailCollectionPageState();
}

class _DetailCollectionPageState extends State<DetailCollectionPage> {
  List<Map<String, dynamic>> allPegawai = [];
  List<Map<String, dynamic>> filteredPegawai = [];
  List<Map<String, dynamic>> paginatedPegawai = [];
  bool isLoading = true;
  String searchQuery = "";
  Timer? _debounce;
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
      String url = '/detailrekapkolektor?start=$startStr&end=$endStr';
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
        title: const Text('Detail Pegawai Collection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00A260),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
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
                                ? 'STATUS: BELUM PENAGIHAN'
                                : 'STATUS: SUDAH PENAGIHAN',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.visitStatus == 'belum'
                                    ? Colors.red.shade800
                                    : Colors.green.shade800)))))
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                            hintText: "Cari NIP atau Nama...",
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey),
                                    onPressed: () => _onSearchChanged(''))
                                : null,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00A260), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true))),
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            "Showing ${filteredPegawai.isEmpty ? 0 : ((currentPage - 1) * itemsPerPage) + 1} to ${filteredPegawai.length < currentPage * itemsPerPage ? filteredPegawai.length : currentPage * itemsPerPage} of ${filteredPegawai.length} entries",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)))),
                Expanded(
                  child: filteredPegawai.isEmpty
                      ? const Center(
                          child: Text("Tidak ada data pegawai",
                              style: TextStyle(color: Colors.grey)))
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300)),
                          child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Table(
                                  columnWidths: const {
                                    0: FixedColumnWidth(40.0),
                                    1: FlexColumnWidth(1.0),
                                    2: FlexColumnWidth(2.0)
                                  },
                                  border: TableBorder(
                                      horizontalInside: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5),
                                      verticalInside: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5)),
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF00A260)),
                                        children: [
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                              child: Text('No',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13))),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                              child: Text('NIP',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13))),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                              child: Text('Nama',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13)))
                                        ]),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                        horizontal: 8),
                                                child: Text(no.toString(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.black87))),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                        horizontal: 8),
                                                child: Text(item['nip'] ?? '-',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.black87))),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                        horizontal: 8),
                                                child: Text(item['nama'] ?? '-',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87)))
                                          ]);
                                    })
                                  ]))),
                ),
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
                                ])),
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
                                        fontWeight: FontWeight.w600))),
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
                                ]))
                          ])),
                SizedBox(height: 40),
              ],
            ),
    );
  }
}
