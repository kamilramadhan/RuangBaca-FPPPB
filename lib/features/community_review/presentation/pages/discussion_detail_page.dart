import 'package:flutter/material.dart';

import '../../data/models/discussion.dart';
import '../../data/repositories/community_repository.dart';

class DiscussionDetailPage extends StatefulWidget {
  const DiscussionDetailPage({super.key, required this.discussion});
  final Discussion discussion;
  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  final _repo = CommunityRepository();
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.addReply(widget.discussion.id, Reply(
        id: '', userId: 'guest', userName: 'Tamu',
        body: _replyCtrl.text.trim(), createdAt: DateTime.now()));
      _replyCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.discussion;
    return Scaffold(
      appBar: AppBar(title: const Text('Diskusi')),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(d.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${d.bookTitle} • ${d.userName}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          Text(d.body),
          const Divider(height: 32),
          Text('Balasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<List<Reply>>(stream: _repo.watchReplies(d.id), builder: (ctx, snap) {
            final replies = snap.data ?? [];
            if (replies.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada balasan', style: TextStyle(color: Colors.grey))));
            return Column(children: replies.map((r) => Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
              padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 14, child: Text(r.userName.isNotEmpty ? r.userName[0] : '?')),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.userName, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                  if (r.userId == 'guest') PopupMenuButton<String>(
                    onSelected: (v) { if (v == 'delete') { _repo.deleteReply(d.id, r.id); } },
                    itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Hapus'))]),
                ]),
                const SizedBox(height: 6),
                Text(r.body),
              ])))).toList());
          }),
        ])),
        Container(padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          child: Row(children: [
            Expanded(child: TextField(controller: _replyCtrl,
              decoration: InputDecoration(hintText: 'Tulis balasan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              onSubmitted: (_) => _sendReply())),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _sending ? null : _sendReply, icon: const Icon(Icons.send_rounded)),
          ])),
      ]),
    );
  }
}
