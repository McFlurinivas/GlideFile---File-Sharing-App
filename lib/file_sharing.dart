import 'dart:async';
import 'dart:ui' as ui;

import 'package:filesharing/file_upload.dart';
import 'package:filesharing/qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FileSharing extends StatefulWidget {
  const FileSharing({super.key});

  @override
  State<FileSharing> createState() => _FileSharingState();
}

class _FileSharingState extends State<FileSharing> {
  String? filePath;
  String? downloadUrl;
  bool isUploading = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSnack(String title) {
    final snackbar = SnackBar(
        content: Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
      ),
    ));
    scaffoldMessengerKey.currentState?.showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            elevation: 15,
            title: const Text('File Sharer'),
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Share a file by selecting it and scanning the QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: filePath != null
                        ? FutureBuilder<ui.Image>(
                            future: _loadOverlayImage(),
                            builder: (BuildContext ctx,
                                AsyncSnapshot<ui.Image> snapshot) {
                              const double size = 280.0;
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                    width: size, height: size);
                              }
                              return CustomPaint(
                                size: const Size.square(size),
                                painter: QrPainter(
                                  data: downloadUrl ?? '',
                                  version: QrVersions.auto,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xff128760),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.circle,
                                    color: Color(0xff1a5441),
                                  ),
                                  embeddedImage: snapshot.data,
                                  embeddedImageStyle:
                                      const QrEmbeddedImageStyle(
                                    size: Size.square(60),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Text('No file selected'),
                  ),
                ),
                if (isUploading) const CircularProgressIndicator(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 40)
                          .copyWith(bottom: 40),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        filePath = await pickFile();
                        if (filePath != null) {
                          setState(() {
                            isUploading = true;
                            downloadUrl =
                                null; // Reset the downloadUrl to remove the old QR code
                          });
                          UploadResult result = await uploadFile(filePath!);
                          setState(() {
                            downloadUrl = result.downloadUrl;
                            isUploading = false;
                          });
                          if (result.errorMessage != null) {
                            if (!context.mounted) return;
                            showSnack(result.errorMessage!);
                          }
                        }
                      },
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Pick and Share File'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<ui.Image> _loadOverlayImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ByteData byteData =
        await rootBundle.load('assets/images/overlay_image.png');
    ui.decodeImageFromList(byteData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }
}
