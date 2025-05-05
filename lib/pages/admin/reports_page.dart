import 'package:flutter/material.dart';
import 'attendance.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Analytics',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildReportOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOptions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Adjusted aspect ratio to prevent overflow
      children: [
        _buildReportCard(
          context,
          title: 'Daily Report',
          icon: Icons.assignment,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DailyReportPage()),
            );
          },
        ),
        _buildReportCard(
          context,
          title: 'Attendance',
          icon: Icons.people,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendancePage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24, // Reduced icon size
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyReportPage extends StatelessWidget {
  const DailyReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildReportTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Select Date',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8), // Reduced spacing
        SizedBox(
          width: 100, // Fixed width for button
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18), // Smaller icon
            label: const Text('Export', style: TextStyle(fontSize: 14)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard('Total Trips', '12', Colors.blue),
          const SizedBox(width: 8),
          _buildSummaryCard('Completed', '10', Colors.green),
          const SizedBox(width: 8),
          _buildSummaryCard('Delayed', '2', Colors.orange),
          const SizedBox(width: 8),
          _buildSummaryCard('Cancelled', '0', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return SizedBox(
      width: 120, // Fixed width
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20, // Slightly smaller
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12, // Smaller font
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 16,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(
                  label: Text('Trip ID', style: TextStyle(fontSize: 12)),
                ),
                DataColumn(
                  label: Text('Route', style: TextStyle(fontSize: 12)),
                ),
                DataColumn(
                  label: Text('Driver', style: TextStyle(fontSize: 12)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(fontSize: 12)),
                ),
                DataColumn(
                  label: Text('Delay', style: TextStyle(fontSize: 12)),
                ),
              ],
              rows: const [
                DataRow(
                  cells: [
                    DataCell(Text('TR-001', style: TextStyle(fontSize: 12))),
                    DataCell(Text('North', style: TextStyle(fontSize: 12))),
                    DataCell(Text('John', style: TextStyle(fontSize: 12))),
                    DataCell(Text('Completed', style: TextStyle(fontSize: 12))),
                    DataCell(Text('5 min', style: TextStyle(fontSize: 12))),
                  ],
                ),
                DataRow(
                  cells: [
                    DataCell(Text('TR-002', style: TextStyle(fontSize: 12))),
                    DataCell(Text('South', style: TextStyle(fontSize: 12))),
                    DataCell(Text('Jane', style: TextStyle(fontSize: 12))),
                    DataCell(Text('Delayed', style: TextStyle(fontSize: 12))),
                    DataCell(Text('15 min', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
