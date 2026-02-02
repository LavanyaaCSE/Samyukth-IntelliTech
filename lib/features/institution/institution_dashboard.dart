import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/app_colors.dart';

class InstitutionDashboard extends StatelessWidget {
  const InstitutionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Institution Insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsOverview(),
            const SizedBox(height: 32),
            Text(
              'Batch Performance Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildChartCard(),
            const SizedBox(height: 32),
            _buildSkillGapAnalysis(),
            const SizedBox(height: 32),
            _buildPlacementReadyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        _buildStatItem('Total Students', '120', Icons.people, AppColors.primary),
        const SizedBox(width: 16),
        _buildStatItem('Placed', '45', Icons.work, AppColors.secondary),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildChartCard() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          ColumnSeries<_ChartData, String>(
            dataSource: [
              _ChartData('Batch A', 85),
              _ChartData('Batch B', 72),
              _ChartData('Batch C', 90),
              _ChartData('Batch D', 65),
            ],
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            name: 'Avg Readiness %',
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          )
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSkillGapAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Critical Skill Gaps',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildGapItem('System Design', 65, AppColors.error),
        const SizedBox(height: 12),
        _buildGapItem('Advanced Java', 40, AppColors.accent),
        const SizedBox(height: 12),
        _buildGapItem('Communication', 20, AppColors.secondary),
      ],
    );
  }

  Widget _buildGapItem(String skill, int gap, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(skill, style: const TextStyle(fontSize: 14)),
            Text('$gap% Gap', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: gap / 100,
          color: color,
          backgroundColor: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPlacementReadyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready for Placement',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildStudentTile('John Doe', 'Batch A', '92%'),
        const SizedBox(height: 8),
        _buildStudentTile('Sarah Smith', 'Batch C', '89%'),
      ],
    );
  }

  Widget _buildStudentTile(String name, String batch, String score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.primary, child: Text(name[0])),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(batch, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(score, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
