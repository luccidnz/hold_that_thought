import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EmbeddingService {
  final String _url = 'https://api.openai.com/v1/embeddings';
  final String _model = 'text-embedding-3-small';
  final String? overrideKey;
  EmbeddingService({this.overrideKey});

  String _key() {
    final raw = (overrideKey ?? Platform.environment['OPENAI_API_KEY'] ?? '');
    return raw.replaceAll('\r','').replaceAll('\n','').trim();
    }

  Future<List<double>> embed(String text) async {
    final key = _key();
    if (key.isEmpty) throw 'Missing OPENAI_API_KEY';
    final res = await http.post(
      Uri.parse(_url),
      headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _model, 'input': text}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('Embedding error ${res.statusCode}: ${res.body}');
      throw 'API ${res.statusCode}';
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final arr = (map['data'] as List).first['embedding'] as List;
    return arr.map((e) => (e as num).toDouble()).toList();
  }
}
