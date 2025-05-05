import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceFilters(),
            const SizedBox(height: 16),
            _buildAttendanceSummary(),
            const SizedBox(height: 16),
            _buildAttendanceTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'From',
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'To',
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: 'all',
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Drivers'),
                      ),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export', style: TextStyle(fontSize: 14)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard('Total', '24', Colors.blue),
          const SizedBox(width: 8),
          _buildSummaryCard('Present', '22', Colors.green),
          const SizedBox(width: 8),
          _buildSummaryCard('Absent', '2', Colors.red),
          const SizedBox(width: 8),
          _buildSummaryCard('Leave', '1', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return SizedBox(
      width: 100, // Fixed width
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 12,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 40,
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(fontSize: 12),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('In')),
                DataColumn(label: Text('Out')),
              ],
              rows: const [
                DataRow(
                  cells: [
                    DataCell(Text('DR-001')),
                    DataCell(Text('John')),
                    DataCell(Text('05-01')),
                    DataCell(
                      Chip(
                        label: Text('Present', style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    DataCell(Text('08:00')),
                    DataCell(Text('17:00')),
                  ],
                ),
                DataRow(
                  cells: [
                    DataCell(Text('DR-002')),
                    DataCell(Text('Jane')),
                    DataCell(Text('05-01')),
                    DataCell(
                      Chip(
                        label: Text('Absent', style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.red,
                      ),
                    ),
                    DataCell(Text('-')),
                    DataCell(Text('-')),
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
