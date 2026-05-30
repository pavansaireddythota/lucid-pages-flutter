import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ReaderScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final int episodeIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    required this.episodeIndex,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int currentEpisodeIndex;

  @override
  void initState() {
    super.initState();
    currentEpisodeIndex = widget.episodeIndex;
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.book['episodes'] as List;
    final episode = episodes[currentEpisodeIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            /// Header featuring a Native Return Back Navigation Trigger
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    color: Colors.black12,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF222222)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode['title'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chapter ${currentEpisodeIndex + 1} of ${episodes.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Content Text Panel
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Html(
                  data: episode['content'] ?? '',
                  style: {
                    "p": Style(
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.6),
                    ),
                    "b": Style(
                      fontWeight: FontWeight.bold,
                    ),
                    "i": Style(
                      fontStyle: FontStyle.italic,
                    ),
                  },
                ),
              ),
            ),

            /// Bottom Navigation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black12,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: currentEpisodeIndex == 0
                          ? null
                          : () {
                              setState(() {
                                currentEpisodeIndex--;
                              });
                            },
                      child: const Text('← Prev'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: currentEpisodeIndex == episodes.length - 1
                          ? null
                          : () {
                              setState(() {
                                currentEpisodeIndex++;
                              });
                            },
                      child: const Text('Next →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}