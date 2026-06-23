import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reporting_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final ReportingService _reportingService = ReportingService();
  UserReportData? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy the CSV data below:'),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard!')),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _exportCsv,
        icon: const Icon(Icons.download),
        label: const Text('Export CSV'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(child: Text('Failed to load report data.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPieChartSection(),
                      const SizedBox(height: 24),
                      _buildBarChartSection(),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Listings', _reportData!.totalListings.toString(), Icons.storefront, Colors.blue),
            _buildStatCard('Total Views', _reportData!.totalViews.toString(), Icons.visibility, Colors.purple),
            _buildStatCard('Total Saves', _reportData!.totalSaves.toString(), Icons.favorite, Colors.pink),
            _buildStatCard('Requests Sent', _reportData!.totalRequestsSent.toString(), Icons.outbox, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    final Map<String, int> categories = _reportData!.categoryDistribution;
    
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Color> colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal
    ];

    int colorIndex = 0;
    final List<PieChartSectionData> sections = categories.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n(${e.value})',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Listings by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement (Views vs Saves)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_reportData!.totalViews > _reportData!.totalSaves 
                      ? _reportData!.totalViews.toDouble() 
                      : _reportData!.totalSaves.toDouble()) * 1.2 + 5,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Views'));
                            case 1:
                              return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Saves'));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _reportData!.totalViews.toDouble(),
                          color: Colors.purple,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _reportData!.totalSaves.toDouble(),
                          color: Colors.pink,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
