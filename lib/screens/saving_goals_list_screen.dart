import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saving_goal_provider.dart';
import '../widgets/saving_goal_card.dart';
import 'add_saving_goal_screen.dart';

class SavingGoalsListScreen extends StatelessWidget {
  const SavingGoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mục tiêu tiết kiệm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<SavingGoalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có mục tiêu nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAdd(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo mục tiêu đầu tiên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF05D15),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.goals.length,
            itemBuilder: (context, index) {
              final goal = provider.goals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Hero(
                  tag: 'goal_${goal.id}',
                  child: SavingGoalCard(
                    goal: goal,
                    onTap: () => _navigateToAdd(context, goal: goal),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: const Color(0xFFF05D15),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAdd(BuildContext context, {dynamic goal}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSavingGoalScreen(initialGoal: goal),
      ),
    );
  }
}
