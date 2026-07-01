import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../core/permission_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/premium_provider.dart';
import '../../models/vault_file.dart';
import '../../core/theme.dart';
import 'folder_view.dart';
import 'settings_view.dart';
import 'premium_upgrade_view.dart';
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

  void _showUpgradeSheet() {
    _triggerHaptic();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumUpgradeView()),
    );
  }

  Future<void> _importQuickFile(VaultProvider vault, bool isPremium) async {
    _triggerHaptic();
    final hasPermission = await VaultPermissionHelper.requestStoragePermission(context);
    if (!hasPermission) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        int successCount = 0;
        bool limitExceeded = false;

        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            final file = File(pickedFile.path!);
            final category = _getFolderIdFromExtension(pickedFile.path!);
            final status = await vault.importFile(
              sourceFile: file,
              parentFolderId: category,
              isPremium: isPremium,
            );

            if (status == 1) {
              successCount++;
            } else if (status == -1) {
              limitExceeded = true;
              break;
            }
          }
        }

        if (mounted) {
          if (limitExceeded) {
            _showUpgradeSheet();
          } else if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully encrypted & imported $successCount files.')),
            );
          }
        }
      }
    } catch (e) {
      // Pick files error
    }
  }

  Future<void> _captureFromCamera(VaultProvider vault, bool isPremium, {required bool recordVideo}) async {
    _triggerHaptic();
    
    final hasPermission = await VaultPermissionHelper.requestCameraPermission(
      context,
      needMicrophone: recordVideo,
    );
    if (!hasPermission) return;

    try {
      final picker = ImagePicker();
      final XFile? file = recordVideo 
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.camera);

      if (file != null) {
        final sourceFile = File(file.path);
        final categoryId = recordVideo ? 'videos' : 'photos';
        
        final result = await vault.importFile(
          sourceFile: sourceFile,
          parentFolderId: categoryId,
          isPremium: isPremium,
        );

        // Delete temporary captured file immediately for absolute security
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }

        if (mounted) {
          if (result == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Captured media successfully encrypted and stored.')),
            );
          } else if (result == -1) {
            _showUpgradeSheet();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error saving media to vault.')),
            );
          }
        }
      }
    } catch (e) {
      // Handle camera capture exception
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

  void _showAddFolderDialog(VaultProvider vault, bool isPremium, bool isDark) {
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
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final success = await vault.createFolder(controller.text, isPremium: isPremium);
                  if (mounted) {
                    Navigator.pop(context);
                    if (!success) {
                      _showUpgradeSheet();
                    }
                  }
                }
              },
              child: const Text('Create', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddOptionsSheet(VaultProvider vault, bool isPremium, bool isDark) {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Import or Capture',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionItem(
                    icon: Icons.camera_alt,
                    label: 'Camera Photo',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _captureFromCamera(vault, isPremium, recordVideo: false);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.videocam,
                    label: 'Record Video',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _captureFromCamera(vault, isPremium, recordVideo: true);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.photo_library,
                    label: 'Import Files',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _importQuickFile(vault, isPremium);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.create_new_folder,
                    label: 'New Folder',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddFolderDialog(vault, isPremium, isDark);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultProv = Provider.of<VaultProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final premiumProv = Provider.of<PremiumProvider>(context);
    final isDark = settingsProv.isDarkMode;

    return Listener(
      onPointerDown: (_) => _userInteraction(),
      onPointerMove: (_) => _userInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'Secure Vault',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              if (vaultProv.isDecoy) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Decoy Mode',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                )
              ]
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (!premiumProv.isPremium)
              TextButton.icon(
                icon: const Icon(Icons.stars, color: Colors.amber, size: 18),
                label: const Text('PRO', style: TextStyle(color: Colors.amber, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                onPressed: _showUpgradeSheet,
              ),
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
                        // Dynamic storage and security dashboard
                        _buildStorageDashboard(vaultProv, premiumProv, isDark),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Categories & Folders',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.create_new_folder_outlined),
                              onPressed: () => _showAddFolderDialog(vaultProv, premiumProv.isPremium, isDark),
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
          onPressed: () => _showAddOptionsSheet(vaultProv, premiumProv.isPremium, isDark),
          icon: const Icon(Icons.add),
          label: const Text('Add Content', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStorageDashboard(VaultProvider vault, PremiumProvider premium, bool isDark) {
    final summary = vault.getStorageSummary();
    double totalMB = summary.values.fold(0, (prev, val) => prev + val);
    
    // Free tier has 5 files limit, PRO is unlimited.
    double maxLimit = 512.0; 
    double percentage = (totalMB / maxLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security & Storage Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: premium.isPremium ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  premium.isPremium ? 'PRO UNLOCKED' : 'FREE TIER (LIMITS ON)',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: premium.isPremium ? Colors.amber : Colors.grey,
                  ),
                ),
              )
            ],
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
                      '${totalMB.toStringAsFixed(1)} MB of ${maxLimit.toStringAsFixed(0)} MB',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Secured Files: ${vault.files.length} ${!premium.isPremium ? "/ 5 max" : ""}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: !premium.isPremium && vault.files.length >= 5 ? Colors.redAccent : Colors.grey,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Screenshots: Blocked  |  Files: AES-256 Encrypted',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.green.shade300),
                ),
              )
            ],
          )
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: const Text(
          'No favorited items yet.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Outfit', fontSize: 13),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot preview file format of ${file.originalName}')),
      );
    }
  }
}
