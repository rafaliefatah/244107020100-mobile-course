import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository yang mengisolasi komunikasi endpoint komentar dari UI/state.
class CommentRepository {
  /// Repository menerima Dio agar mudah dipakai ulang dan diuji.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar untuk post tertentu dengan batas waktu 10 detik.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Abaikan item yang bukan object JSON dan gunakan list kosong jika data null.
    final data = response.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
