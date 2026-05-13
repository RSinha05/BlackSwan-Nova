import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import 'simulation_screen.dart';
import 'news_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _instruments = [];
  bool _loading = true;
  String _filterClass = 'all';
  String _searchQuery = '';

  final _classLabels = {
    'all': 'All',
    'indian-stock': 'Indian Stocks',
    'global-index': 'Global Indices',
    'indian-index': 'Indian Indices',
    'us-stock': 'US Stocks',
    'commodity': 'Commodities',
    'forex': 'Forex',
  };

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    setState(() => _loading = true);
    try {
      _instruments = await SupabaseService.fetchInstruments();
    } catch (e) {
      debugPrint('Error loading instruments: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _instruments;
    if (_filterClass != 'all') {
      list = list.where((i) => i['cls'] == _filterClass).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((i) =>
              (i['name'] ?? '').toString().toLowerCase().contains(q) ||
              (i['ticker'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildInstrumentsPage(),
          const NewsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1321),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF00F0FF),
          unselectedItemColor: Colors.white.withValues(alpha: 0.3),
          selectedLabelStyle:
              GoogleFonts.spaceMono(fontSize: 9, letterSpacing: 1.5),
          unselectedLabelStyle:
              GoogleFonts.spaceMono(fontSize: 9, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'INSTRUMENTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'NEWS INTEL',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentsPage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00FF88),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF00FF88).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'BLACKSWAN NOVA',
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00F0FF),
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_instruments.length} ASSETS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: const Color(0xFF00FF88),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF111827),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                decoration: InputDecoration(
                  hintText: 'Search instruments...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.25)),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withValues(alpha: 0.25), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _classLabels.entries.map((e) {
                final active = _filterClass == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterClass = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
                        e.value,
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
              }).toList(),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Instrument list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00F0FF), strokeWidth: 2))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No instruments found',
                          style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInstruments,
                        color: const Color(0xFF00F0FF),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final inst = _filtered[index];
                            return _InstrumentTile(instrument: inst)
                                .animate()
                                .fadeIn(
                                    delay: (50 * (index % 15)).ms,
                                    duration: 300.ms)
                                .slideX(begin: 0.05);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _InstrumentTile extends StatelessWidget {
  final Map<String, dynamic> instrument;

  const _InstrumentTile({required this.instrument});

  Color _classColor(String cls) {
    switch (cls) {
      case 'indian-stock':
        return const Color(0xFF00F0FF);
      case 'global-index':
        return const Color(0xFF7B61FF);
      case 'indian-index':
        return const Color(0xFFFF9F43);
      case 'us-stock':
        return const Color(0xFF00FF88);
      case 'commodity':
        return const Color(0xFFFFD700);
      case 'forex':
        return const Color(0xFFFF6B9D);
      default:
        return const Color(0xFF00F0FF);
    }
  }

  String _classLabel(String cls) {
    switch (cls) {
      case 'indian-stock':
        return 'IND';
      case 'global-index':
        return 'IDX';
      case 'indian-index':
        return 'NSE';
      case 'us-stock':
        return 'US';
      case 'commodity':
        return 'CMD';
      case 'forex':
        return 'FX';
      default:
        return cls.toUpperCase().substring(0, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = instrument['cls'] ?? '';
    final color = _classColor(cls);
    final base = (instrument['base'] ?? 0).toDouble();
    final mu = (instrument['mu'] ?? 0).toDouble();
    final sig = (instrument['sig'] ?? 0).toDouble();
    final ccy = instrument['ccy'] ?? '\$';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SimulationScreen(instrument: instrument),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF111827),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            // Class badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(
                  _classLabel(cls),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & ticker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instrument['ticker'] ?? '',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Price & params
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$ccy${base.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'μ ${(mu * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: const Color(0xFF00FF88).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'σ ${(sig * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: const Color(0xFFFF9F43).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.15), size: 18),
          ],
        ),
      ),
    );
  }
}
