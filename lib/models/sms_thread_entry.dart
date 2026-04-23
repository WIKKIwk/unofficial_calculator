class SmsThreadEntry {
  SmsThreadEntry({
    required this.threadId,
    required this.address,
    required this.snippet,
    required this.receivedAt,
    required this.messageCount,
  });

  final int threadId;
  final String address;
  final String snippet;
  final DateTime receivedAt;
  final int messageCount;

  factory SmsThreadEntry.fromMap(Map<String, dynamic> map) {
    final rawThread = map['threadId'];
    final threadId = rawThread is int
        ? rawThread
        : int.tryParse(rawThread?.toString() ?? '') ?? 0;
    final rawDate = map['date'];
    final millis = rawDate is int
        ? rawDate
        : int.tryParse(rawDate?.toString() ?? '') ?? 0;
    final rawCount = map['messageCount'];
    final count = rawCount is int
        ? rawCount
        : int.tryParse(rawCount?.toString() ?? '') ?? 0;
    return SmsThreadEntry(
      threadId: threadId,
      address: map['address']?.toString() ?? 'Noma’lum',
      snippet: map['snippet']?.toString() ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      messageCount: count,
    );
  }
}
