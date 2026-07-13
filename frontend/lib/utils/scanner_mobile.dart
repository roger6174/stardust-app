import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'scanner_interface.dart';

class MobileDocumentScanner implements DocumentScanner {
  @override
  Future<XFile?> scanDocument(String type) async {
    try {
      final List<String>? imagesPath = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: false,
      );

      if (imagesPath != null && imagesPath.isNotEmpty) {
        return XFile(imagesPath.first);
      }
    } catch (e) {
      throw 'Document Scanner Error: $e';
    }
    return null;
  }
}

DocumentScanner getScanner() => MobileDocumentScanner();
