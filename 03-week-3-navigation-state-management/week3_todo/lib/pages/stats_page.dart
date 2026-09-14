import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

/// StaticsPage - Halaman untuk menampilkan statistik dengan state management riverpod
/// Menggunakan ConsumerWidget untuk akses ke provider
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menonton statsProvider untuk get state terbaru (loading, error, atau data)
    // Saat state berubah, widget ini akan rebuild otomatis
    final statsAsyncValue = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats (Kode AI)'),
        centerTitle: true,
      ),
      body: Center(
        // AsyncValue.when() adalah method untuk handle 3 state sekaligus:
        // data: ketika data sudah berhasil diambil
        // loading: ketika sedang fetching data
        // error: ketika terjadi error saat fetching
        child: statsAsyncValue.when(
          // State LOADING: Tampilkan spinner dan pesan
          loading: () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Mengambil data statistik...'),
              const SizedBox(height: 32),
              // Tampilkan informasi bahwa ini bisa memakan waktu 2 detik
              const Opacity(
                opacity: 0.7,
                child: Text(
                  'Ini mungkin memakan waktu beberapa detik',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // State ERROR: Tampilkan pesan error dan tombol retry
          error: (error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon untuk menandakan error
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              // Tampilkan pesan error
              Text(
                'Terjadi Kesalahan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              // Tombol Retry untuk fetch ulang data
              ElevatedButton.icon(
                onPressed: () {
                  // Panggil retryFetch dari notifier untuk fetch ulang
                  ref.read(statsProvider.notifier).retryFetch();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),

          // State SUCCESS: Tampilkan ListView dengan 3 item statistik
          data: (statsList) => ListView.builder(
            // Padding untuk memberi space di atas dan bawah
            padding: const EdgeInsets.all(16),
            // Jumlah item adalah panjang dari statsList (3 item)
            itemCount: statsList.length,
            itemBuilder: (context, index) {
              // Get item dari list berdasarkan index
              final stat = statsList[index];

              // Buat Card untuk setiap item statistik
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Label
                      Row(
                        children: [
                          // Icon berbeda untuk setiap item berdasarkan index
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorByIndex(index),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIconByIndex(index),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tampilkan label statistik
                          Text(
                            stat.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tampilkan nilai/angka statistik dalam ukuran besar
                      Text(
                        stat.value.toString(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getColorByIndex(index),
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Tampilkan deskripsi detail
                      Text(
                        stat.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      // Floating Action Button untuk manual refresh data
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Panggil invalidate untuk trigger rebuild dan fetch data ulang
          ref.invalidate(statsProvider);
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Helper method untuk mendapatkan color berdasarkan index item
  /// Memberikan warna berbeda untuk setiap statistik
  Color _getColorByIndex(int index) {
    return switch (index) {
      0 => Colors.blue,
      1 => Colors.orange,
      _ => Colors.green,
    };
  }

  /// Helper method untuk mendapatkan icon berdasarkan index item
  /// Memberikan icon yang relevan untuk setiap statistik
  IconData _getIconByIndex(int index) {
    return switch (index) {
      0 => Icons.people,
      1 => Icons.timeline,
      _ => Icons.trending_up,
    };
  }
}
