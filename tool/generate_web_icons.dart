import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('icon.png');
  if (!iconFile.existsSync()) {
    print('Error: icon.png not found');
    exit(1);
  }

  final original = img.decodeImage(iconFile.readAsBytesSync())!;
  print('Loaded icon.png: ${original.width}x${original.height}');

  final iconsDir = Directory('web/icons');
  if (!iconsDir.existsSync()) {
    iconsDir.createSync(recursive: true);
  }

  // 1. Icon-192.png & favicon.png
  final icon192 = img.copyResize(
    original,
    width: 192,
    height: 192,
    interpolation: img.Interpolation.cubic,
  );
  File('web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('web/favicon.png').writeAsBytesSync(img.encodePng(icon192));
  print('Wrote web/icons/Icon-192.png and web/favicon.png');

  // 2. Icon-512.png
  final icon512 = img.copyResize(
    original,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  File('web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(icon512));
  print('Wrote web/icons/Icon-512.png');

  // 3. Icon-maskable-192.png
  final maskable192 = img.Image(width: 192, height: 192);
  img.fill(maskable192, color: img.ColorRgba8(255, 255, 255, 255));
  final inner192 = img.copyResize(
    original,
    width: 154,
    height: 154,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(maskable192, inner192, dstX: 19, dstY: 19);
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(maskable192));
  print('Wrote web/icons/Icon-maskable-192.png');

  // 4. Icon-maskable-512.png
  final maskable512 = img.Image(width: 512, height: 512);
  img.fill(maskable512, color: img.ColorRgba8(255, 255, 255, 255));
  final inner512 = img.copyResize(
    original,
    width: 410,
    height: 410,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(maskable512, inner512, dstX: 51, dstY: 51);
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(maskable512));
  print('Wrote web/icons/Icon-maskable-512.png');

  print('Done generating all web icons!');
}
