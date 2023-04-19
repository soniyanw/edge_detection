import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(new MaterialApp(
      home: TFlite(title: 'Tflite'),
    ));

class TFlite extends StatefulWidget {
  TFlite({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _TFliteState createState() => _TFliteState();
}

class _TFliteState extends State<TFlite> {
  late File _image;
  var labels = ['label1', 'label2', 'label3'];

  bool _loading = false;
  late List _output;

  @override
  void initState() {
    super.initState();
    _loading = true;

    // Load TFLite model
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  // Load TFLite model
  Future loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: labels.join('\n'),
    );
  }

  // Run inference on image
  Future classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
    );
    setState(() {
      _output = output!;
      String label = _output[0]['label'];
      double confidence = _output[0]['confidence'];
      int index = int.parse(label);
      String predictedLabel = labels[index];
      String prediction = '$predictedLabel (${confidence.toStringAsFixed(2)})';
    });
  }

  // Pick image from gallery
  Future pickImage() async {
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image == null
                    ? Text('No image selected.')
                    : Image.file(_image, height: 200),
                SizedBox(height: 20),
                _output != null
                    ? Text(
                        'Prediction: ${_output[0]['label']} (${_output[0]['confidence'].toStringAsFixed(2)})')
                    : Container(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.image),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
