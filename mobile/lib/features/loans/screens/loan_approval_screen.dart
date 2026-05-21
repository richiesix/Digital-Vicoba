import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LoanApprovalScreen extends StatelessWidget {
  const LoanApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idhinisha Mikopo')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mwanachama ${i + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('TZS ${(i + 1) * 100000}', style: const TextStyle(color: AppColors.pending, fontSize: 20)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Kataa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Idhinisha'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
