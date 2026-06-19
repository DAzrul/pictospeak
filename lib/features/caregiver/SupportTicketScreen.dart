import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _msgController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitTicket() async {
    if (_msgController.text.isEmpty) return;
    setState(() => _isSending = true);

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('support_tickets').add({
      'user_email': user?.email,
      'message': _msgController.text,
      'status': 'OPEN', // 🚀 Workflow dimulakan
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isSending = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent to Admin!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Support & Request")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _msgController, maxLines: 5, decoration: const InputDecoration(hintText: "Contoh: Tolong tambah gambar Nasi Lemak...")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isSending ? null : _submitTicket, child: const Text("HANTAR REQUEST")),
          ],
        ),
      ),
    );
  }
}