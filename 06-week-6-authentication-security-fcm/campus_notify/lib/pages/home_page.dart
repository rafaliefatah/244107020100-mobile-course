import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // Helper untuk sensor token (12 karakter pertama + ...)
  String _formatToken(String? token) {
    if (token == null || token.isEmpty) return 'Memuat token...';
    if (token.length <= 12) return token;
    return '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tampilan Debug Token FCM (Terpotong) untuk Bukti Tugas
          FutureBuilder<String?>(
            future: FirebaseMessaging.instance.getToken(),
            builder: (context, snapshot) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                child: Text(
                  'FCM Token (Debug): ${_formatToken(snapshot.data)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Daftar Pengumuman Terbaru:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Pengumuman Libur Akademik'),
            subtitle: const Text('Klik untuk detail...'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.announcementDetail('101')),
          ),
          ListTile(
            title: const Text('Jadwal Ujian Akhir Semester'),
            subtitle: const Text('Klik untuk detail...'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.announcementDetail('102')),
          ),
        ],
      ),
    );
  }
}
