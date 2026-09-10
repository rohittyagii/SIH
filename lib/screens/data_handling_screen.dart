import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/translations.dart';

class DataHandlingScreen extends ConsumerWidget {
  const DataHandlingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.rrBg,
      appBar: AppBar(
        backgroundColor: context.rrBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.rrT2, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(tr('Data Handling', ref),
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
              Text(tr('User Agreement & Privacy Statement', ref),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.rrT1)),
              const SizedBox(height: 16),
              Text(
                tr('Last Updated: September 2026\n\n'
                'COMPLIANCE STATEMENT AND OVERARCHING DECLARATION OF PRIVACY COMMITMENT: SainikSaathi, hereinafter referred to as "the Application," "the Service," or "the Platform," is fundamentally and structurally architected with a privacy-first, security-by-design, and default-deny overarching paradigm, strictly, unequivocally, and continuously adhering to the highest, most stringent national data protection, privacy, and information security standards mandated by the Government of India. This uncompromising commitment explicitly includes, but is not limited to, absolute, verifiable, and audited full compliance with the Digital Personal Data Protection Act, 2023 (DPDP Act), the Information Technology Act, 2000 (IT Act) and its corresponding rules, the guidelines issued by the Indian Computer Emergency Response Team (CERT-In), and military-grade, defense-in-depth information security protocols promulgated by national defense cybersecurity agencies under the Ministry of Defence. We hereby categorically guarantee, warrant, and affirm that your personal, biometric, behavioral, and telemetry data is handled, processed, transmitted, and stored with uncompromising transparency, absolute purpose limitation, data minimization, and robust, state-of-the-art cryptographic safeguards, thereby ensuring that your fundamental, inalienable right to privacy is proactively, continuously, and preemptively protected at all times, in all states (at rest, in transit, and in use), strictly within the legal jurisdiction of the Republic of India.', ref),
                style: TextStyle(
                    fontSize: 14,
                    color: context.rrT3,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, ref,
                  '1. Comprehensive Data Collection Matrix & Explicitly Defined Purpose Limitations'),
              _sectionBody(context, ref,
                  'SainikSaathi systematically, continuously, and asynchronously collects, aggregates, and processes a wide array of wellness telemetry and physiological indicators, which includes, but is not limited to, self-reported sleep quality metrics, qualitative and quantitative physical readiness scores, subjective focus and cognitive load indicators, and mathematically aggregated overall readiness indices derived through proprietary algorithmic processing. Additionally, optional, unstructured free-text notes may be voluntarily provided by the user via the designated input fields within the graphical user interface. This aforementioned data matrix is strictly, exclusively, and irrevocably purposed to monitor unit-level macro operational readiness, proactively and dynamically allocate targeted welfare, medical, and psychological support resources, and facilitate timely, confidential, and specifically tailored interventions by formally authorized, trained, and vetted support personnel. Your submitted inputs, both structured and unstructured, are solely and exclusively utilized to construct a holistic, longitudinal health matrix that directly, and only directly, informs anonymized unit health analytics and trend visualizations. Under no circumstances, scenarios, or operational exigencies are these metrics, individually or in aggregate, incorporated into, cross-referenced with, or utilized for formal performance appraisals, disciplinary tracking, career progression evaluations, promotion board reviews, or any administrative punitive actions.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '2. Cryptographic Security, Immutable Storage Architecture, and Key Management Protocols'),
              _sectionBody(context, ref,
                  'Information security and data sovereignty are our absolute, uncompromising, and paramount concerns, forming the bedrock of our operational mandate. All personal, physiological, and health-related data, encompassing all free-text notes, historical check-in time-series data, device telemetry, and biometric metadata, is rigorously encrypted at rest utilizing the Advanced Encryption Standard (AES) operating in Galois/Counter Mode (GCM) with a 256-bit cryptographic key, a standard approved for Top Secret and highly classified government data. Your unique service identity, prior to any transmission, storage, or processing, is subjected to irreversible cryptographic pseudonymization and salted hashing utilizing the Argon2id key derivation function, ensuring that your raw identity is mathematically decoupled from your health telemetry. Data in transit between the client application and our secure, geographically sovereign, and physically isolated server infrastructure is shielded via TLS 1.3 cryptographic protocols, strictly enforcing perfect forward secrecy (PFS), utilizing Elliptic Curve Diffie-Hellman Ephemeral (ECDHE) key exchange and strictly verified, non-expired X.509 digital certificates. On your local mobile endpoint device, all cached data is strictly isolated within the application sandbox and secured utilizing hardware-backed, platform-specific Secure Storage mechanisms—specifically leveraging the Secure Enclave on Apple devices via the iOS Keychain, and the Trusted Execution Environment (TEE) on Android devices via the Android Keystore System—rendering the data fundamentally inaccessible to unauthorized applications, malicious actors, or even the operating system itself in a compromised state.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '3. Rigorous Role-Based Data Access Control, Auditing, and Zero-Sharing Policy'),
              _sectionBody(context, ref,
                  'Access to your individual, unaggregated readiness data operates strictly and exclusively under a rigorous, fine-grained Role-Based Access Control (RBAC) and Attribute-Based Access Control (ABAC) multi-layered security model. It is mathematically and programmatically accessible exclusively by formally authorized, specifically appointed welfare officers, explicitly designated unit commanders with active command authority, and specialized medical or psychological support staff. This access is granted solely through a highly secure, multi-factor authenticated (MFA), and comprehensively audited administrative dashboard, and is strictly enforced on a verified "need-to-know" basis. Every single access attempt, whether successful or denied, is immutably logged in a tamper-evident audit trail for continuous security monitoring and forensic analysis. SainikSaathi enforces a draconian, uncompromising, and strict zero-sharing, zero-monetization policy: we do NOT, will not, and have never sold, licensed, rented, leased, shared, bartered, or otherwise exposed your personal data, metadata, or derived insights to third-party advertisers, external data brokers, commercial analytics platforms, or any unauthorized commercial entities under any circumstances whatsoever. Highly anonymized, heavily aggregated data sets, utilizing differential privacy techniques and completely stripped of all Personally Identifiable Information (PII) and Protected Health Information (PHI), may be generated solely for macro-level statistical analysis, epidemiological trend spotting, and strategic policy formulation at the highest levels of command.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '4. Absolute Right to Erasure, Data Sovereignty, and Cryptographic Annihilation'),
              _sectionBody(context, ref,
                  'You maintain absolute, unconditional, and perpetual sovereignty over your personal data footprint generated within this application. At any given time, without requiring any justification, explanation, or administrative approval, you possess the inalienable right to exercise your "Right to Erasure" (commonly known as the Right to be Forgotten) by navigating to the Settings menu and activating the "Delete all my data" functionality. Initiating this highly destructive action triggers an immediate, automated, and irrevocable cryptographic erasure protocol across our entire infrastructure. Upon confirmation, all your historical check-ins, associated mathematical metrics, qualitative wellness assessments, unstructured notes, and all associated relational metadata are permanently and definitively expunged from our active production servers, cache layers, and operational databases. Concurrently, your local device will be securely unlinked from your profile, the local cryptographic encryption keys stored in the hardware secure element will be intentionally destroyed (rendering any residual local ciphertext permanently indecipherable), and your user account will be immediately deactivated and purged. This protocol is explicitly designed to be permanent, irreversible, and mathematically irrecoverable by any known computational means.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '5. Local Edge Caching, Server Data Lifecycle Management, and Retention Sweeps'),
              _sectionBody(context, ref,
                  'To ensure seamless, uninterrupted offline capability, continuous functionality, and resilience in austere or low-connectivity operational environments, a strictly limited, heavily encrypted subset of your most recent check-in history is temporarily cached locally on the edge device (your smartphone). The act of deactivating the device via the settings menu, or initiating a manual logout sequence, will instantly trigger a secure, multi-pass cryptographic wipe of this local cache, ensuring zero data residue. On the server side, your data is governed by a strict, automated, and legally mandated data lifecycle management policy. Server-side deletion mechanisms ensure that your records are not merely marked as deleted (soft-deleted) in the primary operational databases, but are also systematically, thoroughly, and verifiably eradicated across all distributed geographical backup nodes, failover clusters, and disaster recovery states in strict accordance with our rigorous, automated 7-day data retention sweep policy. Beyond this extremely narrow window required for disaster recovery, your data simply ceases to exist on our servers.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '6. Unambiguous Consent, Legal Basis for Processing, and Revocation Mechanisms'),
              _sectionBody(context, ref,
                  'By downloading, installing, authenticating via secure PIN or biometric challenge, and continuing to utilize the SainikSaathi application, you are actively providing your explicit, informed, unambiguous, and freely given consent to this comprehensive, detailed data processing model as outlined in this voluminous document. This consent forms the primary legal basis for our processing of your personal data under applicable global privacy regulations. You unconditionally reserve the right to completely withdraw and revoke this consent at any juncture, without penalty or prejudice, by utilizing the aforementioned "Delete all my data" functionality and subsequently uninstalling the application from your device. It is important to legally note that the revocation of your consent shall not affect the lawfulness, validity, or legality of any data processing activities based on your consent that occurred prior to its formal withdrawal, nor shall it affect any processing mandated by superseding statutory legal obligations.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '7. Comprehensive Incident Response, Breach Notification, and Mitigation Strategies'),
              _sectionBody(context, ref,
                  'In the highly unlikely, mathematically improbable event of a data breach, unauthorized access intrusion, or systemic compromise to our deeply secured infrastructure, SainikSaathi has established a pre-planned, rigorously tested, and rapid incident response protocol executed by a dedicated Computer Security Incident Response Team (CSIRT). Affected users will be notified directly, transparently, and without undue delay, and in all cases no later than the strict minimum timeframe mandated by the most stringent applicable privacy laws governing your jurisdiction (e.g., within 6 hours as per CERT-In guidelines). This official notification will transparently, honestly, and comprehensively detail the exact nature of the breach, the specific categories of data potentially compromised, the likely consequences of the breach, and the immediate, aggressive remedial actions and mitigation strategies being undertaken to secure our systems, neutralize the threat, and protect your identity.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '8. Continuous Compliance, External Independent Auditing, and Governance Oversight'),
              _sectionBody(context, ref,
                  'Our data handling practices, security architectures, and privacy policies are not static documents; they are living frameworks subject to continuous, rigorous, and adversarial auditing by independent, highly accredited, third-party cybersecurity firms, penetration testing syndicates, and privacy compliance assessors. These regular, unannounced audits ensure that our technical, physical, and organizational measures remain at the absolute cutting edge of data protection technology, cryptographic implementation, and in continuous, proactive alignment with the rapidly evolving landscape of global privacy legislation and defense cybersecurity mandates. By institutionalizing these external audits and committing to transparent remediation of any discovered vulnerabilities, we maintain an objective, verified, and continuously updated standard of security, privacy, and trust.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '9. Sub-Processor Agreements, Third-Party Infrastructure Providers, and Data Localization'),
              _sectionBody(context, ref,
                  'In the provisioning of this service, SainikSaathi may utilize highly vetted, enterprise-grade cloud infrastructure providers (Sub-processors) to host the encrypted ciphertext of our databases. Any such engagement is strictly governed by rigorous Data Processing Agreements (DPAs) that legally bind these Sub-processors to security and privacy standards identical to, or exceeding, our own. These Sub-processors are granted zero access to the cryptographic keys required to decrypt your data; they merely host the encrypted binary blobs. Furthermore, all primary data storage, processing, and backup facilities are strictly localized within sovereign national borders in compliance with national data localization mandates, ensuring that your sensitive information never crosses international jurisdictions where it may be subject to foreign surveillance or differing legal standards.'),
              const SizedBox(height: 16),
              _sectionTitle(context, ref,
                  '10. Automated Decision Making, Profiling, and Algorithmic Transparency'),
              _sectionBody(context, ref,
                  'SainikSaathi explicitly declares that no individual personnel decisions, disciplinary actions, or welfare interventions are made solely and exclusively through automated decision-making processes or algorithmic profiling. While sophisticated algorithms are utilized to aggregate your self-reported check-in data into higher-level trend indicators for unit commanders, any specific action taken based on this data involves meaningful, mandatory human review by qualified welfare officers. The algorithms employed are designed purely for the aggregation and visualization of wellness telemetry, and the logic involved is continuously audited to prevent the introduction of systemic bias, ensuring fair, equitable, and transparent handling of all personnel wellness data.'),
              const SizedBox(height: 32),
              Center(
                child: Text(tr('Confidential & Restricted', ref),
                    style: const TextStyle(
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

  Widget _sectionTitle(BuildContext context, WidgetRef ref, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(tr(title, ref),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: context.rrT2)),
    );
  }

  Widget _sectionBody(BuildContext context, WidgetRef ref, String body) {
    return Text(tr(body, ref),
        style: TextStyle(fontSize: 14, color: context.rrT4, height: 1.6));
  }
}
