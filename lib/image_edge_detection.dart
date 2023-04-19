import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_edge_detection/functions.dart' as det;
import 'package:image_picker/image_picker.dart';

void main() async {
  final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
  final image = File(pickedFile!.path);
  final result = await det.applySobelOnFile(image);
  image.writeAsBytes(img.encodePng(result));
}
