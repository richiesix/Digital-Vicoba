import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MemberBalanceRing extends StatelessWidget {
  const MemberBalanceRing({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.savingsLabel,
    required this.savingsValue,
    required this.loanLabel,
    required this.loanValue,
    required this.savingsAmount,
    required this.loanAmount,
  });

  final String title;
  final IconData titleIcon;
  final String savingsLabel;
  final String savingsValue;
  final String loanLabel;
  final String loanValue;
  final double savingsAmount;
  final double loanAmount;

  static const _savingsColor = AppColors.savings;
  static const _loanColor = AppColors.overdue;
  static const double _ringSize = 72;
  static const double _ringStroke = 7;

  @override
  Widget build(BuildContext context) {
    final total = savingsAmount + loanAmount;
    final savingsRatio = total > 0 ? savingsAmount / total : 1.0;
    final percentLabel = '${(savingsRatio * 100).toStringAsFixed(0)}%';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(titleIcon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SavingsRing(
                    savingsRatio: savingsRatio,
                    percentLabel: percentLabel,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BalanceStat(
                              color: _savingsColor,
                              label: savingsLabel,
                              value: savingsValue,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                            indent: 4,
                            endIndent: 4,
                          ),
                          Expanded(
                            child: _BalanceStat(
                              color: _loanColor,
                              label: loanLabel,
                              value: loanValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsRing extends StatelessWidget {
  const _SavingsRing({
    required this.savingsRatio,
    required this.percentLabel,
  });

  final double savingsRatio;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MemberBalanceRing._ringSize,
      height: MemberBalanceRing._ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: MemberBalanceRing._ringSize,
            height: MemberBalanceRing._ringSize,
            child: CircularProgressIndicator(
              value: savingsRatio,
              strokeWidth: MemberBalanceRing._ringStroke,
              backgroundColor: MemberBalanceRing._loanColor.withValues(alpha: 0.12),
              color: MemberBalanceRing._savingsColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.savings_outlined,
                color: MemberBalanceRing._savingsColor,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                percentLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.1,
                  color: MemberBalanceRing._savingsColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 15,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
