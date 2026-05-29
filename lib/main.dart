import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';

import 'api_service.dart';

import 'dart:io';
String loggedInUsername = "";
List<String> assignedBatchNumbers = [];

void main() {

  runApp(

    MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),

      home: LoginPage(),
    ),
  );
}

class LoginPage extends StatefulWidget {

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController
      usernameController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  bool loading = false;

  final String serverIp =
      "http://104.154.76.47:5001";

  Future<void> login() async {

  setState(() {
    loading = true;
  });

  try {

    final response =
        await ApiService()
            .dio
            .post(

      "/api/login",

      data: {
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
      },

      options: Options(
       headers: {
           "Content-Type": "application/json",
      },
     ),
      
    );

    print(
      "LOGIN STATUS: ${response.statusCode}",
    );

    print(
      "LOGIN RESPONSE: ${response.data}",
    );

    if (response.statusCode == 200) {

      loggedInUsername =
          response.data["username"];
          assignedBatchNumbers =
              List<String>.from(
                 response.data["batch_numbers"] ?? []
              );
      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
            PCBInspectorApp(),
        ),
      );
    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
              Text("Login Failed"),
        ),
      );
    }

  } catch (e) {

    print("LOGIN ERROR: $e");

    if (e is DioException) {

      print(
        "STATUS CODE: ${e.response?.statusCode}",
      );

      print(
        "RESPONSE: ${e.response?.data}",
      );

      print(
        "HEADERS: ${e.response?.headers}",
      );
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(
          e.toString(),
        ),
      ),
    );
  }

  setState(() {
    loading = false;
  });
}

  @override
  void dispose() {

    usernameController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text("AOI Login"),

        backgroundColor:
            Colors.indigo,

        foregroundColor:
            Colors.white,
      ),

      body: Padding(

        padding:
            EdgeInsets.all(20),

        child: Column(

          children: [

            SizedBox(height: 50),

            TextField(

              controller:
                  usernameController,

              decoration:
                  InputDecoration(

                labelText:
                    "Username",

                border:
                    OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            TextField(

              controller:
                  passwordController,

              obscureText: true,

              decoration:
                  InputDecoration(

                labelText:
                    "Password",

                border:
                    OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    loading
                        ? null
                        : login,

                style:
                    ElevatedButton
                        .styleFrom(

                  backgroundColor:
                      Colors.indigo,

                  foregroundColor:
                      Colors.white,

                  padding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),

                child: Text(

                  loading
                      ? "Please Wait..."
                      : "LOGIN",
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PCBInspectorApp
    extends StatefulWidget {

  @override
  State<PCBInspectorApp>
      createState() =>
          _PCBInspectorAppState();
}

class _PCBInspectorAppState
    extends State<PCBInspectorApp> {

  File? _image;

  String? _selectedProject;

  List<String>
      _existingProjects = [];
  
  List<String> _assignedBatches = [];
  
  String _batchNumber = "B01";

  String _status = "Ready";

  String? _reportUrl;

  String _selectedMode =
      'presence';

  String _selectedSide =
      'top';

  final TextEditingController
      _projectController =
      TextEditingController();

  final TextEditingController
      _batchController =
      TextEditingController();

  final String serverIp =
      "http://104.154.76.47:5001";

  @override
  void initState() {

    super.initState();

    if (assignedBatchNumbers.isNotEmpty) {

       _batchNumber =
            assignedBatchNumbers.first;

       _batchController.text =
            _batchNumber;
    }

    _fetchProjects();
  }

  Future<void>
      _fetchProjects() async {

    try {

      final response =
          await ApiService()
              .dio
              .get(
        "/get_projects",
      );

      print(response.data);

      setState(() {

        _existingProjects =
            List<String>.from(
          response.data['projects'],
        );
      });

    } catch (e) {

      print(e);

      setState(() {

        _status =
            "Server Connection Failed";
      });
    }
  }

  Future<void>
      _captureAndInspect() async {

    if (_projectController.text
        .trim()
        .isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "Enter Project Name",
          ),
        ),
      );

      return;
    }

    final picker = ImagePicker();

    final pickedFile =
        await picker.pickImage(

      source: ImageSource.camera,

      imageQuality: 60,

      maxWidth: 1920,

      maxHeight: 1920,
    );

    if (pickedFile == null) {
      return;
    }

    print(
      "Picked Image: ${pickedFile.path}",
    );
    
CroppedFile? croppedFile =
    await ImageCropper().cropImage(

  sourcePath: pickedFile.path,

  compressQuality: 90,

  uiSettings: [

    AndroidUiSettings(

      toolbarTitle: 'Align PCB',

      toolbarColor:
          Colors.indigo,

      toolbarWidgetColor:
          Colors.white,

      lockAspectRatio: false,

      hideBottomControls:
          false,

      aspectRatioPresets: [

        CropAspectRatioPreset.original,

        CropAspectRatioPreset.ratio4x3,

        CropAspectRatioPreset.square,
      ],

      initAspectRatio:
          CropAspectRatioPreset
              .original,
    ),

    IOSUiSettings(

      title: 'Align PCB',

      aspectRatioPresets: [

        CropAspectRatioPreset.original,

        CropAspectRatioPreset.ratio4x3,

        CropAspectRatioPreset.square,
      ],
    ),
  ],
);



    print(
      "Crop Result: ${croppedFile?.path}",
    );

    if (croppedFile == null) {

      setState(() {

        _status =
            "Cropping Cancelled";
      });

      return;
    }

    setState(() {

      _image =
          File(croppedFile.path);

      _status =
          "Inspecting PCB...";

      _reportUrl = null;
    });

    try {

      FormData formData =
          FormData.fromMap({

        "project_name":
            _projectController.text
                .trim(),

        "batch_number":
            _batchNumber,

        "inspection_type":
            _selectedMode,

        "selected_side":
            _selectedSide,

        "qc_stage":
            "smt",

        "username": loggedInUsername,

        "image":
            await MultipartFile
                .fromFile(

          _image!.path,
        ),
      });

      final response =
          await ApiService()
              .dio
              .post(

        "/inspect",

        data: formData,
      );

      print(response.data);

      if (response.statusCode ==
          200) {
                
        var data =
            response.data;

        setState(() {

          _status =
              data['status'] ??
                  "Inspection Complete";

          if (data[
                  'batch_number'] !=
              null) {

            _batchNumber =
                data['batch_number'];

            _batchController.text =
                _batchNumber;
          }

          if (data['report_url'] !=
              null) {

            _reportUrl =
                data['report_url'] +
                "?t=${DateTime.now().millisecondsSinceEpoch}";
          }
        });

      } else {

        setState(() {

          _status =
              "Server Error";
        });
      }

    } catch (e) {

      print(e);

      setState(() {

        _status =
            "Connection Failed";
      });
    }
  }

  @override
  void dispose() {

    _projectController.dispose();

    _batchController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(
          "Mishon AoI",
        ),

        backgroundColor:
            Colors.indigo,

        foregroundColor:
            Colors.white,
      ),

      body: Padding(

        padding:
            EdgeInsets.all(16),

        child:
            SingleChildScrollView(

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [

              TextField(

                controller:
                    _projectController,

                decoration:
                    InputDecoration(

                  labelText:
                      "Project Name",

                  border:
                      OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 12),

              DropdownButtonFormField<
                  String>(

                decoration:
                    InputDecoration(

                  border:
                      OutlineInputBorder(),

                  labelText:
                      "Select Existing Project",
                ),

                value: _selectedProject,

                items:
                    _existingProjects
                        .map((e) {

                  return DropdownMenuItem(

                    value: e,

                    child: Text(e),
                  );
                }).toList(),

                onChanged: (val) {

                  setState(() {

                    _selectedProject =
                        val;

                    _projectController
                        .text = val!;
                  });
                },
              ),

              SizedBox(height: 12),

              Row(

                children: [

                  Expanded(

                    child:
                        DropdownButtonFormField<
                            String>(

                      value:
                          _selectedMode,

                      decoration:
                          InputDecoration(

                        labelText:
                            "Inspection",

                        border:
                            OutlineInputBorder(),
                      ),

                      items: [

                        "presence",

                        "soldering"

                      ].map((e) {

                        return DropdownMenuItem(

                          value: e,

                          child:
                              Text(e),
                        );
                      }).toList(),

                      onChanged:
                          (val) {

                        setState(() {

                          _selectedMode =
                              val!;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 10),

                  Expanded(

                    child:
                        DropdownButtonFormField<
                            String>(

                      value:
                          _selectedSide,

                      decoration:
                          InputDecoration(

                        labelText:
                            "PCB Side",

                        border:
                            OutlineInputBorder(),
                      ),

                      items: [

                        "top",

                        "bottom"

                      ].map((e) {

                        return DropdownMenuItem(

                          value: e,

                          child:
                              Text(e),
                        );
                      }).toList(),

                      onChanged:
                          (val) {

                        setState(() {

                          _selectedSide =
                              val!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              TextField(

                controller:
                    _batchController,

                decoration:
                    InputDecoration(

                  labelText:
                      "Batch Number",

                  border:
                      OutlineInputBorder(),
                ),

                onChanged: (val) {

                  _batchNumber =
                      val;
                },
              ),

              SizedBox(height: 25),

              ElevatedButton.icon(

                onPressed:
                    _captureAndInspect,

                icon:
                    Icon(Icons.camera),

                label:
                    Text("CAPTURE & INSPECT"),

                style:
                    ElevatedButton
                        .styleFrom(

                  backgroundColor:
                      Colors.indigo,

                  foregroundColor:
                      Colors.white,

                  padding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),

              SizedBox(height: 25),

              Text(

                "Status: $_status",

                textAlign:
                    TextAlign.center,

                style: TextStyle(

                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              if (_reportUrl != null)

                Container(

                  height: 450,

                  child: ClipRRect(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    child: Image.network(

                      _reportUrl!,

                      fit: BoxFit.contain,

                      width: double.infinity,
                    ),
                  ),
                )

              else if (_image != null)

                Container(

                  height: 450,

                  child: ClipRRect(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    child: Image.file(

                      _image!,

                      fit: BoxFit.contain,

                      width: double.infinity,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
