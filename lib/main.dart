import 'package:client/views/add_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:client/views/model_display.dart';
import 'package:client/models/model_3d.dart';

final dio = Dio();

// Uncomment the below lines if running on local
// const baseApiUrl =
// kIsWeb ? "http://localhost:3000/models/" : "http://10.0.2.2:3000/models/";

// Comment the below lines if running on local
const baseApiUrl = "https://myracleio-apoorvo-backend.onrender.com/models/";

final log = Logger('MiracleIO');

final _router = GoRouter(
  routes: [
    ShellRoute(
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) {
            return "/models";
          },
        ),
        GoRoute(
          path: '/models',
          builder: (context, state) => const MyHomePage(title: "Home"),
        ),
        GoRoute(
          path: '/models/add',
          builder: (context, state) => const AddModel(baseApiUrl: baseApiUrl),
        ),
        GoRoute(
          path: '/models/:modelId',
          builder: (context, state) => ModelDisplay(
              modelId: state.params['modelId'] as String,
              baseApiUrl: baseApiUrl),
        ),
      ],
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
              title: InkWell(
                  onTap: () {
                    context.go("/");
                  },
                  child: const Text("MyracleIO"))),
          body: child,
        );
      },
    )
  ],
);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: "Myracle IO",
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromRGBO(8, 10, 31, 1),
        primary: const Color.fromRGBO(8, 10, 31, 1),
      )),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Model3D>> models;

  @override
  void initState() {
    super.initState();
    models = fetchModels();
  }

  Future<List<Model3D>> fetchModels() async {
    List<Model3D> modelsList = [];
    try {
      log.fine("Fetching models from $baseApiUrl");

      final response = await dio.get(baseApiUrl);
      if (response.data['models'] != null) {
        var modelsJson = response.data['models'];

        for (int i = 0; i < modelsJson?.length; i++) {
          Model3D model = Model3D.fromJson(modelsJson[i]);
          final gsReference = FirebaseStorage.instance.refFromURL(model.url);
          final downloadUrl = await gsReference.getDownloadURL();
          model.downloadUrl = downloadUrl;
          modelsList.add(model);
        }
      }
    } on Exception catch (e, stackTrace) {
      log.severe("Error fetching models.", e, stackTrace);
    }
    log.fine("Fetched ${modelsList.length} models");
    return modelsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: models,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
                    child: Text(
                      "No models uploaded.\n Click the + button to upload your models.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return GridView.builder(
                itemCount: snapshot.data?.length,
                itemBuilder: (context, index) {
                  return Card(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Expanded(
                            child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ModelViewer(
                              src: snapshot.data?[index].downloadUrl as String,
                              cameraControls: false,
                              autoRotate: true,
                            ),
                            Positioned(
                                right: 20,
                                child: IconButton(
                                    onPressed: () {
                                      context.go(
                                          '/models/${snapshot.data?[index].id}');
                                    },
                                    icon: const Icon(Icons.fullscreen)))
                          ],
                        )),
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 12.0),
                            child: Text(
                              snapshot.data?[index].name as String,
                              style: const TextStyle(
                                fontSize: 20.0,
                              ),
                            )),
                      ]));
                },
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                    mainAxisExtent: 300),
              );
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go("/models/add"),
        child: const Icon(Icons.add),
      ),
    );
  }
}
