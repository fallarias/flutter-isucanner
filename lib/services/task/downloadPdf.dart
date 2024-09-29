import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../variables/ip_address.dart';

Future<void> downloadPdf(BuildContext context, String url, String fileName, String id) async {
  // Request external storage permission
  if (!await requestStoragePermission()) {
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String userId = prefs.getInt('userId').toString();

  if (token == null) {
    print("No authentication token found");
    return;
  }

  // Get the external storage directory (e.g., Downloads)
  Directory directory = Directory('/storage/emulated/0/Download');

  // Save QR code PDF to a separate name
  String qrCodePdfPath = '${directory.path}/$fileName-QRCode.pdf';
  String downloadedPdfPath = '${directory.path}/$fileName.pdf'; // Separate name for the downloaded PDF

  // Check if the QR code PDF already exists
  if (await File(qrCodePdfPath).exists()) {
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("QR Code PDF already exists. You cannot download it again."),
        duration: Duration(seconds: 3),
      ),
    );
    return; // Prevent duplicate download
  }

  try {
    String userDetails = jsonEncode({'userId': userId, 'taskId': id});
    // Generate QR code as image bytes
    final qrCodeImage = await generateQrCode(userDetails);

    // Create a new PDF document for the QR code
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Image(pw.MemoryImage(qrCodeImage)), // Add QR code image
                pw.SizedBox(height: 20),
                pw.Text(userDetails, style: pw.TextStyle(fontSize: 24)),
              ],
            ),
          );
        },
      ),
    );

    // Save the QR code PDF document
    final qrOutputFile = File(qrCodePdfPath);
    await qrOutputFile.writeAsBytes(await pdf.save());
    print("PDF with QR code saved to $qrCodePdfPath");

    // Proceed with downloading the actual PDF
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Save the downloaded PDF to a separate file
      final downloadedOutputFile = File(downloadedPdfPath);
      await downloadedOutputFile.writeAsBytes(response.bodyBytes);
      print("Downloaded PDF saved to $downloadedPdfPath");
    } else {
      print("Failed to download file: ${response.statusCode}");
    }
  } catch (e) {
    print("Error downloading file: $e");
  }

  await postTransaction(token, userId, id);
}



// Generate QR code as image bytes using qr_flutter
Future<Uint8List> generateQrCode(String details) async {// Concatenate qrData and userId
  final qrValidationResult = QrValidator.validate(
    data: details,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  );

  if (qrValidationResult.status == QrValidationStatus.valid) {
    final qrCode = qrValidationResult.qrCode;
    final painter = QrPainter.withQr(
      qr: qrCode!,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    // Render the QR code to an image
    final uiImage = await painter.toImage(300);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  } else {
    throw Exception("QR Code validation failed");
  }
}


Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else if (await Permission.storage.isGranted) {
      return true;
    } else {
      if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
        return true;
      } else {
        print("Storage permission denied. Please allow storage access.");
        return false;
      }
    }
  }
  return false;
}

Future<void> postTransaction(String? token, String userId, String id) async {
  try {
    final response = await http.post(
      Uri.parse('$ipaddress/transaction'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'user_id': userId,
        'task_id': id,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print('API Response: $data');
    } else {
      print('Failed to load data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Something went wrong: $e');
  }
}
