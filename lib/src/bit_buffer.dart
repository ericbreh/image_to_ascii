import 'dart:typed_data';

// write only
class BitBuffer {
  final Uint8List _buffer;
  int _currentByte = 0;
  int _bitCount = 0;
  int _byteCount = 0;
  bool _consumed = false;

  BitBuffer(int maxLength) : _buffer = Uint8List((maxLength + 7) ~/ 8);

  //MSB ordering
  void addBit(int value) {
    assert(!_consumed, 'BitBuffer may only be converted one time');
    assert(value == 0 || value == 1);
    _currentByte |= (value << (7 - _bitCount));
    if (_bitCount == 7) {
      _buffer[_byteCount++] = _currentByte;
      _currentByte = 0;
      _bitCount = 0;
    } else {
      _bitCount++;
    }
  }

  void addBits(int value, int count) {
    assert(value >= 0 && value < (1 << count));
    for (int i = count - 1; i >= 0; i--) {
      addBit((value >> i) & 1);
    }
  }

  //The buffer may not be used after this is called
  Uint8List toUint8List() {
    assert(!_consumed, 'BitBuffer may only be converted one time');
    if (_bitCount != 0) {
      _buffer[_byteCount++] = _currentByte;
      _currentByte = 0;
      _bitCount = 0;
    }
    _consumed = true;
    return Uint8List.sublistView(_buffer, 0, _byteCount);
  }
}

// read only
class BitArray {
  final Uint8List _buffer;
  int _byteIndex = 0;
  int _bitIndex = 0;

  BitArray(Uint8List list) : _buffer = list;

  // Reads a single bit in MSB-first order
  int readBit() {
    if (_byteIndex >= _buffer.length) {
      throw StateError('No more bits to read');
    }

    int byte = _buffer[_byteIndex];
    int bit = (byte >> (7 - _bitIndex)) & 1;

    _bitIndex++;
    if (_bitIndex == 8) {
      _bitIndex = 0;
      _byteIndex++;
    }

    return bit;
  }

  // Reads multiple bits and returns them as an integer
  int readBits(int count) {
    if (count < 0 || count > 32) {
      throw ArgumentError('Bit count must be between 0 and 32');
    }

    int result = 0;
    for (int i = 0; i < count; i++) {
      result = (result << 1) | readBit();
    }
    return result;
  }

  int get remainingBits => (_buffer.length - _byteIndex) * 8 - _bitIndex;
}
