import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/sms_message_entry.dart';
import '../models/sms_thread_entry.dart';

class SmsThreadPage extends StatefulWidget {
  const SmsThreadPage({
    super.key,
    required this.controller,
    required this.thread,
  });

  final AppController controller;
  final SmsThreadEntry thread;

  @override
  State<SmsThreadPage> createState() => _SmsThreadPageState();
}

class _SmsThreadPageState extends State<SmsThreadPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadSmsThreadMessages(widget.thread.threadId);
  }

  String _formatTime(DateTime t) {
    final d =
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.thread.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            widget.controller.loadSmsThreadMessages(widget.thread.threadId),
        child: ListenableBuilder(
          listenable: widget.controller.smsInbox,
          builder: (context, _) {
            final items = widget.controller.smsMessages;
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Xabarlar topilmadi')),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final SmsMessageEntry msg = items[index];
                final incoming = msg.isIncoming;
                final bubbleColor = incoming
                    ? scheme.surfaceContainerHighest
                    : scheme.primaryContainer;
                return Align(
                  alignment:
                      incoming ? Alignment.centerLeft : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.body.trim().isEmpty ? 'Bo‘sh xabar' : msg.body),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(msg.receivedAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
