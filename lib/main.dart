import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk.dart';
import 'package:flutter_document_scan_sdk/normalized_image.dart';
import 'package:flutter_document_scan_sdk/template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final _flutterDocumentScanSdkPlugin = FlutterDocumentScanSdk();

void main() {
  runApp(const FlutterDocScanSDK());
}

class FlutterDocScanSDK extends StatelessWidget {
  const FlutterDocScanSDK({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class DocumentPage extends StatefulWidget {
  const DocumentPage(
      {super.key, required this.detectionResults, required this.file});

  final List<DocumentResult> detectionResults;
  final String file;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  ui.Image? normalizedUiImage;
  NormalizedImage? normalizedImage;
  String _pixelFormat = 'grayscale';

  @override
  void initState() {
    super.initState();
    initDocumentState();
  }

  Future<void> initDocumentState() async {
    await normalizeFile(widget.file, widget.detectionResults[0].points);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
      ),
      body: Center(
        child: Stack(children: <Widget>[
          Center(
              child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: normalizedUiImage == null
                  ? Image.asset('images/default.png')
                  : createCustomImage(normalizedUiImage!, []),
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'binary',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await _flutterDocumentScanSdkPlugin
                      .setParameters(Template.binary);

                  if (widget.detectionResults.isNotEmpty) {
                    await normalizeFile(
                        widget.file, widget.detectionResults[0].points);
                  }
                },
              ),
              const Text('Binary'),
              Radio(
                value: 'grayscale',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await _flutterDocumentScanSdkPlugin
                      .setParameters(Template.grayscale);

                  if (widget.detectionResults!.isNotEmpty) {
                    await normalizeFile(
                        widget.file, widget.detectionResults![0].points);
                  }
                },
              ),
              const Text('Gray'),
              Radio(
                value: 'color',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await _flutterDocumentScanSdkPlugin
                      .setParameters(Template.color);

                  if (widget.detectionResults!.isNotEmpty) {
                    await normalizeFile(
                        widget.file, widget.detectionResults![0].points);
                  }
                },
              ),
              const Text('Color'),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MaterialButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {
                            String fileName =
                                '${DateTime.now().millisecondsSinceEpoch}.png';
                            String? path;
                            if (kIsWeb) {
                              path = fileName;
                            } else if (Platform.isAndroid || Platform.isIOS) {
                              Directory directory =
                                  await getApplicationDocumentsDirectory();
                              path = join(directory.path, fileName);
                            } else {
                              path = await getSavePath(suggestedName: fileName);
                              path ??= fileName;
                            }

                            await _flutterDocumentScanSdkPlugin.save(path);
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Save'),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: <Widget>[
                                        Text('The image is saved to: $path')
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                            // if (normalizedUiImage != null) {
                            //   const String mimeType = 'image/png';
                            //   ByteData? data = await normalizedUiImage!
                            //       .toByteData(format: ui.ImageByteFormat.png);
                            //   if (data != null) {
                            //     final XFile imageFile = XFile.fromData(
                            //       data.buffer.asUint8List(),
                            //       mimeType: mimeType,
                            //     );
                            //     await imageFile.saveTo(path);
                            //   }
                            // }
                          },
                          child: const Text("Save Document"))
                    ]),
              ),
            ],
          )
        ]),
      ),
    );
  }

  Future<void> normalizeFile(String file, dynamic points) async {
    normalizedImage = await _flutterDocumentScanSdkPlugin.normalize(
        file, widget.detectionResults[0].points);
    if (normalizedImage != null) {
      decodeImageFromPixels(normalizedImage!.data, normalizedImage!.width,
          normalizedImage!.height, PixelFormat.rgba8888, (ui.Image img) {
        normalizedUiImage = img;
        setState(() {});
      });
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.image, this.results);
  final ui.Image image;
  final List<DocumentResult> results;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawImage(image, Offset.zero, paint);
    for (var result in results) {
      canvas.drawLine(result.points[0], result.points[1], paint);
      canvas.drawLine(result.points[1], result.points[2], paint);
      canvas.drawLine(result.points[2], result.points[3], paint);
      canvas.drawLine(result.points[3], result.points[0], paint);
    }
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) =>
      image != oldDelegate.image || results != oldDelegate.results;
}

Widget createCustomImage(ui.Image image, List<DocumentResult> results) {
  return SizedBox(
    width: image.width.toDouble(),
    height: image.height.toDouble(),
    child: CustomPaint(
      painter: ImagePainter(image, results),
    ),
  );
}

class _MyHomePageState extends State<MyHomePage> {
  String file = '';
  ui.Image? image;

  List<DocumentResult>? detectionResults = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initHomePageState();
  }

  Future<ui.Image> loadImage(XFile file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  Future<void> initHomePageState() async {
    int? ret = await _flutterDocumentScanSdkPlugin.init(
        "https://cdn.jsdelivr.net/npm/dynamsoft-document-normalizer@1.0.11/dist/",
        "DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==");
    String? params = await _flutterDocumentScanSdkPlugin.getParameters();
    print(params);

    ret = await _flutterDocumentScanSdkPlugin.setParameters(Template.grayscale);
    if (ret != 0) {
      print("setParameters failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Doc Scan Sdk'),
        ),
        body: Stack(children: <Widget>[
          Center(
            child: SingleChildScrollView(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: image == null
                  ? Image.asset('images/default.png')
                  : createCustomImage(image!, detectionResults!),
            )),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MaterialButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {
                            XFile? pickedFile;
                            if (kIsWeb ||
                                Platform.isWindows ||
                                Platform.isLinux) {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'images',
                                extensions: <String>['jpg', 'png'],
                              );
                              pickedFile = await openFile(
                                  acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                            } else if (Platform.isAndroid || Platform.isIOS) {
                              pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: MediaQuery.of(context).size.width,
                                  maxHeight:
                                      MediaQuery.of(context).size.height);
                            }

                            if (pickedFile != null) {
                              image = await loadImage(pickedFile);
                              file = pickedFile.path;
                              detectionResults =
                                  await _flutterDocumentScanSdkPlugin
                                      .detect(file);
                              setState(() {});
                              if (detectionResults!.isEmpty) {
                                print("No document detected");
                              } else {
                                setState(() {});
                                print("Document detected");
                              }
                            }
                          },
                          child: const Text('Load Document')),
                      MaterialButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {
                            if (!mounted || detectionResults!.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentPage(
                                  file: file,
                                  detectionResults: detectionResults!,
                                ),
                              ),
                            );
                          },
                          child: const Text("Rectify Document"))
                    ]),
              ),
            ],
          )
        ]),
      ),
    );
  }
}
