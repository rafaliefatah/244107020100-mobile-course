import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

/// Model data untuk satu item statistik
/// Memuat data seperti label, nilai, dan deskripsi
class StatItem {
  final String label;
  final int value;
  final String description;

  StatItem({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  String toString() => 'StatItem(label: $label, value: $value, description: $description)';
}

/// Notifier untuk mengelola state pengambilan data statistik
/// AsyncNotifierProvider akan automatically menangani loading, error, dan success states
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  /// Method yang dipanggil saat provider di-initialize atau di-refresh
  /// Returns Future yang resolve dengan data statistik atau throw exception
  @override
  Future<List<StatItem>> build() async {
    return _fetchStats();
  }

  /// Simulasi pengambilan data statistik dari API
  /// - Delay 2 detik untuk mensimulasikan network request
  /// - 30% chance untuk gagal (throw exception)
  /// - Returns 3 item statistik jika berhasil
  Future<List<StatItem>> _fetchStats() async {
    // Simulasi delay untuk network request
    await Future.delayed(const Duration(seconds: 2));

    // Generate random number untuk simulasi error (30% chance gagal)
    final random = Random();
    if (random.nextInt(100) < 30) {
      throw Exception('Gagal mengambil data statistik. Silahkan coba lagi.');
    }

    // Return 3 item statistik jika berhasil
    return [
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
  }

  /// Method untuk manual refresh data statistik
  /// Bisa dipanggil dari UI saat user menekan tombol retry
  Future<void> retryFetch() async {
    // Set state ke loading dengan membuat future baru
    state = const AsyncValue.loading();
    // Fetch data dan update state
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

/// AsyncNotifierProvider yang provide instance dari StatsNotifier
/// AsyncNotifierProvider automatically handle loading, error, dan success states
/// state akan berupa:
/// - AsyncValue.loading() saat fetching
/// - AsyncValue.error(error) saat error
/// - AsyncValue.data(data) saat success
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<StatItem>>(
  () => StatsNotifier(),
);
