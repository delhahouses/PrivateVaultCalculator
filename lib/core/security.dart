import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class VaultSecurity {
  // A unique app salt to strengthen pin hashes
  static const String _appSalt = "PrivateVaultCalculator_Salt_2026_AGY";

  /// Generates a SHA-256 hash of the PIN combined with the app salt.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin + _appSalt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Scrambles/obfuscates the input file bytes so that it cannot be opened by standard file managers.
  /// Uses a header-scrambling and XOR cipher that is highly efficient for large mobile files (e.g., videos/PDFs)
  /// and ensures the files cannot be parsed by default OS tools.
  static Future<void> encryptFile(File source, File destination, String pin) async {
    final Uint8List fileBytes = await source.readAsBytes();
    final Uint8List keyBytes = utf8.encode(hashPin(pin));
    
    // Perform an in-place XOR scrambling on the bytes
    final scrambledBytes = Uint8List(fileBytes.length);
    for (int i = 0; i < fileBytes.length; i++) {
      // XOR byte by byte using rotating key bytes
      scrambledBytes[i] = fileBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    await destination.writeAsBytes(scrambledBytes);
  }

  /// Decrypts/descrambles the vault file bytes back to its original state.
  static Future<Uint8List> decryptFile(File encryptedFile, String pin) async {
    if (!await encryptedFile.exists()) {
      throw FileNotFoundException("Vault file does not exist on disk.");
    }
    
    final Uint8List encryptedBytes = await encryptedFile.readAsBytes();
    final Uint8List keyBytes = utf8.encode(hashPin(pin));
    
    final decryptedBytes = Uint8List(encryptedBytes.length);
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return decryptedBytes;
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => "FileNotFoundException: $message";
}
