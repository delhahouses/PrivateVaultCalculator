import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../models/vault_file.dart';
import '../../../providers/vault_provider.dart';

class PdfViewerPage extends StatefulWidget {
  final VaultFile file;

  const PdfViewerPage({super.key, required this.file});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  File? _tempDecryptedFile;
  bool _isLoading = true;
  String _errorMessage = '';
  
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  PDFViewController? _pdfViewController;

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
        _errorMessage = 'Failed to decrypt PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Delete decrypted file from disk cache for security
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
      appBar: AppBar(
        title: Text(widget.file.originalName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16)),
        actions: _isReady && _totalPages > 0
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '${_currentPage + 1} / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Outfit')),
                  ),
                )
              : Stack(
                  children: [
                    PDFView(
                      filePath: _tempDecryptedFile!.path,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: _currentPage,
                      fitPolicy: FitPolicy.WIDTH,
                      preventLinkNavigation: false,
                      onRender: (pages) {
                        setState(() {
                          _totalPages = pages ?? 0;
                          _isReady = true;
                        });
                      },
                      onError: (error) {
                        setState(() {
                          _errorMessage = error.toString();
                        });
                      },
                      onPageError: (page, error) {
                        // Handle page specific error
                      },
                      onViewCreated: (PDFViewController pdfViewController) {
                        _pdfViewController = pdfViewController;
                      },
                      onPageChanged: (int? page, int? total) {
                        setState(() {
                          _currentPage = page ?? 0;
                        });
                      },
                    ),
                    if (!_isReady)
                      const Center(child: CircularProgressIndicator()),
                  ],
                )),
      bottomNavigationBar: _isReady && _totalPages > 1
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            _pdfViewController?.setPage(_currentPage - 1);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages - 1
                        ? () {
                            _pdfViewController?.setPage(_currentPage + 1);
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
