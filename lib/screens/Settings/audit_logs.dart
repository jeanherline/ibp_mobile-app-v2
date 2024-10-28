import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  _AuditLogPageState createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  late User? user;
  bool _isLoading = true;
  List<Map<String, dynamic>> auditLogs = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
    });

    if (user != null) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('audit_logs')
                .where('uid', isEqualTo: user!.uid)
                .orderBy('timestamp', descending: true)
                .get();

        List<Map<String, dynamic>> logs =
            snapshot.docs.map((doc) => doc.data()).toList();

        setState(() {
          auditLogs = logs;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching audit logs: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Function to format the timestamp
  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('EEE, MMM d, y h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Audit Logs'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : auditLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No audit logs found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = auditLogs[index];
                      return _buildAuditLogCard(log, screenWidth);
                    },
                  ),
      ),
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log, double screenWidth) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display action type
            Text(
              'Action: ${log['actionType'] ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF580049),
              ),
            ),
            const SizedBox(height: 8),

            // Display timestamp
            Text(
              'Timestamp: ${_formatTimestamp(log['timestamp'])}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Display IP address
            Text(
              'IP Address: ${log['metadata']?['ipAddress'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Display user agent
            Text(
              'User Agent: ${log['metadata']?['userAgent'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Display action and status from changes map
            if (log['changes'] != null && log['changes'] is Map)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action (from changes): ${log['changes']['action'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${log['changes']['status'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
