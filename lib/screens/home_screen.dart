import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/recording.dart';
import '../providers/recording_provider.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordingProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final provider = context.watch<RecordingProvider>();

    if (_isSearching) {
      return AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              provider.search('');
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search by phone number...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (query) => provider.search(query),
        ),
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE94560), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Call Recorder',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
      actions: [
        if (provider.isRecording)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                SizedBox(width: 4),
                Text('REC', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final provider = context.watch<RecordingProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94560)),
      );
    }

    if (provider.recordings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFFE94560),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () => provider.loadRecordings(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.recordings.length,
        itemBuilder: (context, index) {
          return _buildRecordingCard(provider.recordings[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.phone_in_talk,
              size: 64,
              color: Color(0xFF533483),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Recordings Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call recordings will appear here.\nMake or receive a call to start recording.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(Recording recording) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(recording.timestamp);

    return Dismissible(
      key: Key(recording.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Delete Recording?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'This will permanently delete this recording.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<RecordingProvider>().deleteRecording(recording);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF533483).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(recording: recording),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Call type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: recording.isIncoming
                          ? const Color(0xFF0F3460).withOpacity(0.4)
                          : const Color(0xFF533483).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      recording.isIncoming
                          ? Icons.call_received
                          : Icons.call_made,
                      color: recording.isIncoming
                          ? const Color(0xFF48C9B0)
                          : const Color(0xFFE94560),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Recording info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.phoneNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Duration & source
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        recording.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: recording.audioSource == 'VOICE_CALL'
                              ? const Color(0xFF48C9B0).withOpacity(0.15)
                              : const Color(0xFFE94560).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recording.audioSource == 'VOICE_CALL'
                              ? 'BOTH'
                              : 'MIC',
                          style: TextStyle(
                            color: recording.audioSource == 'VOICE_CALL'
                                ? const Color(0xFF48C9B0)
                                : const Color(0xFFE94560),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    final provider = context.watch<RecordingProvider>();

    return FloatingActionButton.extended(
      onPressed: () => provider.toggleAutoRecord(),
      backgroundColor: provider.autoRecordEnabled
          ? const Color(0xFFE94560)
          : const Color(0xFF533483),
      icon: Icon(
        provider.autoRecordEnabled ? Icons.mic : Icons.mic_off,
        color: Colors.white,
      ),
      label: Text(
        provider.autoRecordEnabled ? 'Auto Record ON' : 'Auto Record OFF',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
