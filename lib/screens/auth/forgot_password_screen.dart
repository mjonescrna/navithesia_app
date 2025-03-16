import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:navithesia_beta/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Use the auth provider to send the password reset email
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        if (success) {
          setState(() {
            _resetSent = true;
            _isLoading = false;
          });
        } else {
          // Get the specific error message from the auth provider
          setState(() {
            _errorMessage =
                authProvider.error ??
                'Failed to send reset email. Please try again.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _resetSent ? _buildSuccessMessage() : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 80, color: AppColors.primaryColor),
          const SizedBox(height: 24),

          Text(
            'Forgot Password',
            style: AppTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyText1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Add more detailed instructions in a card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'After you submit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Check your email inbox (and spam folder)'),
                  const Text('2. Click the reset link in the email'),
                  const Text(
                    '3. Create a new password (at least 6 characters)',
                  ),
                  const Text(
                    '4. Return to the app and log in with your new password',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error message (if any)
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorColor),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: AppColors.errorColor),
                textAlign: TextAlign.center,
              ),
            ),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Reset password button
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Reset Password'),
          ),
          const SizedBox(height: 24),

          // Back to login link
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 80, color: AppColors.successColor),
        const SizedBox(height: 24),

        Text(
          'Email Sent',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions to reset your password.',
          style: AppTextStyles.bodyText1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // More detailed instructions
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Check your email inbox (and spam folder)'),
                const Text('2. Click the reset link in the email'),
                const Text('3. Create a new password (at least 6 characters)'),
                const Text(
                  '4. Return to this app and sign in with your new password',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: After changing your password, you\'ll need to sign in again with the new password.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Back to login button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back to Login'),
        ),
        const SizedBox(height: 16),

        // Didn't receive email button
        TextButton(
          onPressed: () {
            setState(() {
              _resetSent = false;
            });
          },
          child: const Text('Didn\'t receive the email? Try again'),
        ),
      ],
    );
  }
}
