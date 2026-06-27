import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/reporting_service.dart';
import '../../services/pdf_export_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with SingleTickerProviderStateMixin {
  final ReportingService _reportingService = ReportingService();
  final PdfExportService _pdfExportService = PdfExportService();
  UserReportData? _reportData;
  bool _isLoading = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadData();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportingService.generateUserReport();
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  void _exportCsv() {
    if (_reportData == null) return;
    final String csv = _reportData!.toCsvString();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CSV Data Generated', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
    try {
      await _pdfExportService.generateAndSharePdf(_reportData!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard & Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C1052), Color(0xFF100720)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _reportData == null
                ? const Center(child: Text('Failed to load report data.', style: TextStyle(color: Colors.white)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.deepPurple,
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20.0),
                        children: [
                          _buildPremiumHeader(),
                          const SizedBox(height: 24),
                          _buildGlassSummaryCards(),
                          const SizedBox(height: 24),
                          _buildGlassPieChart(),
                          const SizedBox(height: 24),
                          _buildGlassBarChart(),
                          const SizedBox(height: 100), 
                        ],
                      ),
                    ),
                  ),
        ),
      ),
      floatingActionButton: _isLoading || _reportData == null ? null : Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'csvBtn',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2C1052),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
            child: const Icon(Icons.data_object),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'pdfBtn',
            backgroundColor: const Color(0xFFA855F7), // Neon purple
            foregroundColor: Colors.white,
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Activity',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        ),
        SizedBox(height: 4),
        Text(
          'Track your performance and engagement',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildGlassStatCard('Active Listings', _reportData!.activeListings.toString(), Icons.storefront, const Color(0xFF60A5FA)),
        _buildGlassStatCard('Total Views', _reportData!.totalViews.toString(), Icons.visibility, const Color(0xFFA855F7)),
        _buildGlassStatCard('Total Saves', _reportData!.totalSaves.toString(), Icons.favorite, const Color(0xFFF472B6)),
        _buildGlassStatCard('Requests Sent', _reportData!.totalRequestsSent.toString(), Icons.outbox, const Color(0xFF34D399)),
      ],
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color iconColor) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withAlpha(51), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPieChart() {
    final Map<String, int> categories = _reportData!.categoryDistribution;
    
    if (categories.isEmpty) return const SizedBox.shrink();

    final List<Color> colors = [const Color(0xFF60A5FA), const Color(0xFFA855F7), const Color(0xFF34D399), const Color(0xFFF472B6), const Color(0xFFFBBF24)];

    int colorIndex = 0;
    final List<PieChartSectionData> sections = categories.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: Text(e.key, style: const TextStyle(fontSize: 8, color: Colors.white)),
        ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGlassBarChart() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Engagement metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_reportData!.totalViews > _reportData!.totalSaves ? _reportData!.totalViews.toDouble() : _reportData!.totalSaves.toDouble()) * 1.2 + 5,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem('${rod.toY.toInt()}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                    }
                  )
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8), 
                          child: Text(value.toInt() == 0 ? 'Views' : 'Saves', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _reportData!.totalViews.toDouble(),
                        gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFC084FC)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _reportData!.totalSaves.toDouble(),
                        gradient: const LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFF9A8D4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
