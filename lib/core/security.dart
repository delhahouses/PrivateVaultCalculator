import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class VaultSecurity {
  // A unique app salt to strengthen pin hashes
  static const String _appSalt = "PrivateVaultCalculator_Salt_2026_AGY";

  /// Generates a SHA-256 hash of the PIN combined with the app salt.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin + _appSalt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static enc.Key _deriveKey(String pin) {
    // Generate a 256-bit key by hashing the PIN combined with the app salt
    final pinBytes = utf8.encode(pin + _appSalt);
    final hash = sha256.convert(pinBytes);
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  static enc.IV _deriveIV(String pin) {
    // Generate a 128-bit IV using the first 16 bytes of the md5 hash of the PIN
    final pinBytes = utf8.encode(pin + _appSalt);
    final hash = md5.convert(pinBytes);
    return enc.IV(Uint8List.fromList(hash.bytes.sublist(0, 16)));
  }

  /// Encrypts the input file using AES-256-CBC.
  static Future<void> encryptFile(File source, File destination, String pin) async {
    final Uint8List fileBytes = await source.readAsBytes();
    final key = _deriveKey(pin);
    final iv = _deriveIV(pin);
    
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    
    await destination.writeAsBytes(encrypted.bytes);
  }

  /// Decrypts the vault file using AES-256-CBC.
  static Future<Uint8List> decryptFile(File encryptedFile, String pin) async {
    if (!await encryptedFile.exists()) {
      throw FileNotFoundException("Vault file does not exist on disk.");
    }
    
    final Uint8List encryptedBytes = await encryptedFile.readAsBytes();
    final key = _deriveKey(pin);
    final iv = _deriveIV(pin);
    
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => "FileNotFoundException: $message";
}
