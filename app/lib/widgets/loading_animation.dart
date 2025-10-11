import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 30,
            child: Icon(Icons.school, size: 30),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: const Duration(seconds: 1),
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
              )
              .then()
              .scale(
                duration: const Duration(seconds: 1),
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.titleMedium,
          ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
        ],
      ),
    );
  }
}