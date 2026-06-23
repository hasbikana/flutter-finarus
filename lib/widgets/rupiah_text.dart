import 'package:flutter/material.dart';
import '../utils/format.dart';

class RupiahText extends StatelessWidget {
  final num amount;
  final TextStyle? style;

  const RupiahText({super.key, required this.amount, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(formatRupiah(amount), style: style);
  }
}
