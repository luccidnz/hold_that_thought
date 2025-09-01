import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/temp_file_cleanup_service.dart';

/// Provider for the temporary file cleanup service
final tempFileCleanupServiceProvider = Provider<TemporaryFileCleanupService>((ref) {
  final service = TemporaryFileCleanupService();
  
  // Start the service
  service.start();
  
  // Dispose when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
