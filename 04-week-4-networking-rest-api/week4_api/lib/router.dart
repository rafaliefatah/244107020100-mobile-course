import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/models/post.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PagedPostPage()),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final postId = int.tryParse(state.pathParameters['id'] ?? '');
          if (postId == null) return const _InvalidPostRoutePage();
          return PostDetailPage(
            postId: postId,
            initialPost: state.extra is Post ? state.extra as Post : null,
          );
        },
      ),
    ],
  );
});

class _InvalidPostRoutePage extends StatelessWidget {
  const _InvalidPostRoutePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ID post tidak valid.')));
  }
}
