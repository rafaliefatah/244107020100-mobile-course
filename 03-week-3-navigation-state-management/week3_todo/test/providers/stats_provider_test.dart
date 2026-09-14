import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

/// Unit test untuk StatsNotifier dan statsProvider
void main() {
  group('StatsNotifier', () {
    /// Test 1: Memastikan data statistik memiliki struktur yang benar
    /// - Harus return 3 item statistik
    /// - Setiap item harus memiliki label, value, dan description
    test('build() returns list with valid structure when successful', () async {
      // Setup: Buat instance dari StatsNotifier
      final notifier = StatsNotifier();

      // Act: Coba build() sampai sukses (karena ada 30% chance error)
      late List<StatItem> result;
      var attempts = 0;
      while (attempts < 20) {
        try {
          result = await notifier.build();
          break;
        } catch (e) {
          attempts++;
          if (attempts >= 20) {
            throw Exception('Failed after 20 attempts');
          }
        }
      }

      // Assert: Verifikasi hasil
      expect(result, isA<List<StatItem>>());
      expect(result.length, equals(3));
      
      // Verifikasi struktur setiap item
      expect(result[0].label, equals('Total Users'));
      expect(result[0].value, isA<int>());
      expect(result[0].description, isNotEmpty);
      
      expect(result[1].label, equals('Active Sessions'));
      expect(result[2].label, equals('Total Revenue'));
    });

    /// Test 2: Memastikan provider dapat menangani error dengan gracefully
    /// - Jika terjadi error, build() harus throw exception
    /// - Error message harus meaningful
    test('build() can throw error as simulated', () async {
      // Setup: Buat instance dari StatsNotifier
      final notifier = StatsNotifier();

      // Act & Assert: Coba sampai mendapat error (dengan retry logic)
      var gotError = false;
      var attempts = 0;
      const maxAttempts = 20;
      
      for (attempts = 0; attempts < maxAttempts; attempts++) {
        try {
          await notifier.build();
          // Jika sukses, lanjut ke attempt berikutnya
          continue;
        } catch (e) {
          // Jika error, verify error message dan exit
          gotError = true;
          expect(
            e.toString(),
            contains('Gagal mengambil data statistik'),
            reason: 'Error message harus mengandung text yang sesuai',
          );
          break;
        }
      }

      // Minimal satu dari kondisi ini harus true
      expect(
        gotError,
        isTrue,
        reason: 'Notifier harus mampu throw error (30% chance)',
      );
    });

    /// Test 3: Memastikan StatItem.toString() bekerja dengan baik
    /// - Berguna untuk debugging
    test('StatItem toString() returns formatted string', () {
      // Setup
      final item = StatItem(
        label: 'Test Label',
        value: 100,
        description: 'Test Description',
      );

      // Act
      final result = item.toString();

      // Assert: Verifikasi format string
      expect(result, contains('StatItem'));
      expect(result, contains('Test Label'));
      expect(result, contains('100'));
      expect(result, contains('Test Description'));
    });

    /// Test 4: Memastikan retryFetch() bisa dipanggil
    /// - Notifier harus memiliki method retryFetch
    /// - Method harus bisa diakses dari notifier
    test('retryFetch() method exists', () {
      // Setup
      final notifier = StatsNotifier();

      // Assert: Verifikasi method retryFetch ada (bukan null)
      expect(
        notifier.retryFetch,
        isNotNull,
        reason: 'Notifier harus memiliki retryFetch method',
      );

      // Verifikasi method retryFetch bisa dipanggil tanpa error
      final retryResult = notifier.retryFetch();
      expect(
        retryResult,
        isA<Future>(),
        reason: 'retryFetch harus return Future',
      );
    });
  });

  /// Group test untuk statsProvider behavior
  group('statsProvider behavior', () {
    /// Test 5: Memastikan provider dapat di-read dan return AsyncValue
    test('statsProvider returns AsyncValue type', () async {
      // Setup
      final container = ProviderContainer();

      // Act: Read provider
      final value = container.read(statsProvider);

      // Assert: Harus berupa AsyncValue
      expect(
        value,
        isA<AsyncValue>(),
        reason: 'Provider harus return AsyncValue',
      );
    });

    /// Test 6: Memastikan provider data dapat di-read sebagai Future
    test('statsProvider.future returns List<StatItem>', () async {
      // Setup
      final container = ProviderContainer();

      // Act: Tunggu future dari provider dengan retry logic
      late List<StatItem> result;
      var attempts = 0;
      const maxAttempts = 10;

      for (attempts = 0; attempts < maxAttempts; attempts++) {
        try {
          result = await container.read(statsProvider.future);
          break; // Jika berhasil, exit loop
        } catch (e) {
          // Jika error, retry
          if (attempts >= maxAttempts - 1) {
            rethrow; // Throw error jika sudah max attempts
          }
        }
      }

      // Assert: Verifikasi result adalah List<StatItem>
      expect(
        result,
        isA<List<StatItem>>(),
        reason: 'Future harus resolve ke List<StatItem>',
      );
      expect(result.length, equals(3));
    });

    /// Test 7: Memastikan provider dapat di-invalidate
    test('statsProvider can be invalidated', () {
      // Setup
      final container = ProviderContainer();

      // Act: Invalidate provider (tidak perlu await)
      expect(
        () => container.invalidate(statsProvider),
        returnsNormally,
        reason: 'invalidate harus bisa dipanggil tanpa error',
      );
    });

    /// Test 8: Memastikan notifier dapat di-access dari container
    test('statsProvider notifier can be accessed', () {
      // Setup
      final container = ProviderContainer();

      // Act: Access notifier
      final notifier = container.read(statsProvider.notifier);

      // Assert
      expect(
        notifier,
        isA<StatsNotifier>(),
        reason: 'Notifier harus bertype StatsNotifier',
      );
    });
  });

  /// Group test untuk StatItem data validation
  group('StatItem data validation', () {
    /// Test 9: Verifikasi data item memiliki nilai yang valid
    test('StatItem properties have valid values', () {
      // Setup
      final items = [
        StatItem(
          label: 'Total Users',
          value: 1250,
          description: 'Jumlah pengguna aktif bulan ini',
        ),
        StatItem(
          label: 'Active Sessions',
          value: 342,
          description: 'Session yang sedang berjalan',
        ),
        StatItem(
          label: 'Total Revenue',
          value: 45850,
          description: 'Total pendapatan bulan ini (dalam USD)',
        ),
      ];

      // Assert: Verifikasi setiap item
      for (final item in items) {
        expect(item.label, isNotEmpty);
        expect(item.value, greaterThan(0));
        expect(item.description, isNotEmpty);
      }
    });
  });
}
