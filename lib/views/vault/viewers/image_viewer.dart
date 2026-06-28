import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../../../models/vault_file.dart';
import '../../../providers/vault_provider.dart';

class ImageViewerPage extends StatefulWidget {
  final VaultFile file;

  const ImageViewerPage({super.key, required this.file});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  File? _tempDecryptedFile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _decryptFile();
  }

  Future<void> _decryptFile() async {
    try {
      final vaultProv = Provider.of<VaultProvider>(context, listen: false);
      final file = await vaultProv.getDecryptedFile(widget.file);
      setState(() {
        _tempDecryptedFile = file;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to decrypt file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Crucial for security: delete the decrypted file from cache immediately
    if (_tempDecryptedFile != null) {
      _tempDecryptedFile!.exists().then((exists) {
        if (exists) {
          _tempDecryptedFile!.delete().catchError((_) => _tempDecryptedFile!);
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.file.originalName,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (_errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'Outfit'),
                    ),
                  ),
                )
              : PhotoView(
                  imageProvider: FileImage(_tempDecryptedFile!),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.file.id),
                )),
    );
  }
}
