import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recording_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recording Settings Section
          _sectionHeader('Recording'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              _switchTile(
                icon: Icons.mic,
                iconColor: const Color(0xFFE94560),
                title: 'Auto Record',
                subtitle: 'Automatically record all calls',
                value: provider.autoRecordEnabled,
                onChanged: (_) => provider.toggleAutoRecord(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Storage Section
          _sectionHeader('Storage'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              _infoTile(
                icon: Icons.folder,
                iconColor: const Color(0xFF533483),
                title: 'Recording Location',
                subtitle: provider.recordingPath.isEmpty
                    ? '/storage/emulated/0/callrecording'
                    : provider.recordingPath,
              ),
              const Divider(color: Color(0xFF2A2A4A), height: 1),
              _infoTile(
                icon: Icons.audio_file,
                iconColor: const Color(0xFF0F3460),
                title: 'Audio Format',
                subtitle: 'M4A (AAC, 128kbps, 44.1kHz)',
              ),
              const Divider(color: Color(0xFF2A2A4A), height: 1),
              _infoTile(
                icon: Icons.record_voice_over,
                iconColor: const Color(0xFF48C9B0),
                title: 'Recording Mode',
                subtitle: 'VOICE_CALL (both sides) with MIC fallback',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _sectionHeader('About'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              _infoTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF48C9B0),
                title: 'Version',
                subtitle: '1.0.0',
              ),
              const Divider(color: Color(0xFF2A2A4A), height: 1),
              _infoTile(
                icon: Icons.phone_android,
                iconColor: const Color(0xFF0F3460),
                title: 'Platform',
                subtitle: 'Android only (personal use)',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE94560).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFFE94560), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Call recording laws vary by jurisdiction. Ensure you comply with local regulations regarding consent and notification when recording calls.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF533483).withOpacity(0.2),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFE94560),
        activeTrackColor: const Color(0xFFE94560).withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
      ),
    );
  }
}
