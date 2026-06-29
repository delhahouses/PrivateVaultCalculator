import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/vault_file.dart';
import '../../providers/vault_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';
import 'vault_home_view.dart'; // import media viewer redirects if needed, but we will import actual viewer pages
import 'viewers/image_viewer.dart';
import 'viewers/video_viewer.dart';
import 'viewers/audio_viewer.dart';
import 'viewers/pdf_viewer.dart';

class FolderView extends StatefulWidget {
  final VaultFolder folder;

  const FolderView({super.key, required this.folder});

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  bool _isGridView = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'name', 'date', 'size'
  bool _sortAscending = false;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = {};

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _pickAndImportFile(VaultProvider vault) async {
    _triggerHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        int count = 0;
        for (var file in result.files) {
          if (file.path != null) {
            final success = await vault.importFile(
              sourceFile: File(file.path!),
              parentFolderId: widget.folder.id,
            );
            if (success) count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $count files successfully.')),
          );
        }
      }
    } catch (e) {
      // Pick file error
    }
  }

  void _toggleSelection(String id) {
    _triggerHaptic();
    setState(() {
      if (_selectedFileIds.contains(id)) {
        _selectedFileIds.remove(id);
        if (_selectedFileIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFileIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFileIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected(VaultProvider vault) async {
    _triggerHaptic();
    final count = _selectedFileIds.length;
    final ids = List<String>.from(_selectedFileIds);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Files', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to permanently delete these $count items from the secure vault?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                for (var id in ids) {
                  await vault.deleteFile(id);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted $count files.')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _moveSelected(VaultProvider vault, bool isDark) {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Selected Files', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vault.folders.length,
              itemBuilder: (context, idx) {
                final destFolder = vault.folders[idx];
                if (destFolder.id == widget.folder.id) return const SizedBox.shrink();

                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(destFolder.name, style: const TextStyle(fontFamily: 'Outfit')),
                  onTap: () async {
                    for (var fileId in _selectedFileIds) {
                      await vault.moveFile(fileId, destFolder.id);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      _clearSelection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Moved files to ${destFolder.name}.')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(VaultFile file, VaultProvider vault, bool isDark) {
    _triggerHaptic();
    final nameWithoutExt = p.basenameWithoutExtension(file.originalName);
    final controller = TextEditingController(text: nameWithoutExt);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename File', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  vault.renameFile(file.id, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Rename', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  List<VaultFile> _getProcessedFiles(List<VaultFile> allFiles) {
    // Filter by folder
    List<VaultFile> folderFiles = allFiles.where((f) => f.parentFolderId == widget.folder.id).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      folderFiles = folderFiles.where((f) => f.originalName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort files
    folderFiles.sort((a, b) {
      int comparison = 0;
      if (_sortBy == 'name') {
        comparison = a.originalName.compareTo(b.originalName);
      } else if (_sortBy == 'size') {
        comparison = a.sizeBytes.compareTo(b.sizeBytes);
      } else {
        comparison = a.dateAdded.compareTo(b.dateAdded);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return folderFiles;
  }

  void _openFileViewer(BuildContext context, VaultFile file) {
    if (file.category == 'Images') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerPage(file: file)));
    } else if (file.category == 'Videos') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => VideoViewerPage(file: file)));
    } else if (file.category == 'Audio') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AudioViewerPage(file: file)));
    } else if (file.category == 'PDFs') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerPage(file: file)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot preview file: ${file.originalName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultProv = Provider.of<VaultProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final processedFiles = _getProcessedFiles(vaultProv.files);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
              title: Text('${_selectedFileIds.length} Selected', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              actions: [
                IconButton(icon: const Icon(Icons.drive_file_move_outlined), onPressed: () => _moveSelected(vaultProv, isDark)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteSelected(vaultProv)),
              ],
            )
          : AppBar(
              title: Text(widget.folder.name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    _triggerHaptic();
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (val) {
                    _triggerHaptic();
                    setState(() {
                      if (_sortBy == val) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = val;
                        _sortAscending = true;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                    const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                    const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
                  ],
                ),
              ],
            ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search in folder...',
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: processedFiles.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No files match search query.' : 'This folder is empty.',
                          style: const TextStyle(color: Colors.grey, fontFamily: 'Outfit'),
                        ),
                      )
                    : (_isGridView
                        ? _buildGridView(processedFiles, vaultProv, isDark)
                        : _buildListView(processedFiles, vaultProv, isDark)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndImportFile(vaultProv),
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildGridView(List<VaultFile> filesList, VaultProvider vault, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: filesList.length,
      itemBuilder: (context, index) {
        final file = filesList[index];
        final isSelected = _selectedFileIds.contains(file.id);

        IconData fileIcon = Icons.insert_drive_file_outlined;
        if (file.category == 'Images') fileIcon = Icons.image;
        if (file.category == 'Videos') fileIcon = Icons.videocam;
        if (file.category == 'Audio') fileIcon = Icons.audiotrack;
        if (file.category == 'PDFs') fileIcon = Icons.description;

        return GestureDetector(
          onLongPress: () => _toggleSelection(file.id),
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(file.id);
            } else {
              _openFileViewer(context, file);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15) 
                  : (isDark ? const Color(0x331C1C1E) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : (isDark ? Colors.white10 : Colors.black12),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      vault.toggleFavorite(file.id);
                    },
                    child: Icon(
                      file.isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: file.isFavorite ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
                Icon(fileIcon, size: 40, color: Theme.of(context).colorScheme.primary),
                Column(
                  children: [
                    Text(
                      file.originalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.readableSize,
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Outfit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<VaultFile> filesList, VaultProvider vault, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filesList.length,
      itemBuilder: (context, index) {
        final file = filesList[index];
        final isSelected = _selectedFileIds.contains(file.id);

        IconData fileIcon = Icons.insert_drive_file_outlined;
        if (file.category == 'Images') fileIcon = Icons.image;
        if (file.category == 'Videos') fileIcon = Icons.videocam;
        if (file.category == 'Audio') fileIcon = Icons.audiotrack;
        if (file.category == 'PDFs') fileIcon = Icons.description;

        return Card(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: ListTile(
            onLongPress: () => _toggleSelection(file.id),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(file.id);
              } else {
                _openFileViewer(context, file);
              }
            },
            leading: Icon(fileIcon, color: Theme.of(context).colorScheme.primary),
            title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit')),
            subtitle: Text(file.readableSize, style: const TextStyle(fontFamily: 'Outfit')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(file.isFavorite ? Icons.star : Icons.star_border, color: file.isFavorite ? Colors.amber : Colors.grey),
                  onPressed: () {
                    _triggerHaptic();
                    vault.toggleFavorite(file.id);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'rename') {
                      _showRenameDialog(file, vault, isDark);
                    } else if (val == 'delete') {
                      _toggleSelection(file.id);
                      _deleteSelected(vault);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
