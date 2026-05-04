// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_model.dart';
import 'package:animate_do/animate_do.dart';

class DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDebt = debt.type == DebtType.debt;
    final isPaid = debt.status == DebtStatus.paid;
    final color = isDebt ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebt
                      ? Icons.call_made_rounded
                      : Icons.call_received_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      debt.note.isNotEmpty
                          ? debt.note
                          : (isDebt ? 'Bạn nợ' : 'Người nợ bạn'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    if (debt.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hạn: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebt ? "-" : "+"}${NumberFormat('#,###').format(debt.amount)} ₫',
                    style: TextStyle(
                      color: isPaid ? Colors.white.withOpacity(0.3) : color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onToggleStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.grey.withOpacity(0.2)
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPaid
                              ? Colors.grey.withOpacity(0.3)
                              : color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isPaid ? 'ĐÃ TRẢ' : 'CHƯA TRẢ',
                        style: TextStyle(
                          color: isPaid ? Colors.grey : color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
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
