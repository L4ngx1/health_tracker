import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/localization/app_strings.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillEmail});

  final String? prefillEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = const AuthController();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _isLoading = v);
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_controller.isValidEmail(email)) {
      _setError(AppStrings.validEmailRequired(context));
      return;
    }

    _setError(null);
    _setLoading(true);
    final error = await _controller.forgotPassword(email);
    if (!mounted) return;
    _setLoading(false);

    if (error != null) {
      _setError(error);
      return;
    }

    _setError(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.resetLinkSent(context)),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AuthLayout(
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centered brand and section header (back button is provided by AuthLayout)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandIconOnly(),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.appTitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.forgotPasswordTitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 360,
                        child: Text(
                          AppStrings.forgotPasswordSubtitle(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      border: Border.all(color: colorScheme.error),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                InputLabel(AppStrings.emailLabel(context)),
                const SizedBox(height: 8),
                RoundedInput(
                  controller: _emailController,
                  hint: AppStrings.emailHintGeneral(context),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: AppStrings.send(context),
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(AppStrings.cancel(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
