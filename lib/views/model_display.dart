import 'package:client/models/model_3d.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

final dio = Dio();
final log = Logger('model_display.myracleio');

class ModelDisplay extends StatefulWidget {
  const ModelDisplay(
      {super.key, required this.modelId, required this.baseApiUrl});

  final String modelId;
  final String baseApiUrl;

  @override
  State<ModelDisplay> createState() => _ModelDisplayState();
}

class _ModelDisplayState extends State<ModelDisplay> {
  late Future<Model3D?> futureModel;
  bool showDetails = false;

  @override
  void initState() {
    super.initState();
    futureModel = fetchModel();
  }

  Future<Model3D?> fetchModel() async {
    Model3D? model;
    try {
      final String requestUrl = "${widget.baseApiUrl}${widget.modelId}/";
      final response = await dio.get(requestUrl);
      model = Model3D.fromJson(response.data['model']);
      final gsReference = FirebaseStorage.instance.refFromURL(model.url);

      final downloadUrl = await gsReference.getDownloadURL();

      model.downloadUrl = downloadUrl;
    } on Exception catch (e, stacktrace) {
      log.severe("Error fetching model.", e, stacktrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 320,
          backgroundColor: Colors.red,
          content: Text(
            "Error fetching model",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return model;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureModel,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data != null) {
            Model3D model = snapshot.data as Model3D;
            return Scaffold(
              body: ModelViewer(
                src: model.downloadUrl,
                alt: model.description,
                autoRotate: true,
                cameraControls: true,
              ),
              bottomNavigationBar: SizedBox(
                width: 60,
                child: ExpansionTile(
                  collapsedIconColor: Colors.white,
                  iconColor: Colors.white,
                  textColor: const Color.fromRGBO(255, 255, 255, 1),
                  collapsedBackgroundColor:
                      Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  collapsedTextColor: const Color.fromRGBO(255, 255, 255, 1),
                  title: Text(
                    "Model Name:   ${model.name}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  children: [
                    ListTile(
                      tileColor: Theme.of(context).splashColor,
                      title: Text(
                        model.description,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
