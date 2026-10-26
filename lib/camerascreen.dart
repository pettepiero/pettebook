import 'dart:io';
import 'isbn_check.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pettebook/theme.dart';
import 'package:flutter/widget_previews.dart';
import 'datafetching.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bookdetailpage.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<String> scannedIsbns = [];
  bool isLookingForCode = true;

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

	@override
	void dispose() {
		controller.dispose();
		super.dispose();
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
  
  @Preview(name: "Camera screen widget")
  Widget _buildSuccessful() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, scannedIsbns);
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
        title: Text("Scanned: ${scannedIsbns.length}", style: AppTheme.h2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 80),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLookingForCode ? Colors.green : Colors.transparent,
                      width: 4
                    ),
                  ),
                  child: MobileScanner(
                    fit: BoxFit.cover,
                    controller: controller,
                    tapToFocus: true,
                    onDetect: (capture) {
                      if (!isLookingForCode) return;

                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? isbn = barcode.rawValue;
                        IsbnCheck isbnCheck = IsbnCheck();
                        if (isbn != null && 
                        (isbn.length == 10 || isbn.length == 13) && 
                        isbnCheck.isValidIsbnFormat(isbn)) {
                          setState(() {
                            isLookingForCode = false;  
                          });

                          debugPrint("Valid isbn:");
                          debugPrint(isbn);

                          _showConfirmationDialog(isbn);

                          break;
                        } 
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Finish & Return List", style: TextStyle(fontSize: 16)),
                onPressed: () {
									Navigator.push(
										context,
										MaterialPageRoute(
											builder: (context) => ListOfBooksToAddScreen(isbns: scannedIsbns),
										),
									);
                }, 
              ),
            )
          ]
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

  void _showConfirmationDialog(String isbn) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColour,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("ISBN Detected", style: AppTheme.h2, textAlign: TextAlign.center),
          content: Text(
            "ISBN: $isbn\n\nAdd this code to your list?",
            style: AppTheme.dialogContentStyle,
            textAlign: TextAlign.center
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
								setState(() => isLookingForCode = true);
              }, 
              //child: const Text("Discard", style: TextStyle(color: AppTheme.altPrimColour)),
              child: const Text("Discard"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  scannedIsbns.add(isbn);
									isLookingForCode = true;
                });
                Navigator.pop(context);
              }, 
              child: const Text("Add to List"),
            )
          ],
        );
      } ,
    );
  }
}


class ListOfBooksToAddScreen extends StatefulWidget{
	final List<String> isbns;

	const ListOfBooksToAddScreen({super.key, required this.isbns});

	@override
	State<ListOfBooksToAddScreen> createState() => _ListOfBooksToAddScreenState();
}

class _ListOfBooksToAddScreenState extends State<ListOfBooksToAddScreen> {
	late List<String> _localIsbns;
	final Map<String, String> _bookTitles = {}; //These are the ones obtained with the search button
	// bookListData will contain information of all the searched isbns when FloatingActionButton is pressed
	final Map<String, dynamic> bookListData = {}; 
	bool _isFetchingAll = false; //Used by circular progress indicator in floating action button
	bool _searchDone = false;
	Set<String> _checkedIsbns = {};
  String? _userId = "";


	@override
	void initState() {
		super.initState();
		_localIsbns = List.from(widget.isbns);
		_checkedIsbns.addAll(widget.isbns);
  	_userId = Supabase.instance.client.auth.currentUser?.id;
		if (_userId == null) {
			throw Error();
		}
	}

	void _toggleSelectAll() {
		setState(() {
			if (_checkedIsbns.length == _localIsbns.length) {
				_checkedIsbns.clear();
			} else {
				_checkedIsbns.addAll(_localIsbns);
			}
		});
	}

  @override
  Widget build(BuildContext context) {
    bool allSelected = _checkedIsbns.length == _localIsbns.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Isbns"),
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              allSelected ? "Deselect All" : "Select All",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), 
            ),
          ),
        ],
      ),
      
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _localIsbns.length,
              itemBuilder: (context, index) {
                String selectedIsbn = _localIsbns[index];
                bool isChecked = _checkedIsbns.contains(selectedIsbn);

                return CheckboxListTile(
                  title: Text(_bookTitles[selectedIsbn] ?? selectedIsbn),
                  secondary: const Icon(Icons.book),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _checkedIsbns.add(selectedIsbn);
                      } else {
                        _checkedIsbns.remove(selectedIsbn);
                      }
                    });
                  },
                );
              },
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
											onPressed: _isFetchingAll ? null : () async {
												setState(() {
													_isFetchingAll = true;
												});

												//Start populating the List with the isbns
												for (var el in _localIsbns) {
													final bookData = await olBookInfoFromISBN(el);
													if (bookData != null) {
														bookListData[el] = bookData;
														_bookTitles[el] = bookData['title'] ?? "Unknown Title";
													}
												}
												debugPrint("The bookListData is now: $bookListData");

												if (!mounted) return;
												setState(() {
													_isFetchingAll = false;
													_searchDone = true;
												});
												
												ScaffoldMessenger.of(context).showSnackBar(
													const SnackBar(content: Text("Finished fetching book data")),
												);
											},
                      child: _isFetchingAll 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Text("Fetch Info", textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12), 
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkedIsbns.isEmpty ? null : () {
												// To select shelf to add books to 
          							showModalBottomSheet(
          							  context: context, 
          							  isScrollControlled: true,
          							  shape: const RoundedRectangleBorder(
          							    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          							  ),
          							  builder: (context) {

          							    return ShelfSelectionSheet(
          							      books: bookListData.values.cast<Map<String, dynamic>>().toList(), 
          							      userId: _userId!
          							    );
          							  }
          							);
                      },
                      child: const Text("Add Selected", textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
