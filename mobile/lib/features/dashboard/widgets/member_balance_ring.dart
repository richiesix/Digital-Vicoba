import 'package:flutter/material.dart';

class MemberBalanceRing extends StatelessWidget {
  const MemberBalanceRing({
    super.key,
    required this.savingsLabel,
    required this.savingsValue,
    required this.loanLabel,
    required this.loanValue,
    required this.savingsAmount,
    required this.loanAmount,
  });

  final String savingsLabel;
  final String savingsValue;
  final String loanLabel;
  final String loanValue;
  final double savingsAmount;
  final double loanAmount;

  @override
  Widget build(BuildContext context) {
    final total = savingsAmount + loanAmount;
    final savingsRatio = total > 0 ? savingsAmount / total : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: savingsRatio,
                      strokeWidth: 12,
                      backgroundColor: Colors.red.shade100,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings, color: Color(0xFF2E7D32), size: 28),
                      Text(
                        '${(savingsRatio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(const Color(0xFF2E7D32), savingsLabel, savingsValue),
                  const SizedBox(height: 12),
                  _legendRow(Colors.red.shade700, loanLabel, loanValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
