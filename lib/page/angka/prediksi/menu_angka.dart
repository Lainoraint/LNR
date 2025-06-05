import 'package:ML_Gweh/page/angka/prediksi/ratusan_page.dart';
import 'package:ML_Gweh/page/angka/prediksi/ribuan_page.dart';
import 'package:flutter/material.dart';
import 'package:ML_Gweh/page/angka/prediksi/satuan_page.dart';
import 'package:ML_Gweh/page/angka/prediksi/puluhan_page.dart';

class MenuAngka extends StatelessWidget {
  const MenuAngka({super.key});

  void _navigateToPage(BuildContext context, String type) {
    switch (type) {
      case 'satuan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SatuanPage()),
        );
        break;
      case 'puluhan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PuluhanPage()),
        );
        break;
      case 'ratusan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RatusanPage()),
        );
      case 'ribuan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RibuanPage()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akan segera hadir!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kategori Angka'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.looks_one),
              title: const Text('Angka Satuan'),
              subtitle: const Text('Prediksi angka 0-9'),
              onTap: () => _navigateToPage(context, 'satuan'),
            ),
            ListTile(
              leading: const Icon(Icons.looks_two),
              title: const Text('Angka Puluhan'),
              subtitle: const Text('Prediksi angka 10-90'),
              onTap: () => _navigateToPage(context, 'puluhan'),
            ),
            ListTile(
              leading: const Icon(Icons.looks_3),
              title: const Text('Angka Ratusan'),
              subtitle: const Text('Prediksi angka 100-900'),
              onTap: () => _navigateToPage(context, 'ratusan'),
            ),
            ListTile(
              leading: const Icon(Icons.looks_4),
              title: const Text('Angka Ribuan'),
              subtitle: const Text('Prediksi angka 1000-9000'),
              onTap: () => _navigateToPage(context, 'ribuan'),
            ),
          ],
        ),
      ),
    );
  }
}
