import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// URL launching handled inline
import '../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _articles = [];
  Map<String, dynamic>? _sentiment;
  bool _loading = true;
  String _region = 'all';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchNews(region: _region),
        ApiService.sentimentSummary(),
      ]);
      _articles =
          List<Map<String, dynamic>>.from(results[0]['articles'] ?? []);
      _sentiment = results[1] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('News error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _sentimentColor(String label) {
    switch (label) {
      case 'Bullish':
        return const Color(0xFF00FF88);
      case 'Bearish':
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFFFF9F43);
    }
  }

  IconData _sentimentIcon(String label) {
    switch (label) {
      case 'Bullish':
        return Icons.trending_up;
      case 'Bearish':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'NEWS INTELLIGENCE',
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00F0FF),
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          // Sentiment summary bar
          if (_sentiment != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF111827),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  _sentimentChip(
                    'Bullish',
                    '${_sentiment!['bullish_pct']}%',
                    const Color(0xFF00FF88),
                  ),
                  const SizedBox(width: 10),
                  _sentimentChip(
                    'Neutral',
                    '${_sentiment!['neutral_pct']}%',
                    const Color(0xFFFF9F43),
                  ),
                  const SizedBox(width: 10),
                  _sentimentChip(
                    'Bearish',
                    '${_sentiment!['bearish_pct']}%',
                    const Color(0xFFFF4757),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_sentiment!['article_count']}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        'articles',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Region filters
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _filterChip('all', 'All'),
                _filterChip('global', 'Global'),
                _filterChip('india', 'India'),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Articles
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00F0FF), strokeWidth: 2))
                : _articles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            Text(
                              'No articles available',
                              style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check that the backend is running',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNews,
                        color: const Color(0xFF00F0FF),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _articles.length,
                          itemBuilder: (context, index) {
                            return _ArticleTile(
                              article: _articles[index],
                              sentimentColor: _sentimentColor,
                              sentimentIcon: _sentimentIcon,
                            )
                                .animate()
                                .fadeIn(
                                    delay: (40 * (index % 10)).ms,
                                    duration: 300.ms)
                                .slideY(begin: 0.03);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final active = _region == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _region = value);
          _loadNews();
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active
                ? const Color(0xFF00F0FF).withValues(alpha: 0.12)
                : const Color(0xFF111827),
            border: Border.all(
              color: active
                  ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? const Color(0xFF00F0FF)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sentimentChip(String label, String pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pct,
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final Map<String, dynamic> article;
  final Color Function(String) sentimentColor;
  final IconData Function(String) sentimentIcon;

  const _ArticleTile({
    required this.article,
    required this.sentimentColor,
    required this.sentimentIcon,
  });

  @override
  Widget build(BuildContext context) {
    final label = article['sentiment_label'] ?? 'Neutral';
    final color = sentimentColor(label);
    final tickers = List<String>.from(article['tickers'] ?? []);

    return GestureDetector(
      onTap: () {
        final urlStr = article['url'] ?? '';
        if (urlStr.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(urlStr, style: const TextStyle(fontSize: 11)),
              backgroundColor: const Color(0xFF111827),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF111827),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source & time
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sentimentIcon(label), color: color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  article['source'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const Spacer(),
                Text(
                  article['time_ago'] ?? '',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              article['title'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if ((article['summary'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                article['summary'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tickers
            if (tickers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tickers.take(4).map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                      border: Border.all(
                          color: const Color(0xFF7B61FF)
                              .withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: const Color(0xFF7B61FF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
