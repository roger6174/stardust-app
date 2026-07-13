import 'package:image_picker/image_picker.dart';

abstract class DocumentScanner {
  Future<XFile?> scanDocument(String type);
}

DocumentScanner getScanner() => throw UnsupportedError('Cannot create a scanner without platform implementation');
