import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final int postId;
  final Post? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = initialPost == null
        ? ref.watch(postDetailProvider(postId))
        : AsyncData(initialPost!);

    return Scaffold(
      appBar: AppBar(title: Text('Post #$postId')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
