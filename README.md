# image_to_ascii

A Flutter package that converts images to ASCII art. Transform any image into beautiful text-based art with support for both static images and live camera feeds.

## Features

- 🖼️ **Image to ASCII Conversion**: Convert any image file to ASCII art
- 📷 **Live Camera Feed**: Real-time ASCII art from your device's camera
- 🎨 **Color Support**: Optional colored ASCII output
- 🌓 **Dark/Light Modes**: Support for both dark and light backgrounds
- ⚡ **Performance Optimized**: Uses isolates for efficient image processing
- 📐 **Flexible Sizing**: Customize output dimensions and aspect ratios
- 🔄 **Camera Controls**: Switch between front and back cameras
- 💾 **Serialization**: Save and load ASCII images with efficient encoding

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  image_to_ascii: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Converting a Static Image

```dart
import 'package:image_to_ascii/image_to_ascii.dart';

// Convert an image file to ASCII
Future<void> convertImage() async {
  final asciiImage = await convertImagePathToAscii(
    'path/to/image.jpg',
    width: 150,          // Optional: target width in characters
    height: 75,          // Optional: target height in characters
    dark: true,          // Dark mode (white text on black)
    color: false,        // Enable color output
  );
  
  // Display the ASCII image
  print(asciiImage.toDisplayString());
}
```

### Using the ASCII Image Widget

```dart
import 'package:flutter/material.dart';
import 'package:image_to_ascii/image_to_ascii.dart';

class AsciiImageExample extends StatelessWidget {
  final AsciiImage asciiImage;
  
  @override
  Widget build(BuildContext context) {
    return AsciiImageWidget(
      ascii: asciiImage,
      width: 500,
      height: 600,
      textStyle: TextStyle(fontSize: 8),
    );
  }
}
```

### Using the Camera Controller

```dart
import 'package:image_to_ascii/image_to_ascii.dart';

class CameraAsciiExample extends StatefulWidget {
  @override
  State<CameraAsciiExample> createState() => _CameraAsciiExampleState();
}

class _CameraAsciiExampleState extends State<CameraAsciiExample> {
  late AsciiCameraController _controller;
  String _currentFrame = '';

  @override
  void initState() {
    super.initState();
    _controller = AsciiCameraController(
      width: 150,                        // Output width in characters
      height: 75,                        // Output height in characters
      preset: ResolutionPreset.low,     // Camera resolution
      darkMode: true,                    // Dark or light ASCII
    );
    
    _controller.initialize().then((_) {
      _controller.stream.listen((asciiFrame) {
        setState(() {
          _currentFrame = asciiFrame;
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display ASCII camera feed
        Text(_currentFrame, style: TextStyle(fontSize: 8)),
        
        // Camera controls
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _controller.switchToBack(),
              child: Text('Back Camera'),
            ),
            ElevatedButton(
              onPressed: () => _controller.switchToFront(),
              child: Text('Front Camera'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Image Cropping

```dart
import 'package:image_to_ascii/image_to_ascii.dart';

// Crop image to specific aspect ratio before conversion
Future<void> cropAndConvert() async {
  final croppedImage = await cropToAspectRatio(
    'path/to/image.jpg',
    portrait: 4 / 5,      // Portrait aspect ratio
    landscape: 5 / 4,     // Landscape aspect ratio
    desiredWidth: 500,    // Target width
    vScale: 1.0,          // Vertical scale factor
  );
  
  final asciiImage = await convertImageToAscii(
    croppedImage,
    dark: true,
    color: false,
  );
}
```

### Saving and Loading ASCII Images

```dart
// Save ASCII image to string
String savedData = asciiImage.toStorableString();

// Load ASCII image from string
AsciiImage loadedImage = AsciiImage.fromStorableString(savedData);
```

## API Reference

### Main Functions

#### `convertImagePathToAscii`
Converts an image file to ASCII art.

**Parameters:**
- `path` (String): Path to the image file
- `width` (int?, optional): Target width in characters
- `height` (int?, optional): Target height in characters
- `dark` (bool, default: false): Use dark mode (white on black)
- `color` (bool, default: false): Enable colored output
- `charAspectRatio` (double, default: 0.7): Character aspect ratio for scaling

**Returns:** `Future<AsciiImage>`

#### `convertImageToAscii`
Converts a `ui.Image` object to ASCII art.

**Parameters:**
- `image` (ui.Image): The image to convert
- `dark` (bool, default: false): Use dark mode
- `color` (bool, default: false): Enable colored output

**Returns:** `Future<AsciiImage>`

### Classes

#### `AsciiImage`
Represents an ASCII art image with metadata.

**Properties:**
- `version` (int): Format version
- `data` (Uint8List): Encoded ASCII data
- `width` (int?): Width in characters
- `height` (int?): Height in characters
- `dark` (bool): Dark mode flag
- `color` (bool): Color mode flag

**Methods:**
- `toDisplayString()`: Convert to plain text string
- `toTextSpans()`: Convert to Flutter TextSpans for rendering
- `toStorableString()`: Serialize to base64 string
- `fromStorableString(String)`: Deserialize from base64 string
- `fromSimpleString(String)`: Create from plain ASCII text

#### `AsciiCameraController`
Controls camera feed for real-time ASCII conversion.

**Constructor Parameters:**
- `width` (int, default: 150): Output width in characters
- `height` (int?): Output height in characters
- `preset` (ResolutionPreset, default: low): Camera resolution
- `darkMode` (bool, default: false): Use dark mode

**Properties:**
- `stream`: Stream of ASCII frames
- `cameras`: Available camera devices
- `currentCameraIndex`: Current camera index

**Methods:**
- `initialize()`: Initialize camera
- `switchToBack()`: Switch to back camera
- `switchToFront()`: Switch to front camera
- `switchToCamera(int)`: Switch to specific camera
- `takePicture()`: Capture a still image
- `dispose()`: Clean up resources

#### `AsciiImageWidget`
Flutter widget for displaying ASCII images.

**Constructor Parameters:**
- `ascii` (AsciiImage, required): The ASCII image to display
- `width` (double?): Widget width
- `height` (double?): Widget height
- `textStyle` (TextStyle?): Text styling
- `forceCanvas` (bool, default: false): Force canvas rendering
- `charAspectRatio` (double, default: 0.7): Character aspect ratio

## Example App

Check out the [example](example/) directory for a complete demo app that showcases:
- Image picker integration
- Live camera feed ASCII conversion
- Dark/light mode toggling
- Camera switching
- Performance metrics

To run the example:

```bash
cd example
flutter run
```

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| Web      | ✅ (limited camera support) |
| macOS    | ✅        |
| Linux    | ✅        |
| Windows  | ✅        |

## Performance

The package uses several optimization techniques:
- **Isolate-based processing**: Heavy computation runs on background isolates
- **Efficient encoding**: Custom binary format for storing ASCII images
- **Adaptive rendering**: Uses canvas or isolates based on platform capabilities
- **Stream throttling**: Camera frames are processed only when previous frame is complete

Typical conversion times (on modern mobile devices):
- 150×75 character image: ~50-100ms
- Real-time camera feed: 10-20 FPS

## Requirements

- **Flutter**: >= 1.17.0
- **Dart SDK**: ^3.7.2
- **camera**: ^0.11.1 (for camera features)
- **google_fonts**: ^6.2.1 (optional, for text styling)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run tests with `flutter test`
4. Run the example app with `cd example && flutter run`

## Credits

Developed with ❤️ using Flutter.
