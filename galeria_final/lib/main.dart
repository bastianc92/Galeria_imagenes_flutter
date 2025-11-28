import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GaleriaApp());
}

class GaleriaApp extends StatelessWidget {
  const GaleriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galería Estilo Pinterest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<File> imagenesUsuario = [];
  List<String> imagenesFirebase = [];

  final List<String> imagenesBase = [
    "assets/mis_imagenes/Gk5LdRSXcAAwuzg.jpg",
    "assets/mis_imagenes/WallpaperDog-20519439.jpg",
    "assets/mis_imagenes/WallpaperDog-20519148.jpg",
    "assets/mis_imagenes/WallpaperDog-20519099.jpg",
    "assets/mis_imagenes/wallpaperflare.com_wallpaper.jpg",
  ];

  @override
  void initState() {
    super.initState();
    cargarImagenesFirebase();
  }

  Future<void> cargarImagenesFirebase() async {
    final ref = FirebaseStorage.instance.ref("imagenes");
    final listado = await ref.listAll();
    final urls =
        await Future.wait(listado.items.map((e) => e.getDownloadURL()));
    setState(() => imagenesFirebase = urls);
  }

  @override
  Widget build(BuildContext context) {
    final todas = [
      ...imagenesBase.map((e) => ImageTile(assetPath: e)),
      ...imagenesUsuario.map((e) => ImageTile(file: e)),
      ...imagenesFirebase.map((e) => ImageTile(networkUrl: e)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Galería Pinterest"), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: todas.length,
        itemBuilder: (_, i) => todas[i],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: seleccionarImagen,
                label: Text("Galería"),
                icon: Icon(Icons.photo),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: tomarFoto,
                label: Text("Cámara"),
                icon: Icon(Icons.camera_alt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    final XFile? archivo = await _picker.pickImage(source: ImageSource.gallery);
    if (archivo != null) {
      setState(() => imagenesUsuario.add(File(archivo.path)));
    }
  }

  Future<void> tomarFoto() async {
    final XFile? archivo = await _picker.pickImage(source: ImageSource.camera);
    if (archivo != null) {
      setState(() => imagenesUsuario.add(File(archivo.path)));
    }
  }
}

class ImageTile extends StatelessWidget {
  final File? file;
  final String? assetPath;
  final String? networkUrl;

  const ImageTile({super.key, this.file, this.assetPath, this.networkUrl});

  @override
  Widget build(BuildContext context) {
    ImageProvider img;
    if (assetPath != null) {
      img = AssetImage(assetPath!);
    } else if (file != null) {
      img = FileImage(file!);
    } else {
      img = NetworkImage(networkUrl!);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreen(img: img),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image(image: img, fit: BoxFit.cover),
      ),
      onLongPress: () {
        if (file != null) {
          mostrarOpciones(context, file!);
        }
      },
    );
  }

  void mostrarOpciones(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Editar (recortar)"),
              onTap: () {
                Navigator.pop(context);
                editarImagen(context, file);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text("Compartir"),
              onTap: () async {
                Navigator.pop(context);
                await Share.shareFiles([file.path]);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text("Subir a Firebase"),
              onTap: () async {
                Navigator.pop(context);
                await subirFirebase(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> editarImagen(BuildContext context, File file) async {
    final CroppedFile? recorte = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [AndroidUiSettings(toolbarTitle: "Editar imagen")],
    );

    if (recorte != null) {
      final nuevoFile = File(recorte.path);
      await file.writeAsBytes(await nuevoFile.readAsBytes());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Imagen editada")),
      );
    }
  }

  Future<void> subirFirebase(BuildContext context, File file) async {
    try {
      final nombre = DateTime.now().millisecondsSinceEpoch.toString() + ".jpg";
      final ref = FirebaseStorage.instance.ref("imagenes/$nombre");

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Imagen subida"),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

class FullScreen extends StatelessWidget {
  final ImageProvider img;

  const FullScreen({super.key, required this.img});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(child: PhotoView(imageProvider: img)),
      ),
    );
  }
}
// fin del archivo
