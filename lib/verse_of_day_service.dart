import 'dart:convert';

import 'package:http/http.dart' as http;

class DailyVerse {
  const DailyVerse(this.reference);

  final String reference;
}

class VerseOfDayService {
  static const _endpoint = 'https://api.midvash.com/v1/votd?language=es';

  static Future<DailyVerse> fetch() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar el versiculo del dia');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map || (data['reference'] ?? '').toString().trim().isEmpty) {
      throw Exception('La respuesta del versiculo no es valida');
    }

    return DailyVerse(data['reference'].toString().trim());
  }
}
