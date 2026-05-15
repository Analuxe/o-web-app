import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/theme.dart';

/// Shows a stylized report dialog to report a user.
void showReportDialog(BuildContext context, {required String reportedUserId}) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(reportedUserId: reportedUserId),
  );
}

class ReportDialog extends StatefulWidget {
  final String reportedUserId;
  const ReportDialog({super.key, required this.reportedUserId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _issueType = 'Spam';
  final _narrativeController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _issueOptions = [
    'Spam',
    'Harassment',
    'Inappropriate Content',
    'Fake Profile',
    'Other'
  ];

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final supabase = Supabase.instance.client;
    final reporterId = supabase.auth.currentUser?.id;

    if (reporterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await supabase.from('reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': widget.reportedUserId,
        'issue_type': _issueType,
        'narrative': _narrativeController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you for keeping O safe.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('REPORT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: OTheme.deepCharcoal,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            // Subtle inner highlight/shadow simulation
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 0,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please help us understand what\'s happening.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'ISSUE TYPE',
              style: TextStyle(
                color: OTheme.neonPink,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _issueType,
                  dropdownColor: OTheme.deepCharcoal,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: OTheme.neonPink),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: _issueOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _issueType = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EXPLANATION',
              style: TextStyle(
                color: OTheme.neonPink,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _narrativeController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Briefly describe the issue...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: OTheme.neonPink, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: OTheme.neonPink, width: 2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: OTheme.neonPink,
                        ),
                      )
                    : const Text(
                        'SUBMIT REPORT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
