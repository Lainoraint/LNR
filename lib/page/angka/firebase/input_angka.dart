import 'package:ML_Gweh/page/angka/firebase/puluhan_page.dart';
import 'package:ML_Gweh/page/angka/firebase/ratusan_page.dart';
import 'package:ML_Gweh/page/angka/firebase/ribuan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ML_Gweh/page/angka/firebase/satuan_page.dart';

class InputAngkaPage extends StatefulWidget {
  const InputAngkaPage({super.key});

  @override
  State<InputAngkaPage> createState() => _InputAngkaPageState();
}

class _InputAngkaPageState extends State<InputAngkaPage> {
  final List<String> kategori = ['Satuan', 'Puluhan', 'Ratusan', 'Ribuan'];

  @override
  void initState() {
    super.initState();
    // Memastikan aplikasi dalam mode portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Kategori Angka',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header Section dengan instruksi
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.format_list_numbered,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Kategori Angka',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sentuh kategori untuk memilih angka',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Kategori Angka
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: kategori.length,
                itemBuilder: (context, index) {
                  String category = kategori[index];
                  Color cardColor = _getColorForCategory(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 101,
                    child: Card(
                      elevation: 8,
                      shadowColor: cardColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: cardColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navigasi ke halaman subkategori
                          _showNumbersBottomSheet(context, category, cardColor);
                        },
                        borderRadius: BorderRadius.circular(20),
                        splashColor: cardColor.withOpacity(0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                cardColor.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Icon(
                                  Icons.draw_outlined,
                                  color: cardColor.withOpacity(0.2),
                                  size: 24,
                                ),
                              ),
                              // Category content
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: cardColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getCategoryIcon(index),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: cardColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: cardColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getCategoryDescription(index),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: cardColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer dengan tips
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Tulislah setiap angka dengan perlahan dan ikuti panduan yang ada',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
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

  void _showNumbersBottomSheet(
      BuildContext context, String category, Color color) {
    List<String> numbers = _getNumbersForCategory(category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.05),
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                'Pilih Angka $category',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Sentuh angka untuk mulai menulis',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Grid Angka
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    String number = numbers[index];
                    return Card(
                      elevation: 5,
                      shadowColor: color.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: color.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          switch (category) {
                            case 'Satuan':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SatuanPage(number: number)),
                              );
                              break;
                            case 'Puluhan':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PuluhanPage(number: number)),
                              );
                              break;
                            case 'Ratusan':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        RatusanPage(number: number)),
                              );
                              break;
                            case 'Ribuan':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        RibuanPage(number: number)),
                              );
                              break;
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        splashColor: color.withOpacity(0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                color.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              number,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi helper untuk mendapatkan warna berdasarkan kategori
  Color _getColorForCategory(int index) {
    switch (index) {
      case 0:
        return Colors.green.shade700; // Satuan
      case 1:
        return Colors.blue.shade700; // Puluhan
      case 2:
        return Colors.purple.shade700; // Ratusan
      case 3:
        return Colors.orange.shade700; // Ribuan
      default:
        return Colors.teal.shade700;
    }
  }

  // Fungsi helper untuk mendapatkan ikon kategori
  String _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return '0-9';
      case 1:
        return '10';
      case 2:
        return '100';
      case 3:
        return '1000';
      default:
        return '#';
    }
  }

  // Fungsi untuk mendapatkan deskripsi kategori
  String _getCategoryDescription(int index) {
    switch (index) {
      case 0:
        return 'Angka 0 sampai 9';
      case 1:
        return 'Angka 10, 20, 30, ...';
      case 2:
        return 'Angka 100, 200, 300, ...';
      case 3:
        return 'Angka 1000, 2000, 3000, ...';
      default:
        return '';
    }
  }

  // Fungsi untuk mendapatkan daftar angka berdasarkan kategori
  List<String> _getNumbersForCategory(String category) {
    switch (category) {
      case 'Satuan':
        return List.generate(10, (index) => index.toString());
      case 'Puluhan':
        return ['10', '20', '30', '40', '50', '60', '70', '80', '90'];
      case 'Ratusan':
        return ['100', '200', '300', '400', '500', '600', '700', '800', '900'];
      case 'Ribuan':
        return [
          '1000',
          '2000',
          '3000',
          '4000',
          '5000',
          '6000',
          '7000',
          '8000',
          '9000'
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    // Reset pengaturan orientasi ketika meninggalkan halaman
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}
