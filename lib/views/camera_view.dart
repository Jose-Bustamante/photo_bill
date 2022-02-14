import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'package:kactus_photo_bill/views/photo_preview_view.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? controller;
  FlashMode? _currentFlashMode;

  bool _isCameraInitialized = false;
  final resolutionPreset = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  File? _imageFile;
  List<File> allFileList = [];

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    fileList.forEach((file) {
      if (file.path.contains('jpg')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });

    if (fileNames.isNotEmpty) {
      final rencentFile = fileNames
          .reduce((current, next) => current[0] > next[0] ? current : next);

      String recentFileName = rencentFile[1];
      _imageFile = File('${directory.path}/$recentFileName');

      setState(() {});
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller if state is mounted in the tree
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A photo is being taken so do nothing
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occurred while taking picture: $e');
      return null;
    }
  }

  @override
  void initState() {
    if (cameras.isNotEmpty) {
      onNewCameraSelected(cameras.first);
    }
    refreshAlreadyCapturedImages();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
        ),
        backgroundColor: Colors.black87,
        body: _isCameraInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1 / controller!.value.aspectRatio,
                    child: Stack(
                      alignment: AlignmentDirectional.topStart,
                      children: [
                        controller!.buildPreview(),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8.0),
                                    child: DropdownButton<ResolutionPreset>(
                                      dropdownColor: Colors.black87,
                                      underline: Container(),
                                      value: currentResolutionPreset,
                                      items: [
                                        for (ResolutionPreset preset
                                            in resolutionPreset)
                                          DropdownMenuItem(
                                            child: Text(
                                              preset.toString().split('.')[1],
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            value: preset,
                                          )
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          currentResolutionPreset = value!;
                                          _isCameraInitialized = false;
                                        });
                                        onNewCameraSelected(
                                            controller!.description);
                                      },
                                      hint: Text('Select item'),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                          child: SizedBox(
                                        // empty box to fix aligment
                                        width: 60,
                                        height: 60,
                                      )),
                                      InkWell(
                                        onTap: () async {
                                          XFile? rawImage = await takePicture();
                                          File imageFile = File(rawImage!.path);
                                          int currentUnix = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          final directory =
                                              await getApplicationDocumentsDirectory();
                                          String fileFormat =
                                              imageFile.path.split('.').last;

                                          await imageFile.copy(
                                              '${directory.path}/$currentUnix.$fileFormat');

                                          refreshAlreadyCapturedImages();
                                        },
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              color: Colors.white38,
                                              size: 80,
                                            ),
                                            Icon(
                                              Icons.circle,
                                              color: Colors.white,
                                              size: 65,
                                            )
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _imageFile != null
                                            ? () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PreviewScreen(
                                                      imageFile: _imageFile!,
                                                      fileList: allFileList,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null,
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              image: _imageFile != null
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                          _imageFile!),
                                                      fit: BoxFit.fill,
                                                    )
                                                  : null),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.flash_off,
                                  color: _currentFlashMode == FlashMode.off
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                                iconSize: 24,
                                splashRadius: 24,
                                onPressed: () async {
                                  setState(() {
                                    _currentFlashMode = FlashMode.off;
                                  });
                                  await controller!.setFlashMode(FlashMode.off);
                                },
                                splashColor: Colors.white,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.flash_auto,
                                  color: _currentFlashMode == FlashMode.auto
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                                iconSize: 24,
                                splashRadius: 24,
                                onPressed: () async {
                                  setState(() {
                                    _currentFlashMode = FlashMode.auto;
                                  });
                                  await controller!
                                      .setFlashMode(FlashMode.auto);
                                },
                                splashColor: Colors.white,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.flash_on,
                                  color: _currentFlashMode == FlashMode.always
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                                iconSize: 24,
                                splashRadius: 24,
                                onPressed: () async {
                                  setState(() {
                                    _currentFlashMode = FlashMode.always;
                                  });
                                  await controller!
                                      .setFlashMode(FlashMode.always);
                                },
                                splashColor: Colors.white,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.highlight,
                                  color: _currentFlashMode == FlashMode.torch
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                                iconSize: 24,
                                splashRadius: 24,
                                onPressed: () async {
                                  setState(() {
                                    _currentFlashMode = FlashMode.torch;
                                  });
                                  await controller!
                                      .setFlashMode(FlashMode.torch);
                                },
                                splashColor: Colors.white,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
                ],
              )
            : Container());
  }
}
