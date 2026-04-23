class SmsMessageEntry {
  SmsMessageEntry({
    required this.id,
    required this.threadId,
    required this.address,
    required this.body,
    required this.receivedAt,
    required this.type,
  });

  final String id;
  final int threadId;
  final String address;
  final String body;
  final DateTime receivedAt;
  final int type;

  bool get isIncoming => type == 1;

  factory SmsMessageEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    final millis = rawDate is int
        ? rawDate
        : int.tryParse(rawDate?.toString() ?? '') ?? 0;
    final rawThread = map['threadId'];
    final threadId = rawThread is int
        ? rawThread
        : int.tryParse(rawThread?.toString() ?? '') ?? 0;
    final rawType = map['type'];
    final type = rawType is int ? rawType : int.tryParse(rawType?.toString() ?? '') ?? 1;
    return SmsMessageEntry(
      id: map['id']?.toString() ?? '',
      threadId: threadId,
      address: map['address']?.toString() ?? 'Noma’lum',
      body: map['body']?.toString() ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      type: type,
    );
  }
}
