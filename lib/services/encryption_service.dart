import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class EncryptionService {
  static const String _keyStorageKey = 'aes_encryption_key';
  static const String _ivStorageKey = 'aes_encryption_iv';
  static const String _backupKeyPref = 'aes_backup_key';
  static const String _backupIvPref = 'aes_backup_iv';

  final _secureStorage = const FlutterSecureStorage();

  late encrypt.Key _encryptionKey;
  late encrypt.IV _iv;
  bool _initialized = false;

  /// Initialize encryption service and generate/load keys
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to load existing key from Keystore
      String? existingKey = await _secureStorage.read(key: _keyStorageKey);
      String? existingIv = await _secureStorage.read(key: _ivStorageKey);

      if (existingKey != null && existingIv != null) {
        // Load existing key
        _encryptionKey = encrypt.Key.fromBase64(existingKey);
        _iv = encrypt.IV.fromBase64(existingIv);
      } else {
        // Keystore might be empty (app update scenario)
        // Try to recover from backup in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final backupKey = prefs.getString(_backupKeyPref);
        final backupIv = prefs.getString(_backupIvPref);

        if (backupKey != null && backupIv != null) {
          // Restore from backup
          _encryptionKey = encrypt.Key.fromBase64(backupKey);
          _iv = encrypt.IV.fromBase64(backupIv);

          // Re-store in Keystore
          await _secureStorage.write(
            key: _keyStorageKey,
            value: _encryptionKey.base64,
            aOptions: _getAndroidOptions(),
          );
          await _secureStorage.write(
            key: _ivStorageKey,
            value: _iv.base64,
            aOptions: _getAndroidOptions(),
          );
        } else {
          // No backup available, generate new key
          _encryptionKey = encrypt.Key.fromSecureRandom(32); // AES-256
          _iv = encrypt.IV.fromSecureRandom(16);

          // Store key securely in Keystore
          await _secureStorage.write(
            key: _keyStorageKey,
            value: _encryptionKey.base64,
            aOptions: _getAndroidOptions(),
          );
          await _secureStorage.write(
            key: _ivStorageKey,
            value: _iv.base64,
            aOptions: _getAndroidOptions(),
          );
        }
      }

      // Always keep backup in SharedPreferences for app update scenarios
      await _backupKey();

      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Backup encryption key to SharedPreferences
  /// This survives app updates better than Keystore alone
  Future<void> _backupKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKeyPref, _encryptionKey.base64);
      await prefs.setString(_backupIvPref, _iv.base64);
    } catch (e) {
      // Don't fail initialization if backup fails
    }
  }

  /// Encrypt file and save as .encrypted
  Future<String> encryptFile(String filePath) async {
    try {
      if (!_initialized) await initialize();

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Encrypt using AES-256
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final encrypted = encrypter.encryptBytes(fileBytes, iv: _iv);

      // Save encrypted file with .encrypted extension
      final encryptedFilePath = '$filePath.encrypted';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encrypted.bytes);

      // Delete original file
      await file.delete();

      return encryptedFilePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Decrypt encrypted file to temporary location
  Future<String> decryptFile(String encryptedFilePath) async {
    try {
      if (!_initialized) await initialize();

      final encryptedFile = File(encryptedFilePath);
      if (!encryptedFile.existsSync()) {
        throw Exception('Encrypted file not found: $encryptedFilePath');
      }

      // Read encrypted bytes
      final encryptedBytes = await encryptedFile.readAsBytes();

      try {
        // Try to decrypt
        final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
        final encrypted64 = encrypt.Encrypted(encryptedBytes);
        final decrypted = encrypter.decryptBytes(encrypted64, iv: _iv);

        // Save to temp location (in app's cache directory)
        final tempDir = Directory.systemTemp;
        final tempFileName =
            'temp_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';

        // Get original extension
        final originalExt = encryptedFilePath.replaceAll('.encrypted', '');
        final ext = originalExt.contains('.')
            ? originalExt.split('.').last
            : 'pdf';

        final tempFilePath = '${tempDir.path}/$tempFileName.$ext';
        final tempFile = File(tempFilePath);

        await tempFile.writeAsBytes(decrypted);

        return tempFilePath;
      } catch (decryptError) {
        // Decryption failed - likely due to key loss or corruption

        // Log detailed error for debugging
        if (decryptError.toString().contains('Bad state') ||
            decryptError.toString().contains('Invalid argument')) {}

        throw Exception(
          'Failed to decrypt file. This may occur after app updates. Try re-downloading the file.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete temporary file
  Future<void> deleteTempFile(String tempFilePath) async {
    try {
      final file = File(tempFilePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when clearing encrypted files
    }
  }

  /// Check if file is encrypted
  bool isEncrypted(String filePath) {
    return filePath.endsWith('.encrypted');
  }

  /// Generate random string for unique temp filenames
  String _randomString(int length) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789';
    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Android keystore options for secure storage
  AndroidOptions _getAndroidOptions() {
    return const AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
    );
  }
}
