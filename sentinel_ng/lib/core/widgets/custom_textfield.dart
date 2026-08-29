import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable text field with label, error state and validation support
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final String? hintText;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Phone number text field with country code
class PhoneNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const PhoneNumberField({super.key, this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Phone Number',
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.phone,
      hintText: '+234 800 000 0000',
      prefixIcon: const Icon(Icons.phone),
    );
  }
}

/// Search text field with icon
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onClear;

  const SearchTextField({super.key, this.controller, this.hintText = 'Search...', this.onClear});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: '',
      controller: controller,
      hintText: hintText,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: onClear != null
          ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
          : null,
    );
  }
}
