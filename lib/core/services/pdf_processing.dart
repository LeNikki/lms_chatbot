import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

const int maxFileSizeBytes = 30 * 1024 * 1024; // 30MB
const int maxPageCount = 500;
const int defaultChunkSize = 1000;

class PdfValidationResult {
  final bool isValid;
  final String? error;
  final int? fileSizeBytes;

  PdfValidationResult({
    required this.isValid,
    this.error,
    this.fileSizeBytes,
  });
}

PdfValidationResult validatePdfSize(Uint8List bytes, String fileName) {
  final sizeBytes = bytes.length;

  if (sizeBytes > maxFileSizeBytes) {
    return PdfValidationResult(
      isValid: false,
      error:
          '"$fileName" is ${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB. '
          'Maximum allowed size is 30MB.',
      fileSizeBytes: sizeBytes,
    );
  }

  return PdfValidationResult(
    isValid: true,
    fileSizeBytes: sizeBytes,
  );
}

/// Processes a PDF page-by-page, calling [onChunk] for each chunk as it's produced.
/// Memory stays around 1 page instead of 500 pages.
/// No large List<String> is ever accumulated.
/// Tracks the start and end page for each chunk so students can verify sources.
Future<void> processPdfPages({
  required Uint8List bytes,
  required Future<void> Function(String chunk, int startPage, int endPage) onChunk,
}) async {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);

  final pageCount = document.pages.count;

  if (pageCount > maxPageCount) {
    document.dispose();
    throw Exception(
      '$pageCount pages. Maximum allowed is $maxPageCount pages.',
    );
  }

  try {
    final buffer = StringBuffer();
    int chunkStartPage = 0;
    int currentPage = 0;

    for (int i = 0; i < pageCount; i++) {
      final pageText = extractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );

      if (pageText.trim().isEmpty) {
        continue;
      }

      currentPage = i + 1;

      if (buffer.length == 0) {
        chunkStartPage = currentPage;
      }

      buffer.write(pageText);
      buffer.write('\n\n');

      if (buffer.length >= defaultChunkSize) {
        final chunk = buffer.toString().trim();
        buffer.clear();
        await onChunk(chunk, chunkStartPage, currentPage);
      }
    }

    if (buffer.isNotEmpty) {
      final chunk = buffer.toString().trim();
      await onChunk(chunk, chunkStartPage, currentPage);
    }
  } finally {
    document.dispose();
  }
}
