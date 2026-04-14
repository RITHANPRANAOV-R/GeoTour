import 'dart:async';
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  final String name;
  final String role;
  final String? image;

  const CallScreen({
    super.key,
    required this.name,
    required this.role,
    this.image,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blur/Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Avatar
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: widget.image != null
                      ? NetworkImage(widget.image!)
                      : null,
                  child: widget.image == null
                      ? const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white54,
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                // Name & Role
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.role.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Timer
                Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontFamily: 'monospace',
                  ),
                ),

                const Spacer(),

                // Call Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _controlButton(
                            Icon(_isMuted ? Icons.mic_off : Icons.mic),
                            "Mute",
                            _isMuted,
                            () => setState(() => _isMuted = !_isMuted),
                          ),
                          _controlButton(
                            const Icon(Icons.dialpad),
                            "Keypad",
                            false,
                            () {},
                          ),
                          _controlButton(
                            Icon(
                              _isSpeakerOn
                                  ? Icons.volume_up
                                  : Icons.volume_down,
                            ),
                            "Speaker",
                            _isSpeakerOn,
                            () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // End Call Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent,
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(
    Widget icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: isActive ? Colors.black : Colors.white,
              ),
              child: icon,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
