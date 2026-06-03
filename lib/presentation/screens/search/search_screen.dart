import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/channels_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  String _query = '';
  bool _isListening = false;
  bool _speechAvailable = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _query = result.recognizedWords;
            _searchCtrl.text = _query;
          });
        },
        localeId: 'ar_SA',
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن قناة أو برنامج...',
            hintStyle:
                const TextStyle(fontFamily: 'Cairo', color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: _isListening
                ? const Icon(Icons.mic, color: Colors.redAccent)
                : IconButton(
                    icon: const Icon(Icons.mic_none, color: Colors.white54),
                    onPressed: _toggleListening,
                  ),
          ),
          onChanged: (val) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState(() => _query = val);
            });
          },
        ),
      ),
      body: channelsAsync.when(
        data: (channels) {
          if (_query.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.white12),
                  SizedBox(height: 12),
                  Text(
                    'ابدأ بالكتابة أو استخدم الميكروفون',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white38,
                        fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final results = channels
              .where((c) =>
                  c.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off,
                      size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد نتائج لـ "$_query"',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white54,
                        fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (ctx, i) => _SearchResultItem(channel: results[i]),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (e, _) => Center(
            child: Text('خطأ: $e',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.red))),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Channel channel;
  const _SearchResultItem({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: channel.logoUrl != null
            ? Image.network(
                channel.logoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.tv, color: Colors.white54, size: 40),
              )
            : const Icon(Icons.tv, color: Colors.white54, size: 40),
      ),
      title: Text(
        channel.name,
        style: const TextStyle(
            fontFamily: 'Cairo', color: Colors.white),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        channel.category,
        style: const TextStyle(
            fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
        textDirection: TextDirection.rtl,
      ),
      trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF00E5FF)),
      onTap: () => context.push(
        AppConstants.routePlayer,
        extra: {
          'channelId': channel.id,
          'streamUrl': channel.currentStreamUrl ?? '',
          'channelName': channel.name,
          'channelLogo': channel.logoUrl,
        },
      ),
    );
  }
}
