import 'dart:io';

import 'package:dio/dio.dart';

String apiErrorMessage(DioException exception) {
  if (exception.response?.statusCode == 401) {
    return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
  }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    case DioExceptionType.unknown:
      if (exception.error is SocketException) {
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      }
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.cancel:
      break;
  }

  return 'Terjadi kesalahan saat menghubungi server. Silakan coba lagi.';
}
