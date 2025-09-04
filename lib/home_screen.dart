import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  late ModelObjectDetection _objectModel;
  List<ResultObjectDetection?> objDetect = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/yolov8s.pt";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
        pathObjectDetectionModel,
        80,
        640,
        640,
        labelPath: "assets/labels/labels.txt",
      );
    } catch (e) {
      if (e is PlatformException) {
        print("Only supported for Android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  Future runObjectDetection() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
    );
    objDetect = await _objectModel.getImagePrediction(
      await File(image!.path).readAsBytes(),
      minimumScore: 0.1,
      IOUThershold: 0.3,
    );
    objDetect.forEach((element) {
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });
    setState(() {
      _image = File(image!.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OBJECT DETECTOR APP"),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 150,
                width: 300,
                child: objDetect.isNotEmpty
                    ? _image == null
                        ? Text('No image selected.')
                        : _objectModel!.renderBoxesOnImage(_image!, objDetect)
                    : _image == null
                        ? Text('No image selected.')
                        : Image.file(_image!),
              ),
            ),
            Center(
              child: Visibility(
                visible: _image != null,
                child: Text("$_imagePrediction"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                runObjectDetection();
              },
              child: const Icon(Icons.camera),
            )
          ],
        ),
      ),
    );
  }
}
