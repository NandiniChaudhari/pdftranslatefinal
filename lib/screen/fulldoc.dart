import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class FullDocumentTranslationScreen extends StatefulWidget {
  const FullDocumentTranslationScreen({super.key});

  @override
  State<FullDocumentTranslationScreen> createState() => _FullDocumentTranslationScreenState();
}

class _FullDocumentTranslationScreenState extends State<FullDocumentTranslationScreen> {
  String? _selectedFilePath;
  String? _selectedLanguage;
  bool _isUploading = false;
  bool _isTranslating = false;
  bool _translationComplete = false;
  String? _translatedContent;
  String? _translatedFilePath;

  final List<String> _languages = [
    'Panjabi', 'Tamil', 'Marathi', 'Hindi','Arabic','Korean','Nepali'
  ];

  // Replace with your server URL
  static const String _serverUrl = 'http://192.168.16.193:5000';

  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _translationComplete = false;
          _translatedFilePath = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick file')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _translateDocument() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a language')),
      );
      return;
    }

    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/translate-pdf'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedFilePath!,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      request.fields['language'] = _selectedLanguage!;

      var response = await request.send();

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/translated_${_selectedLanguage}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final file = File(filePath);
        await response.stream.pipe(file.openWrite());

        setState(() {
          _translationComplete = true;
          _translatedFilePath = filePath;
          _translatedContent = 'Document successfully translated to $_selectedLanguage';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during translation: $e')),
      );
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _openTranslatedFile() async {
    if (_translatedFilePath == null) return;

    try {
      await OpenFile.open(_translatedFilePath!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e')),
      );
    }
  }

  Future<void> _downloadTranslatedFile() async {
    if (_translatedFilePath == null) return;

    try {
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        // For Android, try to get the Downloads directory
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          downloadsDirectory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null || !await downloadsDirectory.exists()) {
        throw Exception('Could not access downloads directory');
      }

      final originalFile = File(_translatedFilePath!);
      final fileName = 'translated_document_${_selectedLanguage}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final destinationPath = '${downloadsDirectory.path}/$fileName';

      await originalFile.copy(destinationPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to ${downloadsDirectory.path}/$fileName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate PDF Document'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File upload section
            const Text(
              'CHOOSE FILES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _selectedFilePath?.split('/').last ?? 'No file chosen',
              style: TextStyle(
                fontSize: 14,
                color: _selectedFilePath != null ? Colors.blue : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // File drop zone
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilePath != null ? Icons.check_circle : Icons.cloud_upload,
                      color: _selectedFilePath != null ? Colors.green : Colors.blue,
                      size: 50,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Drag & drop your PDF here or click to browse',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Only PDF files are supported',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 15),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Only show the rest if a file is selected
            if (_selectedFilePath != null) ...[
              const Divider(),
              const SizedBox(height: 20),

              // Language selection
              const Text(
                'Select Target Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                hint: const Text('Choose language'),
                items: _languages.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Translate button
              ElevatedButton(
                onPressed: _isTranslating ? null : _translateDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isTranslating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Translate Document',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 15),

              // Download button (shown only after translation is complete)
              if (_translationComplete) ...[
                ElevatedButton(
                  onPressed: _downloadTranslatedFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Download PDF',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Translation results
            if (_translationComplete) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Translation Complete',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _translatedContent!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openTranslatedFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_open, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Open Translated PDF',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}