import 'dart:io';
import 'isbn_check.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pettebook/theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? lastScan;
  String? thisScan;
  static bool isScanning = false;

  MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    detectionTimeoutMs: 1000,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String hasCameraPermission = "loading";

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {

    // 1. Skip permission check on Web or Desktop platforms
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      setState(() => hasCameraPermission = 'unsupported');
      return;
    }

    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (status.isGranted) {
      setState(() => hasCameraPermission = 'true');
    } else {
      setState(() => hasCameraPermission = 'false');
    }
  }

  @override
  Widget build(BuildContext context){
    switch (hasCameraPermission){
      case 'true':
        return _buildSuccessful();
      case 'false':
        return _buildFailed();
      case 'unsupported':
        return _buildUnsupported();
      case 'loading':
        default:
          return Scaffold(backgroundColor: AppTheme.backgroundColour);
    }
  }
  
  Widget _buildSuccessful() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 80),
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: MobileScanner(
                    fit: BoxFit.cover,
                    controller: controller,
                    onDetect: (capture) {
                      if (isScanning) {
                        return;
                      }
                      if (kDebugMode) {
                        print("Scanning");
                      }
                      isScanning = true;

                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? isbn = barcode.rawValue;
                        IsbnCheck isbnCheck = IsbnCheck();
                        if (isbn != null && 
                        (isbn.length == 10 || isbn.length == 13) && 
                        isbnCheck.isValidIsbnFormat(isbn)) {
                          debugPrint("Valid isbn:");
                          debugPrint(isbn);
                          return;
                        } 
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Text(
                  "Scan an ISBN Barcode",
                  style: AppTheme.h2,
                ),
              )
            ]
          )
        )
      )
    );
  }

  Widget _buildFailed() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.info,
              color: AppTheme.altPrimColour,
              size: 64,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Text(
                "Permission to use the camera is required for this function.",
                textAlign: TextAlign.center,
                style: AppTheme.dialogContentStyle,
              ),
            ),
          ],
        ),
      )
    );
  }
  Widget _buildUnsupported() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.desktop_access_disabled,
              color: AppTheme.altPrimColour,
              size: 64,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Text(
                "Camera scanning is not supported on this desktop platform.",
                textAlign: TextAlign.center,
                style: AppTheme
                    .dialogContentStyle, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}