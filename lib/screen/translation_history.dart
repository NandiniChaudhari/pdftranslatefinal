import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Add this package
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TranslationHistoryScreen extends StatefulWidget {
  const TranslationHistoryScreen({super.key});

  @override
  State<TranslationHistoryScreen> createState() => _TranslationHistoryScreenState();
}

class _TranslationHistoryScreenState extends State<TranslationHistoryScreen> {
  List<dynamic> pdfFiles = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTranslatedPDFs();
  }

  Future<void> fetchTranslatedPDFs() async {
    try {
      const String serverUrl = 'http://10.10.6.108:5000/list-translated-pdfs';
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pdfFiles = data['files'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load PDFs: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error connecting to server: $e';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFormattedDate(String filename) {
    try {
      final dateMatch = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(filename);
      if (dateMatch != null) {
        final date = DateTime.parse(
            '${dateMatch.group(1)}-${dateMatch.group(2)}-${dateMatch.group(3)}');
        return DateFormat('yyyy-MM-dd').format(date);
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _openPDF(BuildContext context, String filename) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Download the PDF file
      final response = await http.get(
        Uri.parse('http://192.168.168.42:5000/translated_pdfs/$filename'),
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        // Close loading dialog
        Navigator.of(context).pop();

        // Open PDF viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(pdfPath: file.path),
          ),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translated PDFs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTranslatedPDFs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : pdfFiles.isEmpty
          ? const Center(child: Text('No translated PDFs found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          final pdf = pdfFiles[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(pdf['filename']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Translated on ${_getFormattedDate(pdf['filename'])}'),
                  Text('Size: ${_formatFileSize(pdf['size'])}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPDF(context, pdf['filename']),
            ),
          );
        },
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String pdfPath;

  const PDFViewerScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onRender: (pages) => debugPrint('PDF rendered with $pages pages'),
        onError: (error) => debugPrint(error.toString()),
        onPageError: (page, error) => debugPrint('$page: ${error.toString()}'),
        onViewCreated: (PDFViewController controller) {
          debugPrint('PDF view created');
        },
      ),
    );
  }
}