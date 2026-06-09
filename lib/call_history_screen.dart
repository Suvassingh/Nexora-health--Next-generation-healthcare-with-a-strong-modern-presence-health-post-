import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../app_constants.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _callsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _callsFuture = ApiService.getCallHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _callsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Failed to load calls: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final calls = snapshot.data!;
          if (calls.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_missed, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No call history found'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: calls.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final call = calls[index];
              return _CallHistoryCard(call: call);
            },
          );
        },
      ),
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  final Map<String, dynamic> call;

  const _CallHistoryCard({required this.call});

  String _formatDuration(String? start, String? end) {
    if (start == null || end == null) return '—';
    final startTime = DateTime.parse(start);
    final endTime = DateTime.parse(end);
    final diff = endTime.difference(startTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds} sec';
    return '${diff.inMinutes} min ${diff.inSeconds % 60} sec';
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'missed':
        return Icons.call_missed;
      case 'declined':
        return Icons.call_end;
      default:
        return Icons.phone_missed;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Connected';
      case 'missed':
        return 'Missed';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherParty = call['caller_name'] ?? call['callee_name'] ?? 'Unknown';
    final callType = call['call_type'] ?? 'audio';
    final status = call['status'] ?? 'ended';
    final createdAt = call['created_at'];
    final endedAt = call['ended_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
          child: Icon(
            callType == 'video' ? Icons.videocam : Icons.phone,
            color: AppConstants.primaryColor,
          ),
        ),
        title: Text(
          otherParty,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatTime(createdAt)} • ${callType.toUpperCase()}'),
            if (endedAt != null)
              Text(
                'Duration: ${_formatDuration(createdAt, endedAt)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(status), color: _statusColor(status), size: 20),
            const SizedBox(height: 4),
            Text(
              _statusLabel(status),
              style: TextStyle(fontSize: 12, color: _statusColor(status)),
            ),
          ],
        ),
      ),
    );
  }
}
