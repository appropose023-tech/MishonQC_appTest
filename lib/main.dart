import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

import 'dart:io';
import 'dart:convert';

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

    "username":
        usernameController.text,

    "password":
        passwordController.text
  },
);

print(response.data);

if (response.statusCode == 200) {

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

  final String serverIp =
      "http://104.154.76.47:5001";

  @override
  void initState() {

    super.initState();

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

    final picker =
        ImagePicker();

    final pickedFile =
        await picker.pickImage(

      source:
          ImageSource.camera,

      imageQuality: 90,
    );

    if (pickedFile == null) {
      return;
    }

    CroppedFile? croppedFile =
        await ImageCropper()
            .cropImage(

      sourcePath:
          pickedFile.path,

      uiSettings: [

        AndroidUiSettings(

          toolbarTitle:
              'Align PCB',

          toolbarColor:
              Colors.indigo,

          toolbarWidgetColor:
              Colors.white,
        ),

        IOSUiSettings(
          title: 'Align PCB',
        ),
      ],
    );

    if (croppedFile == null) {
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

if (response.statusCode == 200) {

  var data = response.data;

  setState(() {

    _status =
        data['status'];

    _reportUrl =
        serverIp +
            data['report_url'] +
            "?t=${DateTime.now().millisecondsSinceEpoch}";
  });
}
        streamedResponse,
      );

      if (response.statusCode ==
          200) {

        var data = json.decode(
          response.body,
        );

        setState(() {

          _status =
              data['status'];

          _reportUrl =
              serverIp +
                  data[
                      'report_url'] +
                  "?t=${DateTime.now().millisecondsSinceEpoch}";
        });

      } else {

        setState(() {

          _status =
              "Server Error";
        });
      }

    } catch (e) {

      setState(() {

        _status =
            "Connection Failed";
      });
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(
          "QC AI Inspector",
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

              if (_reportUrl !=
                  null)

                ClipRRect(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  child:
                      Image.network(
                    _reportUrl!,
                  ),
                )

              else if (_image !=
                  null)

                ClipRRect(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  child: Image.file(
                    _image!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
