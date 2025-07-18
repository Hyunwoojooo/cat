import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final dynamic inputFormatters;
  final double? width;
  final TextInputType? keyboardType;
  final Color? borderColor;
  final int? maxLines;
  final double? height;
  final Widget? suffixIcon;
  final String? initialValue;
  final Color? fillColor;
  final int? maxLength;
  final double? contentPaddingTop;
  final double? hintFontSize;
  final double? fontSize;

  const CustomTextFormField({
    this.initialValue,
    this.controller,
    this.onChanged,
    this.hintText,
    this.keyboardType,
    this.autoFocus = false,
    this.obscureText = false,
    this.errorText,
    this.inputFormatters,
    this.suffixIcon,
    this.width,
    this.borderColor,
    this.maxLines,
    this.height,
    this.fillColor,
    this.maxLength,
    this.contentPaddingTop,
    this.hintFontSize,
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    InputBorder baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)), // 이 부분을 추가
      borderSide: BorderSide(color: B_5),
    );
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(
        fontSize: fontSize ?? 16,
        fontWeight: FontWeight.w500,
        color: B_1,
        decorationThickness: 0,
      ),
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: keyboardType ?? TextInputType.text,
      // scrollPadding: EdgeInsets.zero,
      controller: controller,
      cursorColor: B_4,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      autofocus: autoFocus,
      onChanged: onChanged,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(
          left: 20,
          top: contentPaddingTop ?? 14,
          right: 10,
          bottom: 20,
        ),
        hintText: hintText,
        errorText: errorText,
        hintStyle: TextStyle(
          color: B_3,
          fontSize: hintFontSize ?? 16,
          fontWeight: FontWeight.w500,
        ),
        counterStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: B_4,
        ),
        counterText: '',
        suffixIcon: suffixIcon,
        fillColor: fillColor ?? B_5,
        filled: true,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder,
      ),
    );
  }
}

// Clear
