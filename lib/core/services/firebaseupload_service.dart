import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseUploadService {
  final storage = FirebaseStorage.instance;
  final db = FirebaseFirestore.instance;

  Future<void> upload(File file, String userId) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = storage.ref().child('uploads/$userId/$fileName');

    final task = await ref.putFile(file);

    final url = await task.ref.getDownloadURL();

    await db.collection('files').add({
      'fileName': fileName,
      'url': url,
      'userId': userId,
      'status': 'uploaded',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
