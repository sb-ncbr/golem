import 'package:flutter/material.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:golem_ui/widgets/home.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        title: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 24.0,
                      children: [
                        Image.asset('assets/logo-golem.png', height: 36),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Gene regulatory elements', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.center,
                    child: Text(name ?? '', style: const TextStyle(fontStyle: FontStyle.italic)))),
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
      body: const Home(),
    );
  }
}
