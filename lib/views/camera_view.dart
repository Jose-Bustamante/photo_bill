import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../main.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  final resolutionPreset = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;
  FlashMode? _currentFlashMode;

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

  @override
  void initState() {
    if (cameras.isNotEmpty) {
      onNewCameraSelected(cameras.first);
    }
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
                              )
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
