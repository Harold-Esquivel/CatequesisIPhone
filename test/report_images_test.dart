import 'dart:convert';
import 'dart:typed_data';
import 'package:catequesis/services/report_images.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('URL de foto antigua, metadata y formato HEIC tienen entrega JPEG', () {
    const original =
        'http://res.cloudinary.com/demo/image/upload/v1/photo.heic';
    final url = reportPhotoUrl(original);
    expect(
      url,
      'https://res.cloudinary.com/demo/image/upload/f_jpg,q_auto,w_1600,c_limit/v1/photo.heic',
    );
    expect(reportPhotoUrl({'secure_url': original}), url);
    expect(reportPhotoUrl(url), url);
    expect(reportPhotoUrl(null), '');
    expect(reportPhotoUrl('file:///private/photo.jpg'), '');
    expect(
      reportPhotoUrl('https://example.com/photo.jpg'),
      'https://example.com/photo.jpg',
    );
  });
  test(
    'reintentar guardado reutiliza la foto subida y conserva el original',
    () async {
      var uploads = 0;
      final service = ReportImageService(
        client: MockClient((request) async {
          uploads++;
          expect(request.url.host, 'api.cloudinary.com');
          expect(request.body, contains('reportes_unsigned'));
          return http.Response(
            jsonEncode({
              'secure_url':
                  'https://res.cloudinary.com/demo/image/upload/v1/photo.heic',
              'public_id': 'reportes/photo',
              'asset_id': 'asset',
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final photo = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'photo.heic',
      );
      final first = await service.upload(
        photo: photo,
        folder: 'clases/g/2026-10-23',
        filePrefix: 'mesas',
        userId: 'ana',
      );
      final retry = await service.upload(
        photo: photo,
        folder: 'clases/g/2026-10-23',
        filePrefix: 'mesas',
        userId: 'ana',
      );
      expect(uploads, 1);
      expect(retry, first);
      expect(first['url'], contains('f_jpg'));
      expect(first['originalUrl'], endsWith('photo.heic'));
      expect(first['provider'], 'cloudinary');
    },
  );
  test(
    'preset rechazado y respuesta ilegible muestran error recuperable',
    () async {
      for (final response in [
        http.Response('{"error":{"message":"Upload preset not found"}}', 400),
        http.Response('Bad gateway', 502),
      ]) {
        final service = ReportImageService(
          client: MockClient((_) async => response),
        );
        final photo = XFile.fromData(
          Uint8List.fromList([1]),
          name: 'photo.jpg',
        );
        await expectLater(
          service.upload(
            photo: photo,
            folder: 'clases',
            filePrefix: 'foto',
            userId: 'ana',
          ),
          throwsA(isA<PhotoUploadException>()),
        );
        service.close();
      }
    },
  );
}
