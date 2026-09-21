import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

// Re-export helper error agar konsumen lama yang mengimpor providers tetap kompatibel.
export 'network_errors.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

// Provider repository membuat dependency Dio dapat diganti saat unit testing.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// Family membuat satu state AsyncNotifier terpisah untuk setiap postId.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  /// Menyimpan postId yang diteruskan oleh family provider.
  CommentListNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    // Exception dari repository otomatis diubah Riverpod menjadi AsyncError.
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  // Memuat ulang komentar tanpa mengubah kontrak state ke UI.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(commentRepositoryProvider).fetchComments(postId),
      );
    } catch (error, stackTrace) {
      // Error manual saat refresh tetap memiliki stack trace untuk debugging.
      state = AsyncError(error, stackTrace);
    }
  }
}

// retry null mencegah request error diulang otomatis dan memudahkan retry dari UI.
final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
      CommentListNotifier.new,
      retry: (retryCount, error) => null,
    );

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider = AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
  // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
  // final dan mudah diuji (tanpa ini, future provider di-test
  // akan me-retry dan menggantung).
  retry: (retryCount, error) => null,
);

class PostDetailNotifier extends AsyncNotifier<Post> {
  PostDetailNotifier(this.postId);

  final int postId;

  @override
  Future<Post> build() async {
    final cachedPosts = ref.read(postListProvider);
    final cachedPost = cachedPosts.asData?.value
        .where((post) => post.id == postId)
        .firstOrNull;
    if (cachedPost != null) return cachedPost;

    return ref.read(postRepositoryProvider).fetchPost(postId);
  }
}

final postDetailProvider =
    AsyncNotifierProvider.family<PostDetailNotifier, Post, int>(
      PostDetailNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    next.whenData(completer.complete);
    if (next.hasError) {
      completer.completeError(
        next.error ?? StateError('unknown error'),
        next.stackTrace ?? StackTrace.empty,
      );
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    completer.complete(next.error);
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}
