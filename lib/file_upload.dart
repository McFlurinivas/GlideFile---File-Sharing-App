import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class UploadResult {
  final String? downloadUrl;
  final String? errorMessage;

  UploadResult({this.downloadUrl, this.errorMessage});
}

Future<bool> isConnected() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true; 
    }
  } on SocketException catch (_) {
    const SnackBar(content: Text('No network connection. Please try again later.'));
  }
  return false; 
}

Future<UploadResult> uploadFile(String filePath) async {
  if (!await isConnected()) {
    return UploadResult(errorMessage: 'No network connection. Please try again later.');
  }

  File file = File(filePath);
  String fileName = basename(file.path);
  try {
    final storageRef = FirebaseStorage.instance.ref().child('files/$fileName');
    await storageRef.putFile(file);
    String downloadUrl = await storageRef.getDownloadURL();
    Timer(const Duration(minutes: 5), () async {
      await storageRef.delete();
    });
    return UploadResult(downloadUrl: downloadUrl);
  } catch (e) {
    return UploadResult(errorMessage: 'Error: $e. Please try again.');
  }
}

