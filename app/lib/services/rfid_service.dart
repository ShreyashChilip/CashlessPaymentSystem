import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class RFIDService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  static const String _wsUrl = 'ws://your-esp8266-ip:port/rfid';  // Replace with your WebSocket URL

  void startListening({required Function(String) onCardDetected}) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _subscription = _channel?.stream.listen(
        (data) {
          // Data from ESP8266 should contain the card UID
          if (data != null && data.toString().isNotEmpty) {
            onCardDetected(data.toString());
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _channel?.sink.close();
  }
}