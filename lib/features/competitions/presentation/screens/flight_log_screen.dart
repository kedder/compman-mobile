import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../domain/entities/flight_log_file.dart';
import '../providers/competitions_providers.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Screen listing today's `.igc` flight log files for a competition, letting
/// the pilot pick which ones to send and to which email address.
///
/// Reachable at `/competitions/:id/flight-logs`.
class FlightLogScreen extends ConsumerStatefulWidget {
  /// Creates the [FlightLogScreen].
  const FlightLogScreen({super.key, required this.competitionId});

  /// The SoaringSpot slug / SoarScore competition ID.
  final String competitionId;

  @override
  ConsumerState<FlightLogScreen> createState() => _FlightLogScreenState();
}

class _FlightLogScreenState extends ConsumerState<FlightLogScreen> {
  final _emailController = TextEditingController();

  Set<String> _selectedFilenames = {};
  bool _selectionInitialized = false;
  bool _emailInitialized = false;
  bool _sending = false;
  String? _sendError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  Future<void> _send(List<FlightLogFile> files) async {
    final selected = files
        .where((f) => _selectedFilenames.contains(f.filename))
        .toList();
    final recipient = _emailController.text.trim();

    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final result = await ref.read(sendFlightLogsProvider)(
        competitionId: widget.competitionId,
        files: selected,
        recipient: recipient,
      );
      if (!mounted) return;
      result.fold(
        (failure) => setState(() => _sendError = failureMessage(failure)),
        (_) {
          ref.invalidate(bookmarkedCompetitionsProvider);
          ref.invalidate(competitionDetailProvider(widget.competitionId));
        },
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'NO_MAIL_APP') {
        setState(
          () => _sendError = 'No email app available to send flight logs.',
        );
      } else {
        setState(() => _sendError = e.message ?? 'Send failed');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitionAsync = ref.watch(
      competitionDetailProvider(widget.competitionId),
    );
    competitionAsync.whenData((competition) {
      if (!_emailInitialized && competition != null) {
        _emailController.text = competition.scoringEmail ?? '';
        _emailInitialized = true;
      }
    });

    final logsAsync = ref.watch(todaysFlightLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Logs')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorRetry(
            message: failureMessage(err),
            onRetry: () => ref.invalidate(todaysFlightLogsProvider),
          ),
        ),
        data: (files) {
          if (files.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No flight logs found for today.'),
              ),
            );
          }

          if (!_selectionInitialized) {
            _selectedFilenames = files.map((f) => f.filename).toSet();
            _selectionInitialized = true;
          }

          final emailValid = _isValidEmail(_emailController.text);
          final canSend =
              _selectedFilenames.isNotEmpty && emailValid && !_sending;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      for (final file in files)
                        _FlightLogCheckboxRow(
                          filename: file.filename,
                          checked: _selectedFilenames.contains(file.filename),
                          onChanged: (checked) => setState(() {
                            _sendError = null;
                            if (checked) {
                              _selectedFilenames.add(file.filename);
                            } else {
                              _selectedFilenames.remove(file.filename);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => _isValidEmail(value ?? '')
                            ? null
                            : 'Enter a valid email address',
                        onChanged: (_) => setState(() => _sendError = null),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canSend ? () => _send(files) : null,
                          style: AppButtonStyles.primary(context),
                          child: const Text('Send'),
                        ),
                      ),
                      if (_sendError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _sendError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A single file row: a checkbox flush with the screen's left padding (to
/// line up with the recipient email field and Send button below) followed
/// by the raw filename.
class _FlightLogCheckboxRow extends StatelessWidget {
  const _FlightLogCheckboxRow({
    required this.filename,
    required this.checked,
    required this.onChanged,
  });

  final String filename;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(filename)),
          ],
        ),
      ),
    );
  }
}
