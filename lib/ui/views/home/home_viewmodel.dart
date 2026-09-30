import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lms_chatbot/app/app.dialogs.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/models/knowledge_chunks.dart';
import 'package:lms_chatbot/core/models/upload_metadata.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:lms_chatbot/core/services/constants/ApiConfigs.dart';
import 'package:lms_chatbot/core/services/pdf_processing.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

const String _systemInstruction = '''
You are a medical education AI assistant designed to help medical students
study, understand, and review medical concepts.

Your highest priorities are:

1. Medical accuracy
2. Evidence-based information
3. Relevant academic sources
4. Clear explanations
5. Verifiable citations
6. Up-to-date medical information when necessary

CONVERSATION CONTEXT

You are having a multi-turn conversation with a medical student. Pay close
attention to the earlier messages in the conversation.

- Use them to understand follow-up questions that refer to something
  discussed before (for example "what about its side effects?", "explain
  that last point", "and in pregnancy?").
- Keep your answer consistent with what you already told the student.
- Do not repeat the full context if a short follow-up answer is enough.

Each turn's final student message contains:

- UPLOADED SOURCE INFORMATION (sources retrieved for this turn)
- UPLOADED KNOWLEDGE (content retrieved for this turn)
- CURRENT QUESTION (what the student just asked)

Follow the source-priority rules below.

============================================================
SOURCE PRIORITY — VERY IMPORTANT
============================================================

You MUST follow this source priority:

STEP 1 — CHECK THE UPLOADED MATERIALS FIRST

The uploaded PDFs, textbooks, lecture notes, and other academic materials
are the student's PRIMARY study resources.

First determine whether the uploaded materials contain enough information
to answer the student's question.

------------------------------------------------------------
CASE 1: UPLOADED MATERIAL FULLY ANSWERS THE QUESTION
------------------------------------------------------------

If the uploaded materials contain sufficient information:

- Use the uploaded material as the PRIMARY and ONLY source.
- Answer using the uploaded material.
- Cite the relevant uploaded source.
- DO NOT use external internet sources.
- DO NOT add external references.
- The References section must contain ONLY the uploaded source(s) actually
  used.

------------------------------------------------------------
CASE 2: UPLOADED MATERIAL PARTIALLY ANSWERS THE QUESTION
------------------------------------------------------------

If the uploaded materials contain only part of the information:

- Use the uploaded material for the information it provides.
- Use reliable external medical information ONLY for the missing information.
- Clearly distinguish information from the uploaded material and external
  information.
- Cite each claim using the source that actually supports it.
- Do NOT replace relevant uploaded information with external information.

------------------------------------------------------------
CASE 3: UPLOADED MATERIAL DOES NOT ANSWER THE QUESTION
------------------------------------------------------------

If the uploaded materials do not contain relevant information:

- Use reliable external medical sources when available.
- Prefer authoritative and current medical sources.
- Do NOT pretend the uploaded material contains the answer.

------------------------------------------------------------
CASE 4: CURRENT MEDICAL INFORMATION
------------------------------------------------------------

If the question involves information that may have changed over time,
such as:

- Current treatment guidelines
- Current drug recommendations
- Updated diagnostic criteria
- Current epidemiology
- Public health recommendations
- Recently published medical evidence

Use current authoritative medical information when available.

Clearly indicate when current information updates or differs from the
uploaded material.

============================================================
EXTERNAL MEDICAL SOURCES
============================================================

When external sources are necessary, prioritize:

1. Peer-reviewed medical journals
2. Systematic reviews and meta-analyses
3. Clinical practice guidelines
4. WHO
5. CDC
6. NIH / NCBI / PubMed
7. Government health agencies
8. Major professional medical organizations
9. Established universities and academic medical institutions

Prefer recent and authoritative sources.

Avoid relying on:

- Blogs
- Forums
- Social media
- Anonymous websites
- Unverified websites
- Commercial health websites

as authoritative medical evidence.

============================================================
CITATIONS
============================================================

Every important medical claim should have an inline citation.

For uploaded PDF sources, use the provided source number.

Example:

Hypertension is defined as ... [0]

If the page number is available:

Hypertension is defined as ... [0, p. 124]

For multiple sources:

The condition is associated with several risk factors [0, 2].

NEVER invent a source number.

NEVER cite a source that was not actually used.

NEVER cite an uploaded source if it does not support the claim.

============================================================
REFERENCES — STRICT FORMAT
============================================================

At the end of the answer, include:

**References**

Only include sources that were actually used to answer the question.

Format references using APA 7th edition as closely as the available
bibliographic information allows.

FORMATTING RULE — CRITICAL:

Each reference MUST be on its own line, and each reference MUST be separated
from the next by ONE BLANK LINE. The reference number must start its own line.

WRONG (merged on one line):

**[0]** Author A. (2022). *Book*. Publisher. **[1]** Author B. (2024). Article.

WRONG (on separate lines but with no blank line between them — these get
merged into one paragraph when rendered):

**[0]** Author A. (2022). *Book*. Publisher.
**[1]** Author B. (2024). Article.

CORRECT (each on its own line, separated by a blank line):

**[0]** Author A. (2022). *Book*. Publisher. DOI not available.

**[1]** Author B. (2024). Article. doi: 10.1234/example.2024.001

============================================================
NO URLS OR LINKS
============================================================

CRITICAL RULE:

DO NOT INCLUDE ANY URLS OR LINKS IN THE RESPONSE.

DO NOT INCLUDE:

- URLs
- Website addresses
- Hyperlinks
- "https://"
- "http://"
- "www."
- Markdown links
- HTML links

Even if a source normally has a URL, OMIT IT.

============================================================
DOI HANDLING — IMPORTANT
============================================================

For every reference, determine whether a DOI is applicable.

A DOI is generally relevant for:

- Peer-reviewed journal articles
- Research articles
- Systematic reviews
- Meta-analyses
- Conference papers or other scholarly publications when a DOI has been
  officially assigned

A DOI may not be applicable for:

- Textbooks or books without an assigned DOI
- Government publications
- WHO/CDC/NIH webpages or reports without a DOI
- Lecture notes
- Uploaded educational PDFs without a DOI
- Other sources that do not have an officially assigned DOI

When an external scholarly source is used:

1. Check whether the source has an officially assigned DOI.

2. If a DOI is available, VERIFY that the DOI actually belongs to the
   cited source.

3. Prefer verification using authoritative sources such as:
   - The journal or publisher's official page
   - Crossref
   - PubMed/NCBI when DOI information is available
   - The official article metadata

4. Only include the DOI if it has been verified.

5. NEVER guess, infer, construct, or fabricate a DOI.

6. If a DOI cannot be reliably verified, end the reference with
   "DOI not available."

7. If the source does not have a DOI, end the reference with
   "DOI not available."

8. Do NOT replace a valid reference with a different source simply because
   another source has a DOI.

9. The DOI must correspond EXACTLY to the cited article/reference,
   including the authors, title, journal, and publication information.

10. A DOI is optional supplementary bibliographic information. The absence
    of a DOI does NOT make a reference invalid.

11. If the available source information already contains a DOI, still verify
    that it belongs to the exact cited source before including it.

12. Never generate a DOI based only on an article title, author name,
    journal name, year, or any recognizable DOI pattern.

============================================================
DOI OUTPUT FORMAT
============================================================

When a DOI is verified, include it at the end of the APA reference as:

doi: 10.xxxx/xxxxx

Do NOT write:

https://doi.org/10.xxxx/xxxxx
http://doi.org/10.xxxx/xxxxx
https://dx.doi.org/10.xxxx/xxxxx

Do NOT include any DOI URL.

If no DOI is found or verified, write "DOI not available." at the end of
that reference instead.

Example WITH verified DOI:

**[1]** Smith, J. A., & Jones, B. C. (2024). Title of article.
*Journal of Medical Research, 15*(2), 123–130. doi: 10.1234/example.2024.001

Example WITHOUT DOI:

**[2]** World Health Organization. (2024). *Title of report*. DOI not available.

Example where a journal article has no verified DOI:

**[3]** Garcia, M. L., & Santos, R. P. (2023). Title of article.
*Medical Education Journal, 12*(4), 200–210. DOI not available.

============================================================
BOOK EXAMPLE
============================================================

**[0]** Author, A. A. (2022). *Title of book* (10th ed.). Publisher.

============================================================
JOURNAL ARTICLE EXAMPLE
============================================================

**[1]** Author, A. A., & Author, B. B. (2024). Title of article.
*Journal Name, 10*(2), 123–130. doi: 10.1000/182

============================================================
ORGANIZATION EXAMPLE
============================================================

**[2]** World Health Organization. (2025). *Title of document*.

============================================================
UPLOADED PDF EXAMPLE
============================================================

**[0]** Author, A. A. (Year). *Title of book*. Publisher.

============================================================
IMPORTANT — NEVER FABRICATE BIBLIOGRAPHIC INFORMATION
============================================================

NEVER invent:

- Authors
- Publication dates
- Publishers
- Editions
- Journal names
- Volume numbers
- Issue numbers
- Page ranges
- DOI numbers
- URLs
- Links
- Page numbers from the uploaded material

If bibliographic information is unavailable, simply omit the missing
information.

An incomplete but accurate reference is ALWAYS better than a complete
fabricated reference.

============================================================
SOURCE RELEVANCE
============================================================

Only cite sources that directly support the statement being made.

Do NOT cite a source merely because:

- It contains a similar keyword
- It is about the same disease
- It appeared in search results
- It is generally related to medicine

The source must actually support the claim.

============================================================
CONFLICTING INFORMATION
============================================================

If the uploaded material and an external source disagree:

- Do not silently combine the information.
- Explain the difference.
- Identify which source supports each statement.
- Prefer newer authoritative clinical guidance when appropriate.
- Clearly communicate the disagreement.

============================================================
MEDICAL SAFETY
============================================================

This chatbot is an educational resource for medical students.

Provide educational information and explanations.

Do not present the response as a definitive patient-specific diagnosis
or treatment decision.

For questions involving patient-specific diagnosis, medications, treatment
decisions, or emergencies, clearly indicate that professional clinical
judgment is required.

============================================================
ANSWER STYLE
============================================================

Answer the student's actual question directly.

Keep the response clear and appropriate for a medical student.

Use headings, bullet points, tables, or step-by-step explanations when
they improve understanding.

Do not unnecessarily reproduce large portions of the source material.

Synthesize the information and explain it clearly.

When the answer (or a section of it) is based on the uploaded knowledge
base, begin it with: "Based on the knowledge base, ..." so the student
knows the information comes directly from their uploaded materials. Start
with that phrase, then give the content and cite the source.

============================================================
FINAL VERIFICATION
============================================================

Before generating the final answer, verify ALL of the following:

1. Did I check the uploaded PDF materials FIRST?

2. If the uploaded PDF fully answered the question, did I use ONLY the
   uploaded PDF?

3. If the uploaded PDF partially answered the question, did I use external
   sources ONLY for the missing information?

4. If the uploaded PDF did not contain the answer, did I use reliable
   external medical sources?

5. Does every important medical claim have a citation?

6. Does every citation correspond to an actual source?

7. Are the references formatted in APA 7th edition?

8. Did I avoid inventing bibliographic information?

9. Did I avoid inventing page numbers?

10. Did I avoid ALL URLs and links?

11. For every scholarly article or research reference, did I check whether
    an officially assigned DOI exists when external verification is
    available?

12. If I included a DOI, did I verify that the DOI belongs to the exact
    cited source?

13. Did I write "DOI not available." when a DOI could not be reliably
    verified or when the source does not have a DOI?

14. Did I avoid guessing, constructing, or fabricating any DOI?

15. Did I avoid adding external references when the uploaded material
    already provided a sufficient answer?

16. Are all cited sources actually relevant to the claims?

17. Did I use the conversation history to resolve follow-up questions?

============================================================
FINAL INSTRUCTION
============================================================

Answer the student's question using the source-priority rules above.

UPLOADED PDF HAS THE ANSWER
→ Use the PDF and cite ONLY the PDF.

UPLOADED PDF HAS PART OF THE ANSWER
→ Use the PDF + external medical sources ONLY for the missing information.

UPLOADED PDF HAS NO ANSWER
→ Use reliable external medical sources.

DO NOT include ANY URLs, links, or website addresses.

Include a DOI in the reference ONLY when it has been verified as belonging
to the exact cited source.

If a DOI does not exist or cannot be reliably verified, end that reference
with "DOI not available."

Do not fabricate medical information or references.
''';

