// lib/widgets/custom_card.dart
import 'package:flutter/material.dart';
import 'package:rupix_admin_auth/utils/constants.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Decoration? decoration;
  const CustomCard({super.key, required this.child, this.decoration});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration ?? 
          BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
