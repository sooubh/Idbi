import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/providers/aws_providers.dart';

class GeminiKeyManagerSheet extends ConsumerStatefulWidget {
  const GeminiKeyManagerSheet({super.key});

  @override
  ConsumerState<GeminiKeyManagerSheet> createState() => _GeminiKeyManagerSheetState();
}

class _GeminiKeyManagerSheetState extends ConsumerState<GeminiKeyManagerSheet> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _testStatusMessage;
  Color? _testStatusColor;

  @override
  void initState() {
    super.initState();
    final hasKey = ref.read(hasGeminiKeyProvider);
    _isEditing = !hasKey;
    _keyController.text = AiRuntimeConfig.apiKey;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _isEditing ? _keyController.text.trim() : AiRuntimeConfig.apiKey;
    if (key.isEmpty) {
      setState(() {
        _testStatusMessage = "API Key cannot be empty";
        _testStatusColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testStatusMessage = "Testing connection...";
      _testStatusColor = Colors.blue;
      _errorMessage = null;
    });

    final keyService = ref.read(geminiKeyServiceProvider);
    final isValid = await keyService.testKey(key);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (isValid) {
        _testStatusMessage = "Connection Successful! Active and Ready.";
        _testStatusColor = Colors.green;
      } else {
        _testStatusMessage = "Invalid API Key. Connection failed.";
        _testStatusColor = Colors.red;
      }
    });
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = "Please enter an API key");
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _testStatusMessage = null;
    });

    final keyService = ref.read(geminiKeyServiceProvider);
    final isValid = await keyService.testKey(key);

    if (!mounted) return;

    if (isValid) {
      await keyService.saveKey(key);
      AiRuntimeConfig.userGeminiApiKey = key;
      ref.read(hasGeminiKeyProvider.notifier).setHasKey(true);

      setState(() {
        _isLoading = false;
        _isEditing = false;
        _testStatusMessage = "Key verified and saved successfully!";
        _testStatusColor = Colors.green;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Gemini API Key updated successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Invalid API Key. Verification failed.";
      });
    }
  }

  Future<void> _removeKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove API Key?"),
        content: const Text(
          "This will delete your Gemini API key from secure storage on this device and block all AI Wealth Advisor features.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final keyService = ref.read(geminiKeyServiceProvider);
    await keyService.removeKey();
    AiRuntimeConfig.userGeminiApiKey = null;
    ref.read(hasGeminiKeyProvider.notifier).setHasKey(false);

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text("Gemini API Key removed successfully."),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasKey = ref.watch(hasGeminiKeyProvider);
    final currentKey = AiRuntimeConfig.apiKey;
    
    final String obscuredKey;
    if (currentKey.isNotEmpty) {
      obscuredKey = currentKey.length > 10
          ? '${currentKey.substring(0, 6)}••••••••${currentKey.substring(currentKey.length - 4)}'
          : '••••••••';
    } else {
      obscuredKey = 'Not Configured';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Pull handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.vpn_key_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Gemini API Key Settings",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_isEditing) ...[
              // Preview State
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active API Key",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      obscuredKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_testStatusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testStatusColor?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _testStatusColor?.withValues(alpha: 0.3) ?? Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                        )
                      else
                        Icon(
                          _testStatusColor == Colors.green ? Icons.check_circle : Icons.error_outline,
                          color: _testStatusColor,
                          size: 18,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testStatusMessage!,
                          style: TextStyle(
                            color: _testStatusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text("Test Key"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => setState(() {
                        _isEditing = true;
                        _errorMessage = null;
                        _testStatusMessage = null;
                      }),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Update"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _removeKey,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  label: const Text("Remove Key", style: TextStyle(color: Colors.redAccent)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Edit/Setup State
              Text(
                "Enter your Gemini API key to enable AI advisor features like voice conversations and personalized recommendations.",
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _keyController,
                obscureText: _obscureText,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: "Gemini API Key",
                  hintText: "AIzaSy...",
                  errorText: _errorMessage,
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_testStatusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testStatusColor?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _testStatusColor?.withValues(alpha: 0.3) ?? Colors.transparent),
                  ),
                  child: Text(
                    _testStatusMessage!,
                    style: TextStyle(color: _testStatusColor, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasKey)
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() {
                        _isEditing = false;
                        _errorMessage = null;
                        _testStatusMessage = null;
                        _keyController.text = AiRuntimeConfig.apiKey;
                      }),
                      child: const Text("Cancel"),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveKey,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Verify & Save"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
