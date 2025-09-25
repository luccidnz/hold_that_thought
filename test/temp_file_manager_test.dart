import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/utils/temp_file_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late Directory tempDir;
  
  setUp(() async {
    // Create a test temporary directory
    final systemTemp = Directory.systemTemp;
    tempDir = Directory('${systemTemp.path}/test_temp_${DateTime.now().millisecondsSinceEpoch}');
    await tempDir.create(recursive: true);
    
    // Set it as the test directory
    TempFileManager.setTestTempDir(tempDir);
  });
  
  tearDown(() async {
    // Reset the test directory
    TempFileManager.resetTestTempDir();
    
    // Clean up
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TempFileManager', () {
    test('cleanupTempFiles deletes all temporary files', () async {
      // Create some test files
      final file1 = File('${tempDir.path}/test1.txt');
      final file2 = File('${tempDir.path}/test2.txt');
      
      await file1.writeAsString('test1');
      await file2.writeAsString('test2');
      
      // Verify files exist
      expect(await file1.exists(), true);
      expect(await file2.exists(), true);
      
      // Clean up
      await TempFileManager.cleanupTempFiles();
      
      // Verify files are gone
      expect(await file1.exists(), false);
      expect(await file2.exists(), false);
    });

    test('createTempFile creates a file with correct extension', () async {
      final tempFile = await TempFileManager.createTempFile('m4a');
      expect(tempFile.path.endsWith('.m4a'), true);
      
      // Create the file to ensure it works
      await tempFile.writeAsString('test content');
      expect(await tempFile.exists(), true);
      
      // Clean up
      await tempFile.delete();
    });

    test('deleteTempFile removes the specified file', () async {
      final tempFile = await TempFileManager.createTempFile('test');
      
      // Create the file
      await tempFile.writeAsString('test content');
      expect(await tempFile.exists(), true);
      
      // Delete it
      await TempFileManager.deleteTempFile(tempFile);
      expect(await tempFile.exists(), false);
    });

    test('getTempFileCount returns correct count', () async {
      // Clean up first
      await TempFileManager.cleanupTempFiles();
      
      // Initial count should be 0
      final initialCount = await TempFileManager.getTempFileCount();
      expect(initialCount, 0);
      
      // Create a few temp files
      final file1 = await TempFileManager.createTempFile('test1');
      final file2 = await TempFileManager.createTempFile('test2');
      final file3 = await TempFileManager.createTempFile('test3');
      
      await file1.writeAsString('test1');
      await file2.writeAsString('test2');
      await file3.writeAsString('test3');
      
      // New count should be 3
      final newCount = await TempFileManager.getTempFileCount();
      expect(newCount, 3);
    });
  });
}
