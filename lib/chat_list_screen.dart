


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/chat_screen.dart';
import 'package:healthpost_app/providers/chat_provider.dart';
import 'package:healthpost_app/widgets/doctor_chat_title.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorChatListScreen extends ConsumerStatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  ConsumerState<DoctorChatListScreen> createState() =>
      _DoctorChatListScreenState();
}

class _DoctorChatListScreenState
    extends ConsumerState<DoctorChatListScreen> {

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('chat_list_doctor_$_currentUserId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (_) {
        ref.read(chatListProvider.notifier).refresh();
      },
    )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Patient Messages',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(chatListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: chatAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () =>
                ref.read(chatListProvider.notifier).refresh(),
            child: const Text("Retry"),
          ),
        ),

        data: (chats) => chats.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
          onRefresh: () =>
              ref.read(chatListProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) => DoctorChatTile(
              preview: chats[i],
              currentUserId: _currentUserId,
              onTap: () async {
                await Get.to(() => ChatScreen(appt: chats[i].appt));

                ref.read(chatListProvider.notifier).refresh();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text("No patient chats yet"),
    );
  }
}