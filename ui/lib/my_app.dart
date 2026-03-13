import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/models/user.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/home_screen.dart';
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
        home: Builder(builder: (context) {
          ApiService.instance.get("/auth/me").then((response) {
            if (context.mounted && response.success) {
              final user = User.fromJson(response.data as Map<String, dynamic>);
              GeneModel.of(context).user = user;
            }
          });

          return const HomeScreen();
        }),
      ),
    );
  }
}
