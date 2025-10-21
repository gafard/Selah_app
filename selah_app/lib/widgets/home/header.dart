import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.displayName, required this.subtitle, this.trailing});
  final String displayName;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shalom $displayName',
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: Colors.white70)),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
