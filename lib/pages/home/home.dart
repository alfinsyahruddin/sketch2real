import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sketch2real/pages/home/components/painter.dart';
import 'package:sketch2real/types/point.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sketch2real/utils/utils.dart';

const BASE_URL = 'http://192.168.43.205:9999';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final picker = ImagePicker();

  List<Point> points = [];
  File imageInput = null;
  String imageOutput = null;
  bool isLoading = false;
  bool finished = false;

  void draw(details) {
    this.setState(() {
      points.add(
        Point(
          point: details.localPosition,
          areaPaint: Paint()
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..color = Colors.grey[400]
            ..strokeWidth = 2.5,
        ),
      );
    });
  }

  void endDraw(details) {
    this.setState(() {
      points.add(null);
    });
  }

  void processSketch() async {
    setState(() {
      isLoading = true;
    });
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset(0, 0),
        Offset(200, 200),
      ),
    );

    final paintBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    Paint paintSketch = Paint()
      ..color = Colors.grey[400]
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, 256, 256),
      paintBackground,
    );

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i].point,
          points[i + 1].point,
          paintSketch,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final listBytes = Uint8List.view(pngBytes.buffer);

    File file = await writeBytes(listBytes);

    setState(() {
      imageInput = file;
    });
    fetchResponse();
  }

  void pickImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);

    if (image == null) {
      return null;
    } else {
      setState(() {
        isLoading = true;
        imageInput = File(image.path);
      });
      fetchResponse();
    }
  }

  void save() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset(0, 0),
        Offset(200, 200),
      ),
    );

    final paintBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    Paint paintSketch = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, 256, 256),
      paintBackground,
    );

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i].point,
          points[i + 1].point,
          paintSketch,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (await Permission.storage.request().isGranted) {
      String path = '/storage/emulated/0/Download';
      await Directory('$path/').create(recursive: true);
      File('$path/${getFileName()}.png')
          .writeAsBytesSync(pngBytes.buffer.asInt8List());

      Fluttertoast.showToast(
        msg: "Image saved!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black.withOpacity(0.5),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Failed to save image, permission denied!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black.withOpacity(0.5),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/${getFileName()}.png');
  }

  Future<File> writeBytes(listBytes) async {
    final file = await _localFile;
    return file.writeAsBytes(listBytes, flush: true);
  }

  void fetchResponse() async {
    final mimeTypeData = lookupMimeType(
      imageInput.path,
      headerBytes: [0xFF, 0xD8],
    ).split('/');

    final imageUploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('$BASE_URL/generate'),
    );

    final file = await http.MultipartFile.fromPath(
      'image',
      imageInput.path,
      contentType: MediaType(
        mimeTypeData[0],
        mimeTypeData[1],
      ),
    );

    imageUploadRequest.fields['ext'] = mimeTypeData[1];
    imageUploadRequest.files.add(file);

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> responseData = json.decode(response.body);
      String outputFile = responseData['result'];

      setState(() {
        String url = '$BASE_URL/download/$outputFile';
        imageOutput = url;
      });

      this.setState(() {
        finished = true;
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void backToSketch() {
    setState(() {
      finished = false;
      imageInput = null;
      imageOutput = null;
    });
  }

  void saveImageOutput() async {
    Fluttertoast.showToast(
      msg: "Saving Image...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black.withOpacity(0.5),
      textColor: Colors.white,
      fontSize: 16.0,
    );

    var imageId = await ImageDownloader.downloadImage(
      imageOutput,
      destination: AndroidDestinationType.custom(
        inPublicDir: true,
        directory: 'Download',
      ),
    );

    if (imageId == null) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        color: const Color(0xFFFF99A5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              height: 100,
            ),
            SizedBox(height: 15),
            Text(
              'Sketch2Real',
              style: TextStyle(
                color: const Color(0xFFFBFF48),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Generative Adversarial Network',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 25),
            Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    spreadRadius: 0.3,
                    offset: Offset(0, 8),
                    color: const Color(0xFFFF0000).withOpacity(0.20),
                  ),
                ],
              ),
              child: finished == false
                  ? GestureDetector(
                      onPanDown: draw,
                      onPanUpdate: draw,
                      onPanEnd: endDraw,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(
                          painter: Painter(
                            points: points,
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageOutput,
                              width: 256,
                              height: 256,
                            ),
                          ),
                          SizedBox(
                            width: 15,
                            height: 15,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              imageInput,
                              width: 256,
                              height: 256,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            SizedBox(
              height: 20,
            ),
            finished == false
                ? Container(
                    width: 175,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12.0,
                          spreadRadius: 0.3,
                          offset: Offset(0, 8),
                          color: const Color(0xFFFF0000).withOpacity(0.20),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          color: Colors.grey,
                          icon: Icon(Icons.clear),
                          splashColor: Colors.black,
                          onPressed: () {
                            this.setState(() {
                              points.clear();
                            });
                          },
                        ),
                        IconButton(
                          color: Colors.grey,
                          icon: Icon(Icons.camera_alt_outlined),
                          splashColor: Colors.black,
                          onPressed: pickImage,
                        ),
                        IconButton(
                          color: Colors.grey,
                          icon: Icon(Icons.save_alt_outlined),
                          splashColor: Colors.black,
                          onPressed: save,
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: 256,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12.0,
                          spreadRadius: 0.3,
                          offset: Offset(0, 8),
                          color: const Color(0xFFFF0000).withOpacity(0.20),
                        ),
                      ],
                    ),
                    child: RaisedButton(
                      padding: EdgeInsets.all(12),
                      elevation: 0,
                      highlightElevation: 0,
                      color: const Color(0xFFFBFF48),
                      highlightColor: const Color(0xFFFBFF48),
                      splashColor: Colors.white.withAlpha(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      onPressed: saveImageOutput,
                      child: Text(
                        'Save Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB648),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFB648),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Color(0xFFFBFF48),
                        width: 5,
                      ),
                    ),
                    child: IconButton(
                      splashColor: Colors.white,
                      onPressed:
                          finished == false ? processSketch : backToSketch,
                      color: Color(0xFFFBFF48),
                      icon: Icon(
                        finished ? Icons.arrow_back : Icons.arrow_forward,
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
