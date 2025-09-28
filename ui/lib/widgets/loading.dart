import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

/// Widget that shows the global loading state
class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    final loadingState =
        context.select<GeneModel, LoadingState>((model) => model.loading);

    if (!loadingState.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loadingState.message ?? 'Loading ...',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: loadingState.progress),
        ],
      ),
    );
  }
}
