import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // State untuk suis-suis kau
  bool e2eEnabled = true;
  bool biometricEnabled = true;
  bool backupEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SECURITY STATUS BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.gpp_good, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Status: Protected', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('All security features are enabled', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. SECURITY SETTINGS (Toggles)
          const Text('Security Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildSettingSwitch('End-to-End Encryption', 'AES-256 encryption for all data', Icons.lock_outline, e2eEnabled, (val) => setState(() => e2eEnabled = val)),
                const Divider(height: 1, indent: 60),
                _buildSettingSwitch('Biometric Lock', 'FaceID / Fingerprint authentication', Icons.fingerprint, biometricEnabled, (val) => setState(() => biometricEnabled = val)),
                const Divider(height: 1, indent: 60),
                _buildSettingSwitch('Automatic Data Backup', 'Secure backup to Firebase', Icons.cloud_done_outlined, backupEnabled, (val) => setState(() => backupEnabled = val)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3. DATA CONFIDENTIALITY (Audit Log)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Confidentiality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    Text('Who has accessed patient communication history', style: TextStyle(fontSize: 12, color: Colors.blueGrey[400])),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textDark, side: BorderSide(color: Colors.grey.shade300)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Jadual Audit Log (Responsive untuk Mobile)
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildAuditHeader(),
                const Divider(height: 1),
                _buildAuditRow('Dr. Sarah Chen', 'Therapist', 'Viewed communication log', 'Today, 10:45 AM', 'iPad Pro', 'Verified'),
                const Divider(height: 1),
                _buildAuditRow('Nurse Ahmad', 'Caregiver', 'Exported weekly report', 'Today, 09:30 AM', 'iPhone 15', 'Verified'),
                const Divider(height: 1),
                _buildAuditRow('Admin User', 'Administrator', 'Modified security settings', 'Yesterday, 2:00 PM', 'Windows PC', 'Review'),
                const Divider(height: 1),
                _buildAuditRow('Nurse Fatimah', 'Caregiver', 'Viewed patient mood trends', 'Apr 12, 11:20 AM', 'Android Tablet', 'Verified'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. PDPA COMPLIANT BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDPA Compliant', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('All patient data is handled in accordance with the Personal Data Protection Act. Data is encrypted at rest and in transit.', style: TextStyle(color: Colors.blue.shade700, fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper: Bikin Suis Settings
  Widget _buildSettingSwitch(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.blueGrey[400])),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      ),
      activeColor: AppTheme.primaryBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // Helper: Header Jadual Audit
  Widget _buildAuditHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          Expanded(flex: 3, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
        ],
      ),
    );
  }

  // Helper: Baris Data Audit
  Widget _buildAuditRow(String name, String role, String action, String time, String device, String status) {
    bool isVerified = status == 'Verified';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                Text(role, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                Text('$time • $device', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isVerified ? Colors.green.shade200 : Colors.orange.shade200),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVerified ? Colors.green.shade700 : Colors.orange.shade700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}