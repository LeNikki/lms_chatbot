class KnowledgeChunk {
  final String content;
  final int chunkIndex;
  final String fileName;
  final String title;
  final String author;
  final int startPage;
  final int endPage;

  KnowledgeChunk({
    required this.content,
    required this.chunkIndex,
    required this.fileName,
    this.title = '',
    this.author = '',
    this.startPage = 0,
    this.endPage = 0,
  });
}

class KnowledgeSearchResult {
  final String content;
  final String fileName;
  final String title;
  final String author;
  final int startPage;
  final int endPage;
  final int score;

  KnowledgeSearchResult({
    required this.content,
    required this.fileName,
    required this.startPage,
    required this.endPage,
    required this.score,
    this.title = '',
    this.author = '',
  });
}
