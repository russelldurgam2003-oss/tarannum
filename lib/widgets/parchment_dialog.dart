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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 20 : 40),
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 700, 
        constraints: BoxConstraints(maxHeight: isMobile ? 400 : 450),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/parchment_horizontal.png'), 
            fit: BoxFit.fill,
          ),
        ),
        // تقليل الحواف على الهاتف
        padding: EdgeInsets.only(
          left: isMobile ? 30 : 60, 
          right: isMobile ? 30 : 60, 
          top: isMobile ? 40 : 50, 
          bottom: isMobile ? 40 : 50
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A2C11),
              ),
            ),
            SizedBox(height: isMobile ? 10 : 15),
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
            if (actions != null) ...[
              SizedBox(height: isMobile ? 10 : 20),
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