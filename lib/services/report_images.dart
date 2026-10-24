import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../design/borgona_theme.dart';

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Image bytes stay in Cloudinary; Firestore stores only the returned metadata.
class ReportImageService {
  ReportImageService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<String, Map<String, String>> _uploaded = {};
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'izwqrc3a',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'reportes_unsigned',
  );

  Future<Map<String, String>> upload({
    required XFile photo,
    required String folder,
    required String filePrefix,
    required String userId,
  }) async {
    final bytes = await photo.readAsBytes();
    if (bytes.isEmpty) {
      throw const PhotoUploadException(
        'La foto está vacía. Selecciona otra imagen.',
      );
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const PhotoUploadException(
        'La foto supera los 10 MB. Elige una imagen más pequeña.',
      );
    }
    // Retrying a failed Firestore save must not upload the same bytes again.
    final cacheKey = '$userId:${photo.path}:${Object.hashAll(bytes)}';
    final cached = _uploaded[cacheKey];
    if (cached != null) return Map.of(cached);
    final extension = photo.name.contains('.')
        ? photo.name.split('.').last.toLowerCase()
        : 'jpg';
    final cleanFolder = 'reportes/$folder/$userId'
        .split('/')
        .map((segment) => segment.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_'))
        .join('/');
    final prefix = filePrefix.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
          )
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = cleanFolder
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename:
                  '${prefix}_${DateTime.now().microsecondsSinceEpoch}.$extension',
            ),
          );
    try {
      final stream = await _client
          .send(request)
          .timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(
        stream,
      ).timeout(const Duration(seconds: 40));
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw const PhotoUploadException(
          'El servicio de fotos no respondió correctamente. Vuelve a intentar.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map && data['error'] is Map
            ? data['error']['message']?.toString() ?? ''
            : '';
        if (detail.toLowerCase().contains('preset')) {
          throw const PhotoUploadException(
            'El servicio de fotos necesita configurar el permiso de carga. Contacta al superior.',
          );
        }
        throw const PhotoUploadException(
          'No se pudo subir la foto al servicio de imágenes. Vuelve a intentar.',
        );
      }
      final url = data is Map ? (data['secure_url'] ?? '').toString() : '';
      final publicId = data is Map ? (data['public_id'] ?? '').toString() : '';
      if (Uri.tryParse(url)?.scheme != 'https' || publicId.isEmpty) {
        throw const PhotoUploadException(
          'El servicio de fotos no devolvió una imagen válida. Vuelve a intentar.',
        );
      }
      final result = {
        'url': reportPhotoUrl(url),
        'originalUrl': url,
        'path': publicId,
        'provider': 'cloudinary',
        'publicId': publicId,
        'assetId': (data['asset_id'] ?? '').toString(),
      };
      _uploaded[cacheKey] = result;
      return Map.of(result);
    } on TimeoutException {
      throw const PhotoUploadException(
        'La carga tardó demasiado. Revisa tu conexión y vuelve a intentar.',
      );
    } on http.ClientException {
      throw const PhotoUploadException(
        'No hay conexión con el servicio de fotos. Revisa internet y vuelve a intentar.',
      );
    }
  }

  void close() {
    _client.close();
    _uploaded.clear();
  }
}

/// Also accepts older records that stored a URL string or secure_url.
String reportPhotoUrl(dynamic photo) {
  final value = photo is Map
      ? (photo['url'] ?? photo['secure_url'] ?? photo['originalUrl'] ?? '')
      : photo;
  var url = (value ?? '').toString().trim();
  final uri = Uri.tryParse(url);
  if (uri == null || !['http', 'https'].contains(uri.scheme)) return '';
  if (uri.host == 'res.cloudinary.com') {
    url = uri.replace(scheme: 'https').toString();
    if (url.contains('/image/upload/') && !url.contains('/f_jpg,')) {
      // JPEG delivery also works when the original iPhone image was HEIC.
      url = url.replaceFirst(
        '/image/upload/',
        '/image/upload/f_jpg,q_auto,w_1600,c_limit/',
      );
    }
  }
  return url;
}

String reportSaveError(Object error) {
  if (error is PhotoUploadException) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'No se pudo guardar el registro: revisa que sigas asignado al grupo y que la clase esté habilitada. Si continúa, el administrador debe actualizar los permisos. Tus fotos seleccionadas se conservan para reintentar.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No se pudo conectar con la base de datos. Conservamos tus fotos; revisa internet y vuelve a guardar.';
      case 'unauthenticated':
        return 'Tu sesión venció. Vuelve a iniciar sesión para guardar el reporte.';
    }
  }
  return 'No se pudo guardar el registro. Tus fotos se conservan; vuelve a intentar.';
}

Future<XFile?> chooseReportPhoto(
  BuildContext context,
  ImagePicker picker,
) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Añadir una foto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Tomar foto'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de mis fotos'),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;
  return picker.pickImage(
    source: source,
    imageQuality: 78,
    maxWidth: 1600,
    maxHeight: 1600,
    requestFullMetadata: false,
  );
}

class ReportPhoto extends StatefulWidget {
  const ReportPhoto(
    this.photo, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });
  final dynamic photo;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  State<ReportPhoto> createState() => _ReportPhotoState();
}

class _ReportPhotoState extends State<ReportPhoto> {
  int _attempt = 0;

  Future<void> _openPhoto(String url) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Borgona.background,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar foto',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) =>
                        const Text('No se pudo cargar la foto.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = reportPhotoUrl(widget.photo);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: url.isEmpty
            ? ColoredBox(
                color: Borgona.sunken,
                child: Center(child: Icon(Icons.image_outlined)),
              )
            : GestureDetector(
                onTap: () => _openPhoto(url),
                child: Semantics(
                  label: 'Foto del reporte. Toca para ampliar.',
                  image: true,
                  child: Image.network(
                    url,
                    key: ValueKey('$url:$_attempt'),
                    fit: widget.fit,
                    width: widget.width,
                    height: widget.height,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : ColoredBox(
                            color: Borgona.sunken,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                    errorBuilder: (context, error, stack) => ColoredBox(
                      color: Borgona.sunken,
                      child: Center(
                        child: IconButton(
                          tooltip: 'Volver a cargar la foto',
                          onPressed: () async {
                            await NetworkImage(url).evict();
                            if (mounted) setState(() => _attempt++);
                          },
                          icon: Icon(Icons.refresh, color: Borgona.burgundy),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class SelectedPhotoThumbnail extends StatefulWidget {
  const SelectedPhotoThumbnail(this.photo, {super.key});
  final XFile photo;
  @override
  State<SelectedPhotoThumbnail> createState() => _SelectedPhotoThumbnailState();
}

class _SelectedPhotoThumbnailState extends State<SelectedPhotoThumbnail> {
  late Future<Uint8List> _bytes = widget.photo.readAsBytes();
  @override
  void didUpdateWidget(SelectedPhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo) _bytes = widget.photo.readAsBytes();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 56,
      height: 56,
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) => snapshot.hasData
            ? Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) =>
                    const Icon(Icons.photo_outlined),
              )
            : ColoredBox(
                color: Borgona.sunken,
                child: Icon(Icons.photo_outlined),
              ),
      ),
    ),
  );
}
