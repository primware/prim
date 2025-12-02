import 'package:flutter/material.dart';
import '../API/token.api.dart';

class CustomFooter extends StatefulWidget {
  const CustomFooter({
    super.key,
  });

  @override
  State<CustomFooter> createState() => _CustomFooterState();
}

class _CustomFooterState extends State<CustomFooter> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'www.primware.net  •  v${AppInfo.appVersion}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
