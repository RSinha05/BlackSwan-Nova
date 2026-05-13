import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SimulationScreen extends StatefulWidget {
  final Map<String, dynamic> instrument;

  const SimulationScreen({super.key, required this.instrument});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulation params
  int _horizon = 1;
  int _paths = 5000;
  double _investment = 1000000;

  // Results
  Map<String, dynamic>? _simResult;
  Map<String, dynamic>? _stressResult;
  bool _simLoading = false;
  bool _stressLoading = false;

  final _fmt = NumberFormat.compact();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _runSimulation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _s0 => (widget.instrument['base'] ?? 100).toDouble();
  double get _mu => (widget.instrument['mu'] ?? 0.1).toDouble();
  double get _sigma => (widget.instrument['sig'] ?? 0.2).toDouble();
  String get _cls => widget.instrument['cls'] ?? 'stock';

  Future<void> _runSimulation() async {
    setState(() => _simLoading = true);
    try {
      _simResult = await ApiService.simulate(
        s0: _s0,
        mu: _mu,
        sigma: _sigma,
        horizon: _horizon,
        paths: _paths,
        investment: _investment,
        assetClass: _cls,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation error: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
    if (mounted) setState(() => _simLoading = false);
  }

  Future<void> _runStress() async {
    setState(() => _stressLoading = true);
    try {
      _stressResult = await ApiService.stressTest(
        s0: _s0,
        mu: _mu,
        sigma: _sigma,
        shockPct: 0.30,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stress test error: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
    if (mounted) setState(() => _stressLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ccy = widget.instrument['ccy'] ?? '\$';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.instrument['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.instrument['ticker']}  ·  $ccy${_s0.toStringAsFixed(2)}',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00F0FF),
          unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
          indicatorColor: const Color(0xFF00F0FF),
          indicatorWeight: 2,
          labelStyle:
              GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1.5),
          tabs: const [
            Tab(text: 'MONTE CARLO'),
            Tab(text: 'STRESS TEST'),
            Tab(text: 'PARAMS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonteCarloTab(ccy),
          _buildStressTab(ccy),
          _buildParamsTab(ccy),
        ],
      ),
    );
  }

  Widget _buildMonteCarloTab(String ccy) {
    if (_simLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: Color(0xFF00F0FF), strokeWidth: 2),
            SizedBox(height: 16),
            Text('Running Monte Carlo...',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (_simResult == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _runSimulation,
          child: const Text('RUN SIMULATION'),
        ),
      );
    }

    final var95 = (_simResult!['var95'] as num).toDouble();
    final cvar95 = (_simResult!['cvar95'] as num).toDouble();
    final cfVar95 = (_simResult!['cf_var95'] as num).toDouble();
    final expectedReturn = (_simResult!['expected_return'] as num).toDouble();
    final bestPath = (_simResult!['best_path'] as num).toDouble();
    final worstPath = (_simResult!['worst_path'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk metrics cards
          _sectionLabel('RISK METRICS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _metricCard(
                      'VaR 95%', '$ccy${_fmt.format(var95)}',
                      color: const Color(0xFFFF4757))),
              const SizedBox(width: 10),
              Expanded(
                  child: _metricCard(
                      'CVaR 95%', '$ccy${_fmt.format(cvar95)}',
                      color: const Color(0xFFFF6B9D))),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _metricCard(
                      'CF-VaR 95%', '$ccy${_fmt.format(cfVar95)}',
                      color: const Color(0xFFFF9F43))),
              const SizedBox(width: 10),
              Expanded(
                  child: _metricCard(
                      'E[Return]', '$ccy${_fmt.format(expectedReturn)}',
                      color: const Color(0xFF00FF88))),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _metricCard('Best Path', '$ccy${_fmt.format(bestPath)}',
                      color: const Color(0xFF00FF88))),
              const SizedBox(width: 10),
              Expanded(
                  child: _metricCard(
                      'Worst Path', '$ccy${_fmt.format(worstPath)}',
                      color: const Color(0xFFFF4757))),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Monte Carlo paths chart
          _sectionLabel('PRICE PATHS'),
          const SizedBox(height: 10),
          Container(
            height: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF111827),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: _buildPathsChart(),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 24),

          // PnL distribution
          _sectionLabel('PnL DISTRIBUTION'),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF111827),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: _buildDistributionChart(ccy),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPathsChart() {
    final paths = _simResult!['paths'] as List;
    // Show max 30 paths for mobile performance
    final displayPaths = paths.take(30).toList();

    // Downsample each path for rendering efficiency
    const maxPoints = 60;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: _s0 * 0.5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: displayPaths.asMap().entries.map((entry) {
          final pathData = List<num>.from(entry.value);
          final step = (pathData.length / maxPoints).ceil().clamp(1, pathData.length);

          final spots = <FlSpot>[];
          for (int i = 0; i < pathData.length; i += step) {
            spots.add(FlSpot(i.toDouble(), pathData[i].toDouble()));
          }

          final isBull = pathData.last > pathData.first;
          return LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 0.5,
            dotData: const FlDotData(show: false),
            color: isBull
                ? const Color(0xFF00FF88).withValues(alpha: 0.25)
                : const Color(0xFFFF4757).withValues(alpha: 0.2),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionChart(String ccy) {
    final pnl = List<num>.from(_simResult!['pnl'] ?? []);
    if (pnl.isEmpty) return const SizedBox();

    // Build histogram
    const bins = 40;
    final sorted = pnl.map((e) => e.toDouble()).toList()..sort();
    final minVal = sorted.first;
    final maxVal = sorted.last;
    final range = maxVal - minVal;
    if (range == 0) return const SizedBox();

    final binWidth = range / bins;
    final counts = List.filled(bins, 0);
    for (final v in sorted) {
      final idx = ((v - minVal) / binWidth).floor().clamp(0, bins - 1);
      counts[idx]++;
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        alignment: BarChartAlignment.center,
        groupsSpace: 1,
        barGroups: counts.asMap().entries.map((entry) {
          final binCenter = minVal + (entry.key + 0.5) * binWidth;
          final isLoss = binCenter < 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                width: (MediaQuery.of(context).size.width - 64) / bins - 1,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(2)),
                color: isLoss
                    ? const Color(0xFFFF4757).withValues(alpha: 0.6)
                    : const Color(0xFF00FF88).withValues(alpha: 0.6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStressTab(String ccy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('STRESS SCENARIO'),
          const SizedBox(height: 12),
          Text(
            'Simulates a 30% adverse shock with 2x volatility spike and measures recovery trajectory using GARCH mean-reversion.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Run button
          if (_stressResult == null && !_stressLoading)
            Center(
              child: GestureDetector(
                onTap: _runStress,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.4)),
                    gradient: LinearGradient(colors: [
                      const Color(0xFFFF4757).withValues(alpha: 0.1),
                      const Color(0xFFFF6B9D).withValues(alpha: 0.05),
                    ]),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFFFF4757), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'RUN STRESS TEST',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4757),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

          if (_stressLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                    color: Color(0xFFFF4757), strokeWidth: 2),
              ),
            ),

          if (_stressResult != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _metricCard(
                  'Shocked Price',
                  '$ccy${(_stressResult!['shocked_price'] as num).toDouble().toStringAsFixed(2)}',
                  color: const Color(0xFFFF4757),
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _metricCard(
                  'Recovery (months)',
                  (_stressResult!['recovery_months'] as num).toDouble() == -1
                      ? 'N/A'
                      : '${(_stressResult!['recovery_months'] as num).toDouble().toStringAsFixed(1)}m',
                  color: const Color(0xFFFF9F43),
                )),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _metricCard(
                  'Recovery (days)',
                  (_stressResult!['recovery_days'] as num).toDouble() == -1
                      ? 'N/A'
                      : '${(_stressResult!['recovery_days'] as num).toDouble().toStringAsFixed(0)}d',
                  color: const Color(0xFF7B61FF),
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _metricCard(
                  'P(Recovery 3yr)',
                  '${((_stressResult!['prob_recovery_3yr'] as num).toDouble() * 100).toStringAsFixed(1)}%',
                  color: const Color(0xFF00FF88),
                )),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildParamsTab(String ccy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SIMULATION PARAMETERS'),
          const SizedBox(height: 16),

          // Horizon
          _paramSlider(
            label: 'HORIZON',
            value: _horizon.toDouble(),
            min: 1,
            max: 5,
            suffix: ' yr',
            divisions: 4,
            onChanged: (v) => setState(() => _horizon = v.round()),
          ),
          const SizedBox(height: 16),

          // Paths
          _paramSlider(
            label: 'PATHS',
            value: _paths.toDouble(),
            min: 1000,
            max: 10000,
            suffix: '',
            divisions: 9,
            onChanged: (v) =>
                setState(() => _paths = (v / 1000).round() * 1000),
          ),
          const SizedBox(height: 16),

          // Investment
          _paramSlider(
            label: 'INVESTMENT ($ccy)',
            value: _investment,
            min: 100000,
            max: 10000000,
            suffix: '',
            divisions: 99,
            onChanged: (v) =>
                setState(() => _investment = (v / 100000).round() * 100000),
          ),
          const SizedBox(height: 10),
          Text(
            '$ccy${_fmt.format(_investment)}',
            style: GoogleFonts.spaceMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00F0FF),
            ),
          ),

          const SizedBox(height: 32),

          // Model details
          _sectionLabel('MODEL CONFIGURATION'),
          const SizedBox(height: 12),
          _detailRow('Drift (μ)', '${(_mu * 100).toStringAsFixed(1)}%'),
          _detailRow('Volatility (σ)', '${(_sigma * 100).toStringAsFixed(1)}%'),
          _detailRow(
              'Risk-Free Rate', '${((widget.instrument['rf'] ?? 0.045) * 100).toStringAsFixed(1)}%'),
          _detailRow('GARCH α', '0.09'),
          _detailRow('GARCH β', '0.90'),
          _detailRow('Jump Intensity (λ)',
              _cls.contains('stock') || _cls.contains('index')
                  ? '4/yr'
                  : '0'),
          _detailRow('Jump Mean (μⱼ)',
              _cls.contains('stock') || _cls.contains('index')
                  ? '-8%'
                  : 'N/A'),
          _detailRow('Jump Vol (σⱼ)',
              _cls.contains('stock') || _cls.contains('index')
                  ? '6%'
                  : 'N/A'),

          const SizedBox(height: 32),

          // Run button
          Center(
            child: GestureDetector(
              onTap: _simLoading ? null : _runSimulation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    const Color(0xFF7B61FF).withValues(alpha: 0.15),
                  ]),
                  border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                ),
                child: Text(
                  _simLoading ? 'RUNNING...' : 'RE-RUN SIMULATION',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00F0FF),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _paramSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}$suffix',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00F0FF),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF00F0FF),
            inactiveTrackColor:
                const Color(0xFF00F0FF).withValues(alpha: 0.1),
            thumbColor: const Color(0xFF00F0FF),
            overlayColor:
                const Color(0xFF00F0FF).withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 2,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
