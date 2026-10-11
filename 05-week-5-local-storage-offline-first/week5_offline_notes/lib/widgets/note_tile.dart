import 'package:flutter/material.dart';

import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap});

  final Note note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.body),
          if (note.dirty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Chip(
                avatar: Icon(Icons.cloud_upload, size: 18),
                label: Text('Belum tersinkron'),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      trailing: note.dirty
          ? null
          : const Icon(Icons.check_circle, color: Colors.green),
      onTap: onTap,
      isThreeLine: note.dirty,
    );
  }
}
