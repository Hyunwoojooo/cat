import 'package:flutter/material.dart';
import 'app_theme.dart';

class CommonWidgets {
  // 공통 라벨 위젯
  static Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor,
        ),
      ),
    );
  }

  // 공통 InfoBox 위젯
  static Widget buildInfoBox({
    required IconData icon,
    required String text,
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
    double? iconSize,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? AppTheme.textSecondaryColor,
            size: iconSize ?? 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: textColor ?? AppTheme.textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 공통 드롭다운 위젯
  static Widget buildDropdown({
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
    String? hintText,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: hintText != null ? Text(hintText) : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondaryColor,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColor,
            fontWeight: FontWeight.w400,
          ),
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // 공통 이미지 영역 위젯
  static Widget buildPhotoArea({
    String? imagePath,
    required VoidCallback onTap,
    String placeholderText = "이미지를 선택해주세요",
    double height = 220,
    double borderRadius = 14,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppTheme.surfaceColor,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.file(
                  imagePath as dynamic,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placeholderText,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // 공통 버튼 위젯
  static Widget buildButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : icon != null
                ? Icon(icon, size: 20)
                : const SizedBox.shrink(),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppTheme.primaryColor,
          side: BorderSide(color: textColor ?? AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
              ? Icon(icon, size: 20)
              : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
  }

  // 공통 카드 위젯
  static Widget buildCard({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
    List<BoxShadow>? shadow,
  }) {
    return Container(
      padding: padding ?? AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: shadow ?? AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  // 공통 구분선 위젯
  static Widget buildDivider({double height = 16}) {
    return SizedBox(height: height);
  }

  // 공통 로딩 인디케이터
  static Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
