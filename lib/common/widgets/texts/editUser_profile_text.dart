import 'package:flutter/material.dart';

class UUserDetails extends StatelessWidget {
  const UUserDetails({
    super.key, required this.title, required this.subtitle, required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall!.apply(color: Colors.grey), overflow: TextOverflow.ellipsis,)),
        Expanded(child: Text(subtitle, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis,)),
        Icon(icon, size: 18,)
      ],
    );
  }
}