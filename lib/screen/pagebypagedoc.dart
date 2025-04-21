import 'dart:io';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PdfTranslationScreen extends StatefulWidget {
  const PdfTranslationScreen({super.key});

  @override
  State<PdfTranslationScreen> createState() => _PdfTranslationScreenState();
}

class _PdfTranslationScreenState extends State<PdfTranslationScreen> {
  String? _selectedFilePath;
  bool _isLoading = false;
  late PdfViewerController _pdfController;
  int _currentPage = 1;
  int? _totalPages;
  String? _selectedLanguage;
  Uint8List? _translatedPdfBytes; // Now properly recognized

  final List<String> _languages = ['Panjabi', 'Tamil', 'Marathi', 'Hindi','Arabic','Korean','Nepali'];
  final String flaskServerUrl = 'http://192.168.168.42:5000/translate-page';

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _selectedFilePath = null;
      _currentPage = 1;
      _totalPages = null;
      _translatedPdfBytes = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFilePath = result.files.single.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _translateCurrentPage() async {
    if (_selectedFilePath == null || _selectedLanguage == null) return;

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(flaskServerUrl))
        ..fields['page'] = _currentPage.toString()
        ..fields['language'] = _selectedLanguage!
        ..files.add(await http.MultipartFile.fromPath('pdf', _selectedFilePath!));

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        if (bytes.isEmpty) {
          throw Exception('Received empty PDF from server');
        }
        setState(() => _translatedPdfBytes = bytes);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation failed: $e')),
      );
      // For debugging:
      debugPrint('Translation error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadArea() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListTile(
        leading: const Icon(Icons.upload_file),
        title: Text(_selectedFilePath != null
            ? path.basename(_selectedFilePath!)
            : 'Select a PDF'),
        trailing: ElevatedButton(
          onPressed: _pickFile,
          child: const Text('Choose File'),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      decoration: const InputDecoration(
        labelText: 'Select Language',
        border: OutlineInputBorder(),
      ),
      items: _languages.map((lang) =>
          DropdownMenuItem(value: lang, child: Text(lang))
      ).toList(),
      onChanged: (value) => setState(() => _selectedLanguage = value),
    );
  }

  Widget _buildOriginalPdfViewer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Original PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SfPdfViewer.file(
            File(_selectedFilePath!),
            controller: _pdfController,
            onDocumentLoaded: (details) {
              setState(() => _totalPages = details.document.pages.count);
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
                _translatedPdfBytes = null;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        Text('Page $_currentPage of $_totalPages'),
      ],
    );
  }

  Widget _buildTranslatedPdfViewer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildLanguageDropdown(),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isLoading ? null : _translateCurrentPage,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Translate Current Page'),
        ),
        const SizedBox(height: 20),
        if (_translatedPdfBytes != null) ...[
          const Text('Translated PDF',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _translatedPdfBytes != null
                ? SfPdfViewer.memory(_translatedPdfBytes!)
                : const Center(child: Text('No translation available')),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Page Translator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildUploadArea(),
              if (_selectedFilePath != null) ...[
                _buildOriginalPdfViewer(),
                _buildTranslatedPdfViewer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}