# image_to_ascii

Convert images or camera output to ASCII art in real-time.

<img src="assets/camera.jpg" width="45%" alt="Camera"/> <img src="assets/edit.jpg" width="45%" alt="Edit"/>

## Usage

### Real-time camera preview

```dart
import 'package:image_to_ascii/image_to_ascii.dart';

// Create camera controller
final controller = AsciiCameraController(
  darkMode: true,
  width: 150,
);
await controller.initialize();

// Display live ASCII using StreamBuilder
StreamBuilder(
  stream: controller.stream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return AsciiImageWidget(
        ascii: AsciiImage.fromSimpleString(snapshot.data!),
      );
    }
    return CircularProgressIndicator();
  },
)

// Control flash
await controller.flashOn();
await controller.flashOff();
await controller.flashAuto();

// Switch cameras
await controller.switchToFront();
await controller.switchToBack();

// Take a picture and convert to ASCII
final picture = await controller.takePicture();
// Then pass to convertImagePathToAscii()

// Dispose when done
await controller.dispose();
```

### Convert image to ASCII

```dart
import 'package:image_to_ascii/image_to_ascii.dart';

// Convert image file to ASCII
final asciiImage = await convertImagePathToAscii(
  'path/to/image.png',
  dark: true,
  color: false,
);

// Display
AsciiImageWidget(ascii: asciiImage)
```

### Options

- `width` / `height` - Set output dimensions (density)
- `dark` / `darkMode` - Invert colors (white text on black)
- `color` - Enable colored ASCII output

```dart
convertImagePathToAscii(
  'image.png',
  width: 100,
  dark: true,
  color: true,
)
```
