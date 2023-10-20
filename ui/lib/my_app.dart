import 'package:flutter/material.dart';
import 'package:golem_ui/genes/gene_model.dart';
import 'package:golem_ui/screens/home_screen.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeneModel>(
          create: (BuildContext context) => GeneModel(),
        ),
      ],
      child: MaterialApp(
        title: 'GOLEM',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff488AB9),
          fontFamily: 'Barlow',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xffA0CB85)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
