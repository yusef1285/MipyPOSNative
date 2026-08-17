// lib/widgets/cash_count_widget.dart
import 'package:flutter/material.dart';

typedef CashCountChanged = void Function(double total, Map<String,int> breakdown);

class CashCountWidget extends StatefulWidget {
  final CashCountChanged? onChanged;

  const CashCountWidget({super.key, this.onChanged});

  @override
  State<CashCountWidget> createState() => _CashCountWidgetState();
}

class _CashCountWidgetState extends State<CashCountWidget> {
  final List<String> _denominations = [
    '1','3','5','10','20','50','100','200','500','1000','2000','5000'
  ];

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {for (var d in _denominations) d: TextEditingController()};
  }

  void _notify() {
    double total = 0.0;
    final breakdown = <String,int>{};

    for (var d in _denominations) {
      final qty = int.tryParse(_controllers[d]!.text) ?? 0;
      breakdown[d] = qty;
      total += (double.tryParse(d) ?? 0.0) * qty;
    }

    widget.onChanged?.call(total, breakdown);
  }

  @override
  void dispose() {
    for (var c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _denominations.map((den) {
            return SizedBox(
              width: 110,
              child: TextField(
                controller: _controllers[den],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '\$$den'),
                onChanged: (_) => _notify(),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _notify,
          child: const Text('Calcular total'),
        ),
      ],
    );
  }
}
