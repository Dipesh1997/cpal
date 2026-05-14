import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SheetsService {
  static const String _spreadsheetId =
      '1RPDF84bu9we3mabRXk0Oot_QMTfHHTQJO5ulHKAP29k';
  static const List<String> _sheetNames = [
    'light',
    'medium',
    'dark',
    'SA',
    'SV',
    'opus',
    'ncs',
    'wood'
  ];

  static Future<Map<String, List<dynamic>>> fetchData() async {
    try {
      // First try to load from cache
      final cachedData = await _loadFromCache();
      if (cachedData != null && cachedData.isNotEmpty) {
        print('✅ Using cached data');
        return cachedData;
      }

      print('🔄 Fetching fresh data from Google Sheets');
      Map<String, List<dynamic>> result = {};

      for (var sheetName in _sheetNames) {
        try {
          print('📥 Downloading sheet: $sheetName');
          final url =
              'https://docs.google.com/spreadsheets/d/$_spreadsheetId/gviz/tq?tqx=out:csv&sheet=$sheetName';
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final csvData = response.body;
            final lines = const LineSplitter().convert(csvData);

            if (lines.isEmpty) {
              print('⚠️ Empty data for sheet: $sheetName');
              continue;
            }

            // Skip header row and process data
            final data = lines
                .skip(1)
                .map((line) {
                  try {
                    // Split by comma but handle quoted values
                    final values = _parseCsvLine(line);
                    if (values.length >= 4) {
                      return {
                        'number': values[0].trim(),
                        'name': values[1].trim(),
                        'value': values[2].trim(),
                        'page': int.tryParse(values[3].trim()) ?? 1,
                      };
                    }
                  } catch (e) {
                    print('⚠️ Error parsing line: $line\nError: $e');
                  }
                  return null;
                })
                .where((item) => item != null)
                .toList();

            if (data.isNotEmpty) {
              result[sheetName] = data;
              print(
                  '✅ Successfully processed ${data.length} colors for $sheetName');
            } else {
              print('⚠️ No valid data found for sheet: $sheetName');
            }
          } else {
            print(
                '⚠️ Failed to fetch sheet $sheetName. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error processing sheet $sheetName: $e');
          continue;
        }
      }

      if (result.isNotEmpty) {
        // Save to cache
        await _saveToCache(result);
        print('✅ Successfully saved ${result.length} sheets to cache');
        return result;
      } else {
        print('⚠️ No data was successfully fetched');
        return {};
      }
    } catch (e) {
      print('❌ Error in fetchData: $e');
      return {};
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        inQuotes = !inQuotes;
      } else if (line[i] == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(line[i]);
      }
    }
    result.add(current.toString());
    return result;
  }

  static Future<void> _saveToCache(Map<String, List<dynamic>> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/colors_cache.json');
      await file.writeAsString(jsonEncode(data));
      print('✅ Cache saved successfully');
    } catch (e) {
      print('⚠️ Error saving cache: $e');
    }
  }

  static Future<Map<String, List<dynamic>>?> _loadFromCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/colors_cache.json');

      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = Map<String, List<dynamic>>.from(jsonDecode(contents));
        if (data.isNotEmpty) {
          print('✅ Cache loaded successfully');
          return data;
        }
      }
    } catch (e) {
      print('⚠️ Error loading cache: $e');
    }
    return null;
  }

  static Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/colors_cache.json');
      if (await file.exists()) {
        await file.delete();
        print('✅ Cache cleared successfully');
      }
    } catch (e) {
      print('⚠️ Error clearing cache: $e');
    }
  }
}
