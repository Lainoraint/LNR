import 'package:ML_Gweh/page/angka/firebase/input_angka.dart';
import 'package:ML_Gweh/page/angka/prediksi/menu_angka.dart';
import 'package:ML_Gweh/page/hijaiyah/input_hijaiyah.dart';
import 'package:ML_Gweh/page/hijaiyah/menulis_hijaiyah.dart';
import 'package:flutter/material.dart';
import 'package:ML_Gweh/page/alfabet/input_page.dart';
import 'package:ML_Gweh/page/alfabet/prediksi.dart';
import 'package:ML_Gweh/page/alfabet/menulis_alfabet_page.dart';
import 'package:ML_Gweh/config/drawer_header.dart';
import 'package:ML_Gweh/config/category_header.dart';
import 'package:ML_Gweh/config/expansion_tile.dart';
import 'package:ML_Gweh/config/list_tile.dart';
import 'package:ML_Gweh/page/hijaiyah/dataset_hijaiyah.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: buildDrawerHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    buildCategoryHeader(context, "MENU APLIKASI"),
                    const SizedBox(height: 8),
                    buildExpansionTile(
                      context,
                      leadingIcon:
                          const Icon(Icons.dashboard, color: Colors.teal),
                      title: "Input Dataset",
                      children: [
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.text_increase,
                              color: Colors.teal.shade700),
                          title: 'Alfabet Kapital',
                          destination: const InputPage(),
                        ),
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.brightness_4_outlined,
                              color: Colors.teal.shade700),
                          title: 'Huruf Hijaiyah',
                          destination: const HijaiyahInputPage(),
                        ),
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.looks_one_outlined,
                              color: Colors.teal.shade700),
                          title: 'Angka',
                          destination: const InputAngkaPage(),
                        ),
                      ],
                    ),
                    buildExpansionTile(
                      context,
                      leadingIcon:
                          const Icon(Icons.lightbulb, color: Colors.amber),
                      title: "Prediksi & Pengenalan",
                      children: [
                        buildListTile(
                          context,
                          leadingIcon:
                              Icon(Icons.draw, color: Colors.amber.shade700),
                          title: 'Prediksi Huruf',
                          destination: const Prediksi(),
                        ),
                      ],
                    ),
                    buildExpansionTile(
                      context,
                      leadingIcon: const Icon(Icons.local_fire_department_sharp,
                          color: Colors.deepOrange),
                      title: "Dataset",
                      children: [
                        buildListTile(
                          context,
                          leadingIcon: const Icon(Icons.star_rounded,
                              color: Colors.deepOrange),
                          title: 'Huruf Hijaiyah',
                          destination: const DatasetHijaiyah(),
                        ),
                      ],
                    ),
                    buildExpansionTile(
                      context,
                      leadingIcon:
                          const Icon(Icons.apps, color: Colors.deepPurple),
                      title: "Prediksi",
                      children: [
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.app_shortcut,
                              color: Colors.deepPurple.shade400),
                          title: 'Menulis Alfabet Kapital',
                          destination: const MenulisAlfabetPage(),
                        ),
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.brightness_low_outlined,
                              color: Colors.deepPurple.shade400),
                          title: 'Menulis Huruf Hijaiyah',
                          destination: const MenulisHijaiyah(),
                        ),
                        buildListTile(
                          context,
                          leadingIcon: Icon(Icons.looks_two_outlined,
                              color: Colors.deepPurple.shade400),
                          title: 'Menulis Angka',
                          destination: const MenuAngka(),
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
    );
  }
}