// Payload guards.
//
// The Gemini request is sent as a single POST. On some mobile networks the
// connection aborts once the body grows past roughly 1 MB, which surfaces as
// "Client exception: Software caused connection abort". The limits below keep
// the assembled prompt well under that ceiling.
const int _maxChunkChars = 4000;
const int _maxMessageChars = 6000;
const int _maxHistoryChars = 24000;

String _truncate(String text, int maxChars) =>
    text.length > maxChars
        ? '${text.substring(0, maxChars)}\n[... truncated]'
        : text;

class HomeViewModel extends BaseViewModel {
  final TextEditingController messageController = TextEditingController();

  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _dialogService = locator<DialogService>();
  GenerativeModel? flashModel;
  GenerativeModel? fallbackModel;
  List<KnowledgeChunk> _knowledgeCache = [];
  String uploadStatus = "";
  double uploadProgress = 0;
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // USER DATA
  String role = "";
  String name = "User";
  bool isAiTyping = false;

  // Sidebar state
  bool _showSidebar = false;
  bool get showSidebar => _showSidebar;

  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! Which topic should we learn today?', 'isUser': false},
  ];

  Color get primaryColor {
    if (role.isEmpty) return Colors.grey;
    return role == "teacher" ? Colors.blue : Colors.pink;
  }

  Color get backgroundColor {
    if (role.isEmpty) return Colors.grey.shade50;
    return role == "teacher" ? Colors.blue.shade50 : Colors.pink.shade50;
  }

  Color get drawerColor {
    if (role.isEmpty) return Colors.grey.shade200;
    return role == "teacher" ? Colors.blue.shade100 : Colors.pink.shade100;
  }

  Future<void> init() async {
    setBusy(true);

    try {
      await ApiConfigs.load();

      if (ApiConfigs.isConfigured) {
        flashModel = GenerativeModel(
          model: 'models/gemini-3.5-flash',
          apiKey: ApiConfigs.apiKey,
          systemInstruction: Content.system(_systemInstruction),
        );

        fallbackModel = GenerativeModel(
          model: 'models/gemini-2.5-flash',
          apiKey: ApiConfigs.apiKey,
          systemInstruction: Content.system(_systemInstruction),
        );
      } else {
        debugPrint("Gemini API key not found in env.json");
      }
    } catch (e) {
      debugPrint("Error initializing AI models: $e");
    }

    await loadKnowledgeBase();
    await loadUserData();

    setBusy(false);
    notifyListeners();
  }

  Future<void> loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        role = userData['role'] ?? 'student';
        name = userData['name'] ?? 'User';
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      role = 'student';
      name = 'User';
    }
    notifyListeners();
  }

  Future<void> loadKnowledgeBase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('knowledge_chunks')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();

      _knowledgeCache = snapshot.docs.map((doc) {
        final data = doc.data();
        return KnowledgeChunk(
          content: data['content'] as String? ?? '',
          chunkIndex: (data['chunkIndex'] as num?)?.toInt() ?? 0,
          fileName: data['fileName'] as String? ?? '',
          title: data['title'] as String? ?? '',
          author: data['author'] as String? ?? '',
          startPage: (data['startPage'] as num?)?.toInt() ?? 0,
          endPage: (data['endPage'] as num?)?.toInt() ?? 0,
          doi: data['doi'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint("Error loading knowledge base: $e");
      _knowledgeCache = [];
    }
  }

  void toggleSidebar() {
    _showSidebar = !_showSidebar;
    notifyListeners();
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    messages.add({
      'text': messageController.text.trim(),
      'isUser': true,
    });

    messageController.clear();
    notifyListeners();

    _mockAiResponse();
  }

  void logout() {
    _navigationService.navigateToLoginView();
  }

  Future<void> processPdfForKnowledgeBase(BuildContext context) async {
    if (_isUploading) {
      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Upload In Progress',
        description:
            'Please wait for the current file upload to finish before uploading another file.',
      );
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileMetas = result.files
          .map((f) => UploadFileMetadata(
                fileName: f.name,
                title: f.name,
                author: '',
              ))
          .toList();

      final detailsResponse = await _dialogService.showCustomDialog(
        variant: DialogType.uploadDetails,
        title: 'File Details',
        description: 'Edit the title and author for each file before uploading.',
        data: fileMetas,
      );

      if (detailsResponse?.confirmed != true) {
        return;
      }

      final editedMetas =
          (detailsResponse!.data as List).cast<UploadFileMetadata>();

      _isUploading = true;
      notifyListeners();

      int successCount = 0;
      final errors = <String>[];
      final uploadedDetails = <String>[];

      for (int i = 0; i < result.files.length; i++) {
        final pickedFile = result.files[i];
        final meta = i < editedMetas.length ? editedMetas[i] : fileMetas[i];

        uploadStatus =
            "Uploading ${pickedFile.name}\n(${i + 1}/${result.files.length})";
        uploadProgress = (i + 1) / result.files.length;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 50));

        try {
          uploadStatus = "Reading ${pickedFile.name}...";
          uploadProgress = 0;
          notifyListeners();

          final bytes = await pickedFile.xFile.readAsBytes();

          final sizeCheck = validatePdfSize(bytes, pickedFile.name);
          if (!sizeCheck.isValid) {
            errors.add('"${pickedFile.name}": ${sizeCheck.error}');
            continue;
          }

          int chunkCount = 0;
          bool hasContent = false;

          await processPdfPages(
            bytes: bytes,
            onChunk: (chunk, startPage, endPage) async {
              hasContent = true;
              chunkCount++;
              uploadStatus =
                  "Uploading ${pickedFile.name}\nChunk $chunkCount";
              notifyListeners();

              await _saveSingleChunk(
                fileName: pickedFile.name,
                title: meta.title.isEmpty ? pickedFile.name : meta.title,
                author: meta.author,
                chunk: chunk,
                chunkIndex: chunkCount - 1,
                startPage: startPage,
                endPage: endPage,
                doi: meta.doi,
              );
            },
          );

          await Future.delayed(const Duration(milliseconds: 100));

          if (!hasContent) {
            errors.add(
                '"${pickedFile.name}": no searchable text found — this file '
                'was NOT uploaded. It may be a scanned or image-only PDF.');
            continue;
          }

          successCount++;
          uploadedDetails.add(
              '"${meta.title.isEmpty ? pickedFile.name : meta.title}" '
              '($chunkCount chunk(s))');
        } catch (e) {
          debugPrint("Failed to process ${pickedFile.name}: $e");
          errors.add('"${pickedFile.name}": ${e.toString()}');
        }

        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (errors.isEmpty) {
        if (successCount > 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount PDF(s) uploaded successfully'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
      } else {
        final buffer = StringBuffer()
          ..writeln('$successCount uploaded'
              '${successCount == 1 ? "" : "s"}'
              ' · ${errors.length} failed'
              '${errors.length == 1 ? "" : "s"}:');

        if (uploadedDetails.isNotEmpty) {
          buffer.writeln('\nUploaded:');
          for (final line in uploadedDetails) {
            buffer.writeln('  ✓ $line');
          }
        }

        for (final line in errors) {
          buffer.writeln('  ✗ $line');
        }

        await _dialogService.showCustomDialog(
          variant: DialogType.infoAlert,
          title: 'Upload Finished',
          description: buffer.toString().trim(),
        );
      }
    } catch (e) {
      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error',
        description: e.toString(),
      );
    } finally {
      uploadStatus = "";
      uploadProgress = 0;
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSingleChunk({
    required String fileName,
    required String title,
    required String author,
    required String chunk,
    required int chunkIndex,
    required int startPage,
    required int endPage,
    String doi = '',
  }) async {
    final firestore = FirebaseFirestore.instance;
    const maxRetries = 3;

    final docRef = firestore.collection('knowledge_chunks').doc();

    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        await docRef.set({
          'fileName': fileName,
          'title': title,
          'author': author,
          'chunkIndex': chunkIndex,
          'content': chunk,
          'startPage': startPage,
          'endPage': endPage,
          'doi': doi,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        final written = await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
        if (!written.exists) {
          throw Exception('Write not confirmed by server');
        }
        return;
      } catch (e) {
        debugPrint("Chunk upload attempt ${retry + 1} failed: $e");
        if (retry == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (retry + 1)));
      }
    }
  }

  Future<List<String>> getKnowledgeChunks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('knowledge_chunks')
        .orderBy('chunkIndex')
        .get();

    return snapshot.docs
        .map((e) => e.data()['content'] as String? ?? '')
        .toList();
  }

  Future<List<KnowledgeSearchResult>> searchKnowledgeChunks(
      String query) async {
    final queryWords = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((e) => e.length > 2)
        .toList();

    if (queryWords.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('knowledge_chunks')
        .limit(50)
        .get();

    final scoredChunks = <KnowledgeSearchResult>[];

    for (final doc in snapshot.docs) {
      final documentData = doc.data();
      final data = documentData['content'] as String? ?? '';
      final content = data.toLowerCase();
      int score = 0;

      for (final word in queryWords) {
        if (content.contains(word)) {
          score++;
        }
      }

      if (score > 0) {
        scoredChunks.add(KnowledgeSearchResult(
          content: data,
          fileName: documentData['fileName'] as String? ?? 'Unknown',
          title: documentData['title'] as String? ?? '',
          author: documentData['author'] as String? ?? '',
          startPage: (documentData['startPage'] as num?)?.toInt() ?? 0,
          endPage: (documentData['endPage'] as num?)?.toInt() ?? 0,
          score: score,
          doi: documentData['doi'] as String? ?? '',
        ));
      }
    }

    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    return scoredChunks.take(5).toList();
  }



Future<void> _mockAiResponse() async {
  try {
    isAiTyping = true;
    notifyListeners();

    final question = (messages.last['text'] as String? ?? '').trim();

    // Find the last topic the student asked about before this message.
    String? previousTopic;
    for (int i = messages.length - 2; i >= 0; i--) {
      final m = messages[i];
      if (m['isUser'] == true) {
        final t = (m['text'] as String? ?? '').trim();
        if (t.isNotEmpty) {
          previousTopic = t;
          break;
        }
      }
    }

    // Detect single-word / short follow-up queries.
    final words = question
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList();
    final isSingleWord = words.length == 1;

    const followUpHints = {
      'definition',
      'define',
      'meaning',
      'explain',
      'elaborate',
      'more',
      'details',
      'continue',
      'why',
      'how',
      'what',
    };
    final isFollowUp = isSingleWord &&
        previousTopic != null &&
        followUpHints.contains(words.first) &&
        previousTopic.toLowerCase() != question.toLowerCase();

    // For chained follow-ups, retrieve using the resolved topic.
    final effectiveQuery = isFollowUp ? '$previousTopic $question' : question;

    // ============================================================
    // 1. SEARCH UPLOADED PDFS FIRST
    // ============================================================
    final results = await searchKnowledgeChunks(effectiveQuery);

    final hasUploadedSources = results.isNotEmpty;

    // ============================================================
    // 2. PREPARE UPLOADED KNOWLEDGE
    // ============================================================
    final knowledgeBase = hasUploadedSources
        ? results.map((r) => _truncate(r.content, _maxChunkChars)).join('\n\n---\n\n')
        : 'No relevant information was found in the uploaded materials.';

    // ============================================================
    // 3. PREPARE SOURCE INFORMATION
    // ============================================================
    // Metadata only. The text itself is already carried by knowledgeBase
    // above; repeating it here doubled the request body.
    final sourcesInfo = hasUploadedSources
        ? results.asMap().entries.map((entry) {
            final index = entry.key;
            final r = entry.value;

            final pageText = r.startPage == r.endPage
                ? 'Page ${r.startPage}'
                : 'Pages ${r.startPage}-${r.endPage}';

            final doiText = r.doi.isNotEmpty ? '\nDOI: ${r.doi}' : '';

            return '''
SOURCE [$index]
Source Type: Uploaded PDF / Learning Material
File Name: ${r.fileName}
Location: $pageText$doiText
''';
          }).join('\n\n==============================\n\n')
        : 'No uploaded sources were found.';

    // ============================================================
    // 4. BUILD REQUEST WITH CONVERSATION CONTEXT
    // ============================================================
    final contents = <Content>[];

    // Previous conversation turns (skip the greeting, exclude the
    // question that was just added).
    final historyStart = messages.length > 1 ? 1 : 0;
    final historyEnd = messages.length - 1;

    // Walk backwards so the newest turns are the ones that survive when the
    // budget is exhausted, then restore chronological order.
    final history = <Content>[];
    var historyChars = 0;

    for (int i = historyEnd - 1; i >= historyStart; i--) {
      final msg = messages[i];
      final isUser = msg['isUser'] == true;
      final text = _truncate(msg['text'] as String? ?? '', _maxMessageChars);

      if (historyChars + text.length > _maxHistoryChars && history.isNotEmpty) {
        break;
      }

      history.add(Content(isUser ? 'user' : 'model', [TextPart(text)]));
      historyChars += text.length;
    }

    contents.addAll(history.reversed);

    // Current turn: retrieved sources, knowledge, and the question.
    String resolutionGuide;
    if (isFollowUp) {
      resolutionGuide = 'The student earlier asked about: "$previousTopic". '
          'The CURRENT QUESTION is a SHORT FOLLOW-UP to that topic. Interpret '
          'it in context (for example "definition" means "definition of '
          '$previousTopic"). START your answer with a clear definition, then '
          'elaborate using the source-priority rules above.';
    } else if (isSingleWord) {
      resolutionGuide = 'This is a single-word question. START your answer with '
          'a clear, direct definition of the term, then elaborate (physiology, '
          'causes, clinical significance, etc.) using the source-priority '
          'rules above. Do not skip the definition.';
    } else {
      resolutionGuide =
          'Answer the CURRENT QUESTION directly. Use the conversation '
          'history above to resolve any references to earlier topics.';
    }

    final currentTurn = '''
============================================================
UPLOADED SOURCE INFORMATION
============================================================

$sourcesInfo


============================================================
UPLOADED KNOWLEDGE
============================================================

$knowledgeBase


============================================================
CURRENT QUESTION
============================================================

$question


============================================================
CONTEXT AND ANSWERING GUIDE
============================================================

$resolutionGuide
''';
    contents.add(Content.text(currentTurn));

    // ============================================================
    // 5. CHECK AI MODELS
    // ============================================================
    if (flashModel == null || fallbackModel == null) {
      messages.add({
        'text': ApiConfigs.isConfigured
            ? 'AI models are not initialized. Please restart the app.'
            : 'The AI service is not configured. Add your Gemini API key to '
                'env.json as the "API_KEY" field and restart the app.',
        'isUser': false,
        'sources': <Map<String, dynamic>>[],
      });
      notifyListeners();
      return;
    }

    // ============================================================
    // 6. GENERATE RESPONSE (retry on 503 / 429 across all models)
    // ============================================================
    const maxRetriesPerModel = 3;
    final models = [flashModel!, fallbackModel!];

    GenerateContentResponse? response;
    Object? lastError;

    for (final model in models) {
      for (int attempt = 1; attempt <= maxRetriesPerModel; attempt++) {
        try {
          response = await model.generateContent(contents);
          lastError = null;
          break;
        } catch (apiError) {
          final errorMessage = apiError.toString().toLowerCase();
          final is503 = errorMessage.contains('503') ||
              errorMessage.contains('unavailable');
          final isQuota = errorMessage.contains('429') ||
              errorMessage.contains('quota') ||
              errorMessage.contains('resource exhausted') ||
              errorMessage.contains('rate limit');

          if (!is503 && !isQuota) {
            rethrow;
          }

          lastError = apiError;

          if (attempt < maxRetriesPerModel) {
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      if (response != null) break;
    }

    if (response == null) {
      throw lastError ??
          GenerativeAIException(
              'All AI models are unavailable. Please try again later.');
    }

    // ============================================================
    // 7. SAVE UPLOADED SOURCES FOR UI
    // ============================================================
    final sources = results.map((r) {
      return {
        'fileName': r.fileName,
        'title': r.title,
        'author': r.author,
        'startPage': r.startPage,
        'endPage': r.endPage,
      };
    }).toList();

    messages.add({
      'text': response.text ?? 'No response.',
      'isUser': false,
      'sources': sources,
    });

    notifyListeners();
  } catch (e) {
    messages.add({
      'text': _friendlyError(e),
      'isUser': false,
      'sources': <Map<String, dynamic>>[],
    });

    notifyListeners();
  } finally {
    isAiTyping = false;
    notifyListeners();
  }
}

bool _isAuthError(String message) =>
    message.contains('unauthenticated') ||
    message.contains('401') ||
    message.contains('invalid authentication credentials') ||
    message.contains('api_key_invalid') ||
    message.contains('api key not valid');

String _friendlyError(Object error) {
  final message = error.toString().toLowerCase();

  if (_isAuthError(message)) {
    return 'The AI service rejected the configured API key. Please check the '
        '"API_KEY" value in env.json and restart the app.';
  }

  if (message.contains('429') ||
      message.contains('quota') ||
      message.contains('resource exhausted') ||
      message.contains('rate limit')) {
    return 'The AI service is temporarily over quota. Please wait a moment '
        'and try again.';
  }

  if (message.contains('404') || message.contains('not found')) {
    return 'The AI model could not be found. Please check the configured model '
        'name in home_viewmodel.dart.';
  }

  if (message.contains('connection abort') ||
      message.contains('client exception') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup')) {
    return 'The connection to the AI service was interrupted. This usually '
        'means the request was too large for the current network. Try again, '
        'or switch to a stronger network.';
  }

  return 'Error: $error';
}





  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
