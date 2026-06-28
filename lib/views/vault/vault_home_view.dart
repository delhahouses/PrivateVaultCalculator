import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/vault_file.dart';
import '../../core/theme.dart';
import 'folder_view.dart';
import 'settings_view.dart';
import '../calculator_view.dart';
import 'viewers/image_viewer.dart';
import 'viewers/video_viewer.dart';
import 'viewers/audio_viewer.dart';
import 'viewers/pdf_viewer.dart';


class VaultHomeView extends StatefulWidget {
  const VaultHomeView({super.key});

  @override
  State<VaultHomeView> createState() => _VaultHomeViewState();
}

class _VaultHomeViewState extends State<VaultHomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle auto-lock on app lifecycle changes (e.g. backgrounded)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProv.autoLockDuration > 0) {
        authProv.lock();
        _checkLockState();
      }
    }
  }

  void _checkLockState() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (!authProv.isAuthenticated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault locked due to inactivity.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CalculatorView()),
        (route) => false,
      );
    }
  }

  void _userInteraction() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
    authProv.updateInteractionTime();
    authProv.checkAutoLock(settingsProv.autoLockDuration);
    _checkLockState();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _importQuickFile(VaultProvider vault) async {
    _triggerHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        int successCount = 0;
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            final file = File(pickedFile.path!);
            final category = _getFolderIdFromExtension(pickedFile.path!);
            final success = await vault.importFile(
              sourceFile: file,
              parentFolderId: category,
            );
            if (success) successCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully encrypted & imported $successCount files.')),
          );
        }
      }
    } catch (e) {
      // Pick files error
    }
  }

  String _getFolderIdFromExtension(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.gif' || ext == '.webp') {
      return 'photos';
    }
    if (ext == '.mp4' || ext == '.avi' || ext == '.mkv' || ext == '.mov') {
      return 'videos';
    }
    if (ext == '.mp3' || ext == '.wav' || ext == '.m4a' || ext == '.flac') {
      return 'audio';
    }
    if (ext == '.pdf' || ext == '.doc' || ext == '.docx' || ext == '.xls' || ext == '.xlsx' || ext == '.ppt' || ext == '.pptx' || ext == '.txt') {
      return 'documents';
    }
    return 'others';
  }

  void _showAddFolderDialog(VaultProvider vault, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Folder', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Folder Name',
              filled: true,
              fillColor: isDark ? Colors.white05 : Colors.black05,
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
                  vault.createFolder(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultProv = Provider.of<VaultProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;

    return Listener(
      onPointerDown: (_) => _userInteraction(),
      onPointerMove: (_) => _userInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Secure Vault',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _triggerHaptic();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                _triggerHaptic();
                Provider.of<AuthProvider>(context, listen: false).lock();
                _checkLockState();
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
          child: SafeArea(
            child: vaultProv.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStorageDashboard(vaultProv, isDark),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.create_new_folder_outlined),
                              onPressed: () => _showAddFolderDialog(vaultProv, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFoldersGrid(vaultProv, isDark),
                        const SizedBox(height: 24),
                        const Text(
                          'Favorites',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                        ),
                        const SizedBox(height: 12),
                        _buildFavoritesList(vaultProv, isDark),
                      ],
                    ),
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _importQuickFile(vaultProv),
          icon: const Icon(Icons.add_moderator),
          label: const Text('Add File', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStorageDashboard(VaultProvider vault, bool isDark) {
    final summary = vault.getStorageSummary();
    double totalMB = summary.values.fold(0, (prev, val) => prev + val);
    
    // Custom simulated limit (e.g. 512 MB for local user storage)
    double maxLimit = 512.0; 
    double percentage = (totalMB / maxLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encrypted Storage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  )
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalMB.toStringAsFixed(1)} MB of ${maxLimit.toStringAsFixed(0)} MB used',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total files secured: ${vault.files.length}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Outfit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersGrid(VaultProvider vault, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: vault.folders.length,
      itemBuilder: (context, index) {
        final folder = vault.folders[index];
        final fileCount = vault.files.where((f) => f.parentFolderId == folder.id).length;

        IconData fIcon = Icons.folder;
        if (folder.iconName == 'image') fIcon = Icons.image;
        if (folder.iconName == 'video') fIcon = Icons.videocam;
        if (folder.iconName == 'audio') fIcon = Icons.audiotrack;
        if (folder.iconName == 'document') fIcon = Icons.description;

        return GestureDetector(
          onTap: () {
            _triggerHaptic();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FolderView(folder: folder)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassBoxDecoration(isDark: isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(fIcon, color: Theme.of(context).colorScheme.primary, size: 28),
                    // Allow deleting custom folders
                    if (!['photos', 'videos', 'audio', 'documents', 'others'].contains(folder.id))
                      GestureDetector(
                        onTap: () {
                          _triggerHaptic();
                          vault.deleteFolder(folder.id);
                        },
                        child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$fileCount files',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Outfit'),
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

  Widget _buildFavoritesList(VaultProvider vault, bool isDark) {
    final favorites = vault.files.where((f) => f.isFavorite).toList();
    
    if (favorites.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: const Text(
          'No favorited items yet.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Outfit'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final file = favorites[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(
              file.category == 'Images' ? Icons.image :
              file.category == 'Videos' ? Icons.videocam :
              file.category == 'Audio' ? Icons.audiotrack : Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(file.readableSize),
            trailing: IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () {
                _triggerHaptic();
                vault.toggleFavorite(file.id);
              },
            ),
            onTap: () {
              _triggerHaptic();
              _openFileViewer(context, file);
            },
          ),
        );
      },
    );
  }

  void _openFileViewer(BuildContext context, VaultFile file) {
    if (file.category == 'Images') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(file: file),
        ),
      );
    } else if (file.category == 'Videos') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoViewerPage(file: file),
        ),
      );
    } else if (file.category == 'Audio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioViewerPage(file: file),
        ),
      );
    } else if (file.category == 'PDFs') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(file: file),
        ),
      );
    } else {
      // Fallback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot preview file format of ${file.originalName}')),
      );
    }
  }
}
