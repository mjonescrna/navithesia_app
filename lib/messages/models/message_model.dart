class Message {
  final String id;
  final String text;
  final String senderName;
  final String senderInitial;
  final DateTime timestamp;
  final bool isCurrentUser;

  Message({
    required this.id,
    required this.text,
    required this.senderName,
    required this.senderInitial,
    required this.timestamp,
    this.isCurrentUser = false,
  });

  // Factory constructor to create a message from a map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      text: map['text'] as String,
      senderName: map['senderName'] as String,
      senderInitial:
          map['senderInitial'] ?? map['senderName'].toString().substring(0, 1),
      timestamp:
          map['timestamp'] is DateTime ? map['timestamp'] : DateTime.now(),
      isCurrentUser: map['isCurrentUser'] ?? false,
    );
  }

  // Convert message to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'senderName': senderName,
      'senderInitial': senderInitial,
      'timestamp': timestamp.toIso8601String(),
      'isCurrentUser': isCurrentUser,
    };
  }
}
