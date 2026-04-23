class SmsMessageEntry {
  SmsMessageEntry({
    required this.id,
    required this.address,
    required this.body,
    required this.receivedAt,
  });

  final String id;
  final String address;
  final String body;
  final DateTime receivedAt;

  factory SmsMessageEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    final millis = rawDate is int
        ? rawDate
        : int.tryParse(rawDate?.toString() ?? '') ?? 0;
    return SmsMessageEntry(
      id: map['id']?.toString() ?? '',
      address: map['address']?.toString() ?? 'Noma’lum',
      body: map['body']?.toString() ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}
