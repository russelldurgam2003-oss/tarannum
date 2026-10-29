import 'package:flutter/material.dart';

class ParchmentDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const ParchmentDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 700, // حجم مناسب للصورة الأفقية
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/parchment_horizontal.png'),
            fit: BoxFit.fill,
          ),
        ),
        // ضبط الحواف لتناسب الفراغ الداخلي في المخطوطة الأفقية
        padding: const EdgeInsets.only(left: 60, right: 60, top: 50, bottom: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C11),
              ),
            ),
            const SizedBox(height: 15),
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
            if (actions != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}