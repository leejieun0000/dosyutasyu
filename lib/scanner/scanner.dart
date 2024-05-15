import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'QRscannerOverlay.dart';
import 'foundScreen.dart';

class Scanner extends StatefulWidget {
  const Scanner({Key? key}) : super(key: key);

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  MobileScannerController  cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  void initState() {
    // TODO: implement initState
    this._screenWasClosed();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        appBar: AppBar(
          backgroundColor: Color(0xFFBF30),
          title: Text("Scanner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          elevation: 0.0,
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: _foundBarcode,
            ),
            QRScannerOverlay(overlayColour: Colors.black.withOpacity(0.5))
          ],
        )
    );
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    for (final barcode in barcodes) {
      print(barcode.rawValue);
      if (!_screenOpened) {
        final String code = barcode.rawValue ?? "___";
        _screenOpened = true; // 스크린이 열릴 때 상태 변경
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoundScreen(
              value: code,
              screenClose: _screenWasClosed,
            ),
          ),
        ).then((value) {
          _screenWasClosed(); // 화면이 닫힐 때 상태 초기화
        });
        break; // 하나의 바코드만 처리하고 루프 종료
      }
    }
  }


  void _screenWasClosed(){
    _screenOpened = false;
  }
}
