import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/vault_file.dart';
import '../core/security.dart';

class VaultProvider with ChangeNotifier {
  List<VaultFolder> _folders = [];
  List<VaultFile> _files = [];
  bool _isLoading = false;
  String? _currentPin; // In-memory reference for file encryption/decryption

  List<VaultFolder> get folders => _folders;
  List<VaultFile> get files => _files;
  bool get isLoading => _isLoading;

  VaultProvider() {
    _initVault();
  }

  /// Sets the currently active PIN for cryptographic operations.
  void setPin(String pin) {
    _currentPin = pin;
  }

  Future<void> _initVault() async {
    _isLoading = true;
    notifyListeners();
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(docDir.path, 'vault_files'));
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      final metaFile = File(p.join(docDir.path, 'vault_metadata.json'));
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        
        final List<dynamic> folderJsonList = data['folders'] ?? [];
        final List<dynamic> fileJsonList = data['files'] ?? [];

        _folders = folderJsonList.map((item) => VaultFolder.fromJson(item)).toList();
        _files = fileJsonList.map((item) => VaultFile.fromJson(item)).toList();
      } else {
        // Create default system folders on first startup
        _folders = [
          VaultFolder(id: 'photos', name: 'Photos', dateCreated: DateTime.now(), iconName: 'image'),
          VaultFolder(id: 'videos', name: 'Videos', dateCreated: DateTime.now(), iconName: 'video'),
          VaultFolder(id: 'audio', name: 'Audio', dateCreated: DateTime.now(), iconName: 'audio'),
          VaultFolder(id: 'documents', name: 'Documents', dateCreated: DateTime.now(), iconName: 'document'),
          VaultFolder(id: 'others', name: 'Others', dateCreated: DateTime.now(), iconName: 'folder'),
        ];
        await _saveMetadata();
      }
    } catch (e) {
      // Handle initialization error silently or log
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final metaFile = File(p.join(docDir.path, 'vault_metadata.json'));
      
      final Map<String, dynamic> data = {
        'folders': _folders.map((f) => f.toJson()).toList(),
        'files': _files.map((f) => f.toJson()).toList(),
      };

      await metaFile.writeAsString(json.encode(data));
    } catch (e) {
      // Error saving metadata
    }
  }

  /// Create a custom user folder.
  Future<void> createFolder(String name) async {
    final folder = VaultFolder(
      id: const Uuid().v4(),
      name: name,
      dateCreated: DateTime.now(),
      iconName: 'folder',
    );
    _folders.add(folder);
    await _saveMetadata();
    notifyListeners();
  }

  /// Delete a folder and all files inside it.
  Future<void> deleteFolder(String folderId) async {
    // Delete files in this folder first
    final filesInFolder = _files.where((f) => f.parentFolderId == folderId).toList();
    for (var file in filesInFolder) {
      await deleteFile(file.id);
    }
    _folders.removeWhere((f) => f.id == folderId);
    await _saveMetadata();
    notifyListeners();
  }

  /// Import a file into the vault, encrypt it, and store it.
  Future<bool> importFile({
    required File sourceFile,
    required String parentFolderId,
  }) async {
    if (_currentPin == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final fileId = const Uuid().v4();
      final extension = p.extension(sourceFile.path);
      
      // Store encrypted files as .dat with random UUIDs to hide formats
      final encryptedFileName = '$fileId.dat';
      final encryptedFilePath = p.join(docDir.path, 'vault_files', encryptedFileName);
      final destinationFile = File(encryptedFilePath);

      // Perform encryption
      await VaultSecurity.encryptFile(sourceFile, destinationFile, _currentPin!);

      // Gather Mimetype info
      final filename = p.basename(sourceFile.path);
      final mimeType = _determineMimeType(filename);
      final size = await sourceFile.length();

      final vaultFile = VaultFile(
        id: fileId,
        originalName: filename,
        encryptedPath: encryptedFilePath,
        mimeType: mimeType,
        sizeBytes: size,
        dateAdded: DateTime.now(),
        parentFolderId: parentFolderId,
      );

      _files.add(vaultFile);
      await _saveMetadata();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Decrypts a vault file and saves it in the temporary cache directory.
  /// Returns the path to the decrypted temporary file.
  Future<File> getDecryptedFile(VaultFile vaultFile) async {
    if (_currentPin == null) {
      throw Exception("PIN key not loaded in vault manager.");
    }
    
    final encryptedFile = File(vaultFile.encryptedPath);
    final decryptedBytes = await VaultSecurity.decryptFile(encryptedFile, _currentPin!);
    
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = p.join(tempDir.path, 'vault_temp_${vaultFile.id}_${vaultFile.originalName}');
    final tempFile = File(tempFilePath);
    
    await tempFile.writeAsBytes(decryptedBytes);
    return tempFile;
  }

  /// Delete a file from disk and database.
  Future<void> deleteFile(String fileId) async {
    try {
      final index = _files.indexWhere((f) => f.id == fileId);
      if (index != -1) {
        final vaultFile = _files[index];
        final diskFile = File(vaultFile.encryptedPath);
        if (await diskFile.exists()) {
          await diskFile.delete();
        }
        _files.removeAt(index);
        await _saveMetadata();
        notifyListeners();
      }
    } catch (e) {
      // Error deleting file
    }
  }

  /// Rename a file.
  Future<void> renameFile(String fileId, String newName) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      // Keep extension if user did not input it
      final ext = p.extension(_files[idx].originalName);
      final hasNewExt = p.extension(newName).isNotEmpty;
      _files[idx] = VaultFile(
        id: _files[idx].id,
        originalName: hasNewExt ? newName : '$newName$ext',
        encryptedPath: _files[idx].encryptedPath,
        mimeType: _files[idx].mimeType,
        sizeBytes: _files[idx].sizeBytes,
        dateAdded: _files[idx].dateAdded,
        parentFolderId: _files[idx].parentFolderId,
        isFavorite: _files[idx].isFavorite,
      );
      await _saveMetadata();
      notifyListeners();
    }
  }

  /// Move file to another folder.
  Future<void> moveFile(String fileId, String targetFolderId) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      _files[idx] = VaultFile(
        id: _files[idx].id,
        originalName: _files[idx].originalName,
        encryptedPath: _files[idx].encryptedPath,
        mimeType: _files[idx].mimeType,
        sizeBytes: _files[idx].sizeBytes,
        dateAdded: _files[idx].dateAdded,
        parentFolderId: targetFolderId,
        isFavorite: _files[idx].isFavorite,
      );
      await _saveMetadata();
      notifyListeners();
    }
  }

  /// Toggle favorite.
  Future<void> toggleFavorite(String fileId) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      _files[idx].isFavorite = !_files[idx].isFavorite;
      await _saveMetadata();
      notifyListeners();
    }
  }

  /// Returns storage summary.
  Map<String, double> getStorageSummary() {
    double photos = 0, videos = 0, audio = 0, docs = 0, others = 0;
    
    for (var f in _files) {
      final sizeMB = f.sizeBytes / (1024 * 1024);
      if (f.category == 'Images') photos += sizeMB;
      else if (f.category == 'Videos') videos += sizeMB;
      else if (f.category == 'Audio') audio += sizeMB;
      else if (f.category == 'PDFs' || f.category == 'Documents') docs += sizeMB;
      else others += sizeMB;
    }

    return {
      'Images': photos,
      'Videos': videos,
      'Audio': audio,
      'Documents': docs,
      'Others': others,
    };
  }

  String _determineMimeType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.gif' || ext == '.webp') {
      return 'image/${ext.replaceAll('.', '')}';
    }
    if (ext == '.mp4' || ext == '.avi' || ext == '.mkv' || ext == '.mov') {
      return 'video/${ext.replaceAll('.', '')}';
    }
    if (ext == '.mp3' || ext == '.wav' || ext == '.m4a' || ext == '.flac') {
      return 'audio/${ext.replaceAll('.', '')}';
    }
    if (ext == '.pdf') return 'application/pdf';
    if (ext == '.txt') return 'text/plain';
    if (ext == '.zip') return 'application/zip';
    if (ext == '.rar') return 'application/x-rar-compressed';
    return 'application/octet-stream';
  }
}
