import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
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
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final me = AuthService.instance;
      await _repo.addReply(
        widget.discussion.id,
        Reply(
          id: '',
          userId: me.uid,
          userName: me.displayName,
          body: _replyCtrl.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      _replyCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.discussion;
    final initial =
        d.userName.isNotEmpty ? d.userName[0].toUpperCase() : 'P';

    return Scaffold(
      appBar: AppBar(title: const Text('Diskusi')),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header diskusi ──
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Text(initial,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.userName,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(d.bookTitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryColor)),
                      ]),
                ),
              ]),
              const SizedBox(height: 14),
              Text(d.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(d.body, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.forum_outlined,
                    size: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('Balasan',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),

              // ── Stream replies ──
              StreamBuilder<List<Reply>>(
                stream: _repo.watchReplies(d.id),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator()));
                  }
                  final replies = snap.data ?? [];
                  if (replies.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: Text('Belum ada balasan',
                              style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return Column(
                    children: replies
                        .map((r) => _ReplyCard(
                            reply: r,
                            discussionId: d.id,
                            repo: _repo))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),

        // ── Input balasan ──
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                decoration: InputDecoration(
                  hintText: 'Tulis balasan...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendReply,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard(
      {required this.reply,
      required this.discussionId,
      required this.repo});
  final Reply reply;
  final String discussionId;
  final CommunityRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = reply.userId == AuthService.instance.uid;
    final initial =
        reply.userName.isNotEmpty ? reply.userName[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppTheme.accentColor,
          child: Text(initial,
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(reply.userName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (isOwner)
                      GestureDetector(
                        onTap: () => repo.deleteReply(discussionId, reply.id),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.grey),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(reply.body, style: theme.textTheme.bodyMedium),
                ]),
          ),
        ),
      ]),
    );
  }
}
