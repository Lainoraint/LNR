import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ML_Gweh/page/hijaiyah/hijaiyah_firebase.dart';

class HijaiyahInputPage extends StatefulWidget {
  const HijaiyahInputPage({super.key});

  @override
  State<HijaiyahInputPage> createState() => _HijaiyahInputPageState();
}

class _HijaiyahInputPageState extends State<HijaiyahInputPage> {
  // List of Hijaiyah letters
  final Map<String, String> hijaiyahLetters = {
    'alif': 'ا',
    'ba': 'ب',
    'ta': 'ت',
    'tsa': 'ث',
    'jim': 'ج',
    'ha': 'ح',
    'kho': 'خ',
    'dal': 'د',
    'dzal': 'ذ',
    'ra': 'ر',
    'za': 'ز',
    'sin': 'س',
    'syin': 'ش',
    'shod': 'ص',
    'dhah': 'ض',
    'tho': 'ط',
    'dzo': 'ظ',
    'ain': 'ع',
    'ghoin': 'غ',
    'fa': 'ف',
    'qof': 'ق',
    'kaf': 'ك',
    'lam': 'ل',
    'mim': 'م',
    'nun': 'ن',
    'wau': 'و',
    'haa': 'ه',
    'lamalif': 'ﻻ',
    'hamzah': 'ء',
    'ya': 'ي',
  };

  @override
  void initState() {
    super.initState();
    // Ensure application is in portrait mode for the selection page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _navigateToDrawingPage(String letter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenulisHijaiyahFirebasePage(letter: letter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Huruf Hijaiyah',
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
            // Header Section with instructions
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
                      Icons.edit_note,
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
                          'Pilih Huruf Hijaiyah Untuk Berlatih',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sentuh kartu huruf untuk mulai menulis',
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

            // Hijaiyah Letters Grid - with RTL order
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 huruf per baris
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: hijaiyahLetters.length,
                  itemBuilder: (context, index) {
                    final hijaiyahList = hijaiyahLetters.entries.toList();
                    if (index >= hijaiyahList.length) return null;

                    const rowLength = 4; // Kolom per baris
                    final totalRows = (hijaiyahList.length / rowLength).ceil();
                    final lastRowItemCount =
                        hijaiyahList.length % rowLength == 0
                            ? rowLength
                            : hijaiyahList.length % rowLength;

                    // Tentukan baris dan posisi normal
                    final row = index ~/ rowLength;
                    final posInRow = index % rowLength;

                    // Perhitungan indeks RTL yang benar
                    int rtlIndex;
                    if (row == totalRows - 1 && lastRowItemCount < rowLength) {
                      // Baris terakhir dengan item yang tidak lengkap
                      final startOfLastRow =
                          hijaiyahList.length - lastRowItemCount;
                      final offsetInLastRow = lastRowItemCount - 1 - posInRow;

                      // Hanya render posisi yang valid di baris terakhir
                      if (posInRow >= lastRowItemCount) return null;

                      rtlIndex = startOfLastRow + offsetInLastRow;
                    } else {
                      // Baris lengkap
                      final rtlPosInRow = rowLength - 1 - posInRow;
                      rtlIndex = (row * rowLength) + rtlPosInRow;
                    }

                    final key = hijaiyahList[rtlIndex].key;
                    final letter = hijaiyahList[rtlIndex].value;
                    final cardColor = _getColorForLetter(rtlIndex);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
                          onTap: () => _navigateToDrawingPage(key),
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
                            child: Center(
                              child: Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Amiri',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Footer with hint
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
                      'Tip: Tulislah dari kanan ke kiri sesuai dengan aturan penulisan huruf Arab',
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

  // Helper method to get different colors for different Hijaiyah letter groups
  Color _getColorForLetter(int index) {
    if (index < 7) {
      // First group (ا to خ)
      return Colors.green.shade700;
    } else if (index < 14) {
      // Second group (د to ش)
      return Colors.teal.shade700;
    } else if (index < 21) {
      // Third group (ص to ف)
      return Colors.indigo.shade700;
    } else {
      // Fourth group (ق to ي)
      return Colors.brown.shade700;
    }
  }

  @override
  void dispose() {
    // Reset orientation settings when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}
