import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Palette',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ColorPalettePage(),
    );
  }
}

class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

class _ColorPalettePageState extends State<ColorPalettePage> {
  Map<String, dynamic> colors = {};

  @override
  void initState() {
    super.initState();
    loadColors();
  }

  Future<void> loadColors() async {
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/colors.json');
    setState(() {
      colors = json.decode(jsonString);
    });
  }

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Color Palette'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Light'),
              Tab(text: 'Medium'),
              Tab(text: 'Dark'),
              Tab(text: 'Opus'),
            ],
          ),
        ),
        body: TabBarView(
          children: ['light', 'medium', 'dark', 'opus'].map((category) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: colors[category]?.length ?? 0,
              itemBuilder: (context, index) {
                final color = colors[category]?[index];
                if (color == null) return const SizedBox();

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Container(
                    height: 100,
                    color: hexToColor(color['value']),
                    child: ListTile(
                      title: Text(
                        color['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${color['number']} - ${color['value']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
