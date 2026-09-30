class UploadFileMetadata {
  final String fileName;
  String title;
  String author;
  String doi;

  UploadFileMetadata({
    required this.fileName,
    required this.title,
    required this.author,
    this.doi = '',
  });
}