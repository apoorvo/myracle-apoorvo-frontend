import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final dio = Dio();
final log = Logger('add_model.myracleio');

class AddModel extends StatefulWidget {
  const AddModel({super.key, required this.baseApiUrl});

  final String baseApiUrl;

  @override
  State<AddModel> createState() => _AddModelState();
}

class _AddModelState extends State<AddModel> {
  String modelName = "";
  String modelDescription = "";

  List<int> modelBytes = [];
  String? modelFileName;
  String errorMsg = "";
  bool submitting = false;

  _selectFile(Function cb) async {
    const allowedFileExtensions = ['glb', 'gltf', 'fbx'];
    String newErrorMsg =
        "File should have the extenstion: ${allowedFileExtensions.toString()}";
    bool hasError = false;
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (kIsWeb) {
      PlatformFile? file = result?.files.first;
      if (allowedFileExtensions.contains(file!.extension)) {
        setState(() {
          modelBytes = file!.bytes!;
          modelFileName = file.name;
        });
      } else {
        hasError = true;
      }
    } else {
      String? path = result?.files.single.path;

      if (path != null) {
        File file = File(path);
        String extension = path.split("/").last.split(".").last;

        if (allowedFileExtensions.contains(extension)) {
          Uint8List bytes = await file.readAsBytes();

          setState(() {
            modelBytes = bytes;
            modelFileName = result?.files.single.name;
          });
        } else {
          hasError = true;
        }
      }
    }

    if (hasError) {
      setState(() {
        errorMsg = newErrorMsg;
      });
      cb(newErrorMsg);
    }
  }

  _validateForm() {
    if (modelName == "" || modelName.isEmpty) {
      setState(() {
        errorMsg = "Model name can't be empty";
      });
      return false;
    }
    if (modelBytes.isEmpty || modelFileName == null) {
      setState(() {
        errorMsg = "File not selected";
      });
      return false;
    }

    return true;
  }

  uploadFormData() async {
    FormData formData = FormData.fromMap({
      "modelFile": MultipartFile.fromBytes(modelBytes, filename: modelFileName),
      "name": modelName,
      "description": modelDescription,
    });

    Response<Map> response = await dio.post(widget.baseApiUrl, data: formData);
  }

  handleSubmit() async {
    await uploadFormData();
    context.go("/models");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null) {
                          return "Name is required";
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {
                        modelName = value;
                      }),
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          border: OutlineInputBorder(),
                          labelText: 'Enter Model Name',
                          hintText: 'Model Name'),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      onChanged: (value) => setState(() {
                        modelDescription = value;
                      }),
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          border: OutlineInputBorder(),
                          labelText: 'Enter Model Description',
                          hintText: 'Model Description'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                            mouseCursor: MaterialStateMouseCursor.clickable,
                            onPressed: () {
                              _selectFile((String errorMessage) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        width: 320,
                                        backgroundColor: Colors.red,
                                        content: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )));
                              });
                            },
                            icon: const Icon(Icons.upload_file)),
                        Text(modelFileName ?? ""),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_validateForm() && !submitting) {
                          setState(() {
                            submitting = true;
                          });
                          handleSubmit();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 320,
                              backgroundColor: Colors.red,
                              content: Text(
                                errorMsg,
                                style: const TextStyle(color: Colors.white),
                              )));
                        }
                      },
                      child: submitting
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ))
                          : const Text("Add Model"),
                    ),
                  ])),
        ),
      ),
    );
  }
}
