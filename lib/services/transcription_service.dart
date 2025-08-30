import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class TranscriptionService {
  final String _url = 'https://api.openai.com/v1/audio/transcriptions';
  final String _model = 'whisper-1';
  final String? overrideKey;
  TranscriptionService({this.overrideKey});

  String _key() {
    final raw = (overrideKey ?? Platform.environment['OPENAI_API_KEY'] ?? '');
    return raw.replaceAll('\r','').replaceAll('\n','').trim();
  }

  Future<String> transcribeFile(String path) async {
    final key = _key();
    if (key.isEmpty) throw 'Missing OPENAI_API_KEY';
    final file = File(path);
    if (!await file.exists()) throw 'Audio file not found: $path';

    final req = http.MultipartRequest('POST', Uri.parse(_url))
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = _model
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', path));

    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 120)));
    // ignore: avoid_print
    print('Whisper HTTP ${res.statusCode}, len=${res.body.length}');
    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('Whisper error body: ${res.body}');
      if (res.statusCode == 429 && res.body.contains('insufficient_quota')) throw '__QUOTA__';
      throw 'API ${res.statusCode}';
    }
    final text = res.body.trim();
    if (text.isEmpty) throw 'Empty transcript';
    return text;
  }

  Future<String?> ping() async {
    final key = _key();
    if (key.isEmpty) return Future.error('OPENAI_API_KEY not set');
    final uri = Uri.parse('https://api.openai.com/v1/models/$_model');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $key'}).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        try {
          final m = jsonDecode(res.body) as Map<String, dynamic>;
          final id = m['id']?.toString() ?? '';
          return id.isNotEmpty ? 'ok: $id' : 'ok';
        } catch (_) {
          return 'ok';
        }
      }
      return Future.error('Ping ${res.statusCode}: ${res.body}');
    } on TimeoutException {
      return Future.error('Ping timeout');
    } catch (e) {
      return Future.error('Ping error: $e');
    }
  }
}
