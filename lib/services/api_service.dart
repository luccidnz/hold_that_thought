import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Service for API interactions, including LLM calls
class ApiService {
  final FlutterSecureStorage _secureStorage;
  static const String _openAiKeyKey = 'openai_api_key';
  
  ApiService(this._secureStorage);
  
  /// Set the OpenAI API key
  Future<void> setOpenAiKey(String key) async {
    await _secureStorage.write(key: _openAiKeyKey, value: key);
  }
  
  /// Get the OpenAI API key
  Future<String?> getOpenAiKey() async {
    return await _secureStorage.read(key: _openAiKeyKey);
  }
  
  /// Delete the OpenAI API key
  Future<void> deleteOpenAiKey() async {
    await _secureStorage.delete(key: _openAiKeyKey);
  }
  
  /// Call the LLM with a prompt
  Future<String> callLlm(String prompt) async {
    try {
      final apiKey = await getOpenAiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        // Use environment variable as fallback
        final envKey = const String.fromEnvironment('OPENAI_API_KEY');
        if (envKey.isEmpty) {
          return _simulateLlmResponse(prompt);
        }
      }
      
      // Prepare the request
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that provides clear, concise responses.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'temperature': 0.7,
        'max_tokens': 800
      };
      
      // Send the request to OpenAI
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        print('Error calling LLM API: ${response.statusCode} ${response.body}');
        return _simulateLlmResponse(prompt);
      }
    } catch (e) {
      print('Exception when calling LLM: $e');
      return _simulateLlmResponse(prompt);
    }
  }
  
  /// Generate embeddings for a text
  Future<List<double>> generateEmbeddings(String text) async {
    try {
      final apiKey = await getOpenAiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        // Use environment variable as fallback
        final envKey = const String.fromEnvironment('OPENAI_API_KEY');
        if (envKey.isEmpty) {
          return _simulateEmbeddings(text);
        }
      }
      
      // Prepare the request
      final requestBody = {
        'model': 'text-embedding-ada-002',
        'input': text
      };
      
      // Send the request to OpenAI
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<double>.from(jsonResponse['data'][0]['embedding']);
      } else {
        print('Error generating embeddings: ${response.statusCode} ${response.body}');
        return _simulateEmbeddings(text);
      }
    } catch (e) {
      print('Exception when generating embeddings: $e');
      return _simulateEmbeddings(text);
    }
  }
  
  /// Simulate an LLM response for testing/demo purposes
  String _simulateLlmResponse(String prompt) {
    if (prompt.contains('summarize') || prompt.contains('Summarize')) {
      return '''
Key bullet points:
- This is a simulated summary of the content
- It contains multiple bullet points
- Each point captures a key idea from the text

Action items:
- Follow up on the main topic
- Schedule a time to review the ideas

Tags: simulation, demo, placeholder, test, mock

Hook: A simulated response for demonstration purposes
''';
    } else if (prompt.contains('digest') || prompt.contains('Digest')) {
      return '''
Summary: This is a simulated daily digest for demonstration purposes. It summarizes the key activities and thoughts from the specified day in a concise format.

Highlights:
- First major highlight from the day
- Second important moment or insight
- Third notable event or thought

Themes:
- Primary theme connecting the day's thoughts
- Secondary pattern observed across recordings
- Underlying mood or focus throughout the day
''';
    } else {
      return 'This is a simulated response from the LLM API for testing purposes.';
    }
  }
  
  /// Generate simulated embeddings for testing/demo purposes
  List<double> _simulateEmbeddings(String text) {
    // Create a deterministic but seemingly random vector based on the text
    final embeddings = List<double>.filled(1536, 0.0);
    
    // Use a simple hash of the text to seed the "random" values
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = (hash * 31 + text.codeUnitAt(i)) % 1000000;
    }
    
    // Fill the embedding vector with values derived from the hash
    for (int i = 0; i < embeddings.length; i++) {
      // Generate a value between -1.0 and 1.0 based on the hash and position
      embeddings[i] = ((hash + i) % 1000) / 500.0 - 1.0;
      
      // Scale to a more typical embedding magnitude
      embeddings[i] /= 50.0;
    }
    
    // Normalize the vector to unit length
    double sumSquares = 0.0;
    for (final value in embeddings) {
      sumSquares += value * value;
    }
    
    final magnitude = sumSquares > 0 ? sqrt(sumSquares) : 1.0;
    
    for (int i = 0; i < embeddings.length; i++) {
      embeddings[i] /= magnitude;
    }
    
    return embeddings;
  }
}

/// Provider for the ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiService(secureStorage);
});

/// Simple square root function to avoid adding another import
double sqrt(double x) {
  if (x <= 0) return 0;
  
  double guess = x / 2.0;
  
  // Simple Newton's method implementation
  for (int i = 0; i < 10; i++) {
    guess = 0.5 * (guess + x / guess);
  }
  
  return guess;
}
