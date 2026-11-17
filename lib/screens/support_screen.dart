
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final db = FirebaseFirestore.instance;
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  String category = 'Payment / Wallet';
  bool submitting = false;

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  final List<String> categories = [
    'Payment / Wallet',
    'Withdrawal',
    'Bonus',
    'Referral',
    'Premium Membership',
    'Account / Login',
    'Other',
  ];

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submitTicket() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please login first.');
      return;
    }

    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty) {
      showMessage('Please enter a subject.');
      return;
    }

    if (message.length < 10) {
      showMessage('Please explain your problem in at least 10 characters.');
      return;
    }

    setState(() => submitting = true);

    try {
      await db.collection('support_tickets').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'subject': subject,
        'category': category,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      subjectController.clear();
      messageController.clear();

      showMessage('Your support ticket has been submitted.');
    } catch (e) {
      showMessage('Ticket submission failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  String dateText(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      return '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Waiting...';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'replied':
      case 'closed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: const Center(child: Text('Please login to contact support.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent, color: Colors.white, size: 38),
                SizedBox(height: 10),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit your problem. Our support team will review your ticket.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Submit a Complaint',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Problem Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    value: category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    'Subject',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: subjectController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      hintText: 'Example: Withdrawal problem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Describe Your Problem',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: messageController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Write your problem in detail...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitting ? null : submitTicket,
                      icon: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        submitting ? 'Submitting...' : 'Submit Ticket',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'My Previous Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('support_tickets')
                .where('uid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Unable to load tickets. Please check your connection or Firestore Rules.',
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.toList();

              docs.sort((a, b) {
                final aDate = a.data()['createdAt'];
                final bDate = b.data()['createdAt'];
                final aTime = aDate is Timestamp
                    ? aDate.millisecondsSinceEpoch
                    : 0;
                final bTime = bDate is Timestamp
                    ? bDate.millisecondsSinceEpoch
                    : 0;
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: Text('You have not submitted any tickets yet.'),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? 'open').toString();

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['subject'] ?? 'Support Ticket',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor:
                                    statusColor(status).withOpacity(0.12),
                                labelStyle: TextStyle(
                                  color: statusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text('Ticket ID: ${doc.id}'),
                          Text('Category: ${data['category'] ?? 'Other'}'),
                          Text('Submitted: ${dateText(data['createdAt'])}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Your Message',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(data['message'] ?? ''),
                          const Divider(height: 22),
                          const Text(
                            'Admin Reply',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            (data['adminReply'] ?? '').toString().isEmpty
                                ? 'No reply yet. Please wait for our support team.'
                                : data['adminReply'].toString(),
                          ),
                          if (data['repliedAt'] != null)
                            Text(
                              'Replied: ${dateText(data['repliedAt'])}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
