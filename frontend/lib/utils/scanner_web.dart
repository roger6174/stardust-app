import 'package:image_picker/image_picker.dart';
import 'scanner_interface.dart';

class WebDocumentScanner implements DocumentScanner {
  @override
  Future<XFile?> scanDocument(String type) async {
    // The web doesn't support the native document scanner plugin.
    // It should fallback to standard camera via ImagePicker.
    return null; 
  }
}

DocumentScanner getScanner() => WebDocumentScanner();
