import 'dart:io';

import 'package:dio/dio.dart';

import '../failures/failure.dart';

Failure apiFailureFromException(DioException exception) {
  if (exception.response?.statusCode == 401) {
    return const AuthenticationFailure(
      'Sesi Anda telah berakhir. Silakan masuk kembali.',
    );
  }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const ServerFailure(
        'Koneksi ke server terlalu lama. Silakan coba lagi.',
      );
    case DioExceptionType.connectionError:
      return const ServerFailure(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
      );
    case DioExceptionType.unknown:
      if (exception.error is SocketException) {
        return const ServerFailure(
          'Tidak ada koneksi internet. Periksa jaringan Anda.',
        );
      }
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.cancel:
      break;
  }

  return const ServerFailure(
    'Terjadi kesalahan saat menghubungi server. Silakan coba lagi.',
  );
}

Failure failureFromException(Object error) {
  if (error is DioException) return apiFailureFromException(error);
  if (error is Exception) {
    return const UnexpectedFailure('Terjadi kesalahan. Silakan coba lagi.');
  }
  return const UnexpectedFailure('Terjadi kesalahan. Silakan coba lagi.');
}
