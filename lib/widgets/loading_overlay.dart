import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.getTextPrimary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Beautiful loading dialog for delete account etc
void showDeletingDialog(BuildContext context, {String? title, String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated delete icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) => Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever_rounded,
                        size: 40,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (title != null)
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.secondaryColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              if (message != null)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message, 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
