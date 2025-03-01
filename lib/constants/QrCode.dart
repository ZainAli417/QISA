import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrShareWidget extends StatefulWidget {
  final String meetingId;
  final String hostedBy;
  const QrShareWidget({Key? key, required this.meetingId,required this.hostedBy}) : super(key: key);

  @override
  _QrShareWidgetState createState() => _QrShareWidgetState();
}

class _QrShareWidgetState extends State<QrShareWidget> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQrCode() async {
    try {
      // Capture the QR code widget as an image.
      RenderRepaintBoundary boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image to a temporary file.
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      // Share the PNG file.
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Meeting Code for QISA \n Meeting ID: ${widget.meetingId} \n Hosted by ${widget.hostedBy} ',
      );
    } catch (e) {
      print('Error sharing QR Code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Wrap the QR code widget with a RepaintBoundary for capture.
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            color: Colors.white, // Ensures a non-transparent background
            child: QrImageView(
              data: widget.meetingId,
              size: 70.0,
            ),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          label: Text(
            'Share To Socials',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            _shareQrCode;
          },
        ),

      ],
    );
  }
}
