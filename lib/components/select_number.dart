import 'package:flutter/material.dart';

import 'colors.dart';

class ChoiceMemberCount extends StatefulWidget {
  final Function(String) onMemberCountSelected;
  final String? initialValue;

  const ChoiceMemberCount({
    super.key,
    required this.onMemberCountSelected,
    this.initialValue,
  });

  @override
  State<ChoiceMemberCount> createState() => _ChoiceMemberCountState();
}

class _ChoiceMemberCountState extends State<ChoiceMemberCount> {
  String? selectedCount;

  @override
  void initState() {
    super.initState();
    selectedCount = widget.initialValue;
  }

  void _handleSelection(String value) {
    setState(() {
      selectedCount = value;
    });
    widget.onMemberCountSelected(value); // 부모 위젯에 선택된 값 전달
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: B_5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          showModalBottomSheet(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            backgroundColor: WHITE,
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 370,
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    SizedBox(
                      width: 70,
                      height: 160,
                      child: Start01(
                        onNumberSelected: (value) {
                          _handleSelection(value);
                        },
                        maxNumbs: 13,
                      ),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: P_1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0.0,
                          ),
                          onPressed: () {
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          child: SizedBox(
                            width: 318,
                            height: 56,
                            child: Center(
                              child: Text(
                                '확인',
                                style: TextStyle(
                                  color: WHITE,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          alignment: Alignment.centerLeft,
          child: Text(
            selectedCount ?? '인원 수를 선택해 주세요.',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: selectedCount == null ? B_3 : B_1,
            ),
          ),
        ),
      ),
    );
  }
}

class Start01 extends StatefulWidget {
  final Function(String) onNumberSelected;
  final int maxNumbs;
  final List<String>? customLabels;

  const Start01({
    super.key,
    required this.onNumberSelected,
    required this.maxNumbs,
    this.customLabels,
  });

  @override
  State<Start01> createState() => _Start01State();
}

class _Start01State extends State<Start01> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController();
  }

  void _onNumberTap(String number) {
    widget.onNumberSelected(number);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
        color: WHITE,
      ),
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 70,
        perspective: 0.005,
        diameterRatio: 1000,
        squeeze: 1,
        overAndUnderCenterOpacity: 0.3,
        useMagnifier: true,
        magnification: 1.3,
        onSelectedItemChanged: (value) {
          String selectedValue;
          if (widget.customLabels != null) {
            selectedValue = widget.customLabels![value];
          } else {
            selectedValue = (value + 1).toString().padLeft(2, '0');
          }
          _onNumberTap(selectedValue);
          print(selectedValue);
        },
        physics: const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildListDelegate(
          children: List<Widget>.generate(widget.maxNumbs, (index) {
            if (widget.customLabels != null) {
              return Center(
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: B_1,
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: B_1,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
