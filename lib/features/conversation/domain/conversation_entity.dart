import 'dart:typed_data';

enum MessageRole { user, ai }

enum ConversationErrorType { network, permission, appCheck, quota, midSession, unknown }

enum ConversationStatus {
  idle,
  connecting,
  active,
  userSpeaking,
  aiSpeaking,
  analyzing,
  ended,
  error,
}

class ConversationMessage {
  final String id;
  final MessageRole role;
  final String text;
  final Uint8List? audioBytes;
  final DateTime timestamp;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.text,
    this.audioBytes,
    required this.timestamp,
  });

  ConversationMessage copyWith({String? text, Uint8List? audioBytes}) {
    return ConversationMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      audioBytes: audioBytes ?? this.audioBytes,
      timestamp: timestamp,
    );
  }
}
