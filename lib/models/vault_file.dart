class VaultFile {
  final String id;
  final String originalName;
  final String encryptedPath;
  final String mimeType;
  final int sizeBytes;
  final DateTime dateAdded;
  final String parentFolderId;
  bool isFavorite;

  VaultFile({
    required this.id,
    required this.originalName,
    required this.encryptedPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.dateAdded,
    required this.parentFolderId,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'encryptedPath': encryptedPath,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'dateAdded': dateAdded.toIso8601String(),
        'parentFolderId': parentFolderId,
        'isFavorite': isFavorite,
      };

  factory VaultFile.fromJson(Map<String, dynamic> json) => VaultFile(
        id: json['id'] as String,
        originalName: json['originalName'] as String,
        encryptedPath: json['encryptedPath'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: json['sizeBytes'] as int,
        dateAdded: DateTime.parse(json['dateAdded'] as String),
        parentFolderId: json['parentFolderId'] as String,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  // Helper helper to categorize files
  String get category {
    if (mimeType.startsWith('image/')) return 'Images';
    if (mimeType.startsWith('video/')) return 'Videos';
    if (mimeType.startsWith('audio/')) return 'Audio';
    if (mimeType == 'application/pdf') return 'PDFs';
    return 'Documents';
  }

  // Get human readable file size
  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class VaultFolder {
  final String id;
  final String name;
  final DateTime dateCreated;
  final String iconName;

  VaultFolder({
    required this.id,
    required this.name,
    required this.dateCreated,
    required this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateCreated': dateCreated.toIso8601String(),
        'iconName': iconName,
      };

  factory VaultFolder.fromJson(Map<String, dynamic> json) => VaultFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        dateCreated: DateTime.parse(json['dateCreated'] as String),
        iconName: json['iconName'] as String? ?? 'folder',
      );
}
