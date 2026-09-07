import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DataHandlingScreen extends StatelessWidget {
  const DataHandlingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rrBg,
      appBar: AppBar(
        backgroundColor: context.rrBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.rrT2, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Data Handling',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.rrT1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User Agreement & Privacy Statement',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.rrT1)),
              const SizedBox(height: 16),
              Text(
                'Last Updated: September 2026\n\n'
                'This comprehensive Data Handling User Agreement governs the collection, processing, storage, and erasure of your personal and health-related data within the SainikSaathi platform. By using this application, you consent to these terms.',
                style: TextStyle(fontSize: 14, color: context.rrT3, height: 1.5),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, '1. Data Collection & Purpose'),
              _sectionBody(context,
                  'SainikSaathi collects wellness check-ins (sleep, physical, focus, and overall readiness scores) and optional text notes. This data is strictly used to monitor unit readiness, allocate welfare resources, and provide timely, confidential support. Your inputs directly influence unit health analytics but are not used for formal performance appraisals.'),
              const SizedBox(height: 16),
              _sectionTitle(context, '2. Cryptographic Security & Storage'),
              _sectionBody(context,
                  'All personal data, including text notes and check-in history, is encrypted at rest using AES-256 encryption. Your unique service identity is pseudonymized. Data transmitted to our secure servers is protected via TLS 1.3. Local device data is secured using platform-specific Secure Storage mechanisms (Keychain/Keystore).'),
              const SizedBox(height: 16),
              _sectionTitle(context, '3. Data Access & Sharing'),
              _sectionBody(context,
                  'Your individual readiness data is accessible only by authorized welfare officers and unit commanders through a secure dashboard, strictly on a need-to-know basis. SainikSaathi does NOT share your data with third-party advertisers or external agencies. Anonymized, aggregated data may be used for statistical analysis at the command level.'),
              const SizedBox(height: 16),
              _sectionTitle(context, '4. Right to Erasure (Data Deletion)'),
              _sectionBody(context,
                  'You maintain full sovereignty over your personal data. At any time, you may exercise your "Right to Erasure" by navigating to Settings > Delete all my data. Initiating this action triggers a cryptographic erasure: all your historical check-ins, metrics, and assessments are permanently deleted from our servers. Your device will be unlinked, and your account will be deactivated.'),
              const SizedBox(height: 16),
              _sectionTitle(context, '5. Local vs Server Data'),
              _sectionBody(context,
                  'For offline capability, limited check-in history is cached on your device. Deactivating the device or logging out will clear this local cache. Server-side deletion ensures your records are purged globally across all backup states in accordance with our 7-day retention sweep policy.'),
              const SizedBox(height: 16),
              _sectionTitle(context, '6. Consent & Revocation'),
              _sectionBody(context,
                  'By continuing to use SainikSaathi, you actively consent to this data processing model. You may revoke this consent at any time by deleting your data and discontinuing the use of the app.'),
              const SizedBox(height: 32),
              Center(
                child: Text('Confidential & Restricted',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.rrT2)),
    );
  }

  Widget _sectionBody(BuildContext context, String body) {
    return Text(body,
        style: TextStyle(
            fontSize: 14, color: context.rrT4, height: 1.6));
  }
}
