import 'package:flutter/material.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/my_app.dart';
import 'package:geneweb/screens/lock_screen.dart';
import 'package:geneweb/widgets/home.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final adminUrl = '${const String.fromEnvironment('GOLEM_API_URL')}/admin';

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final username = context.select<GeneModel, String?>((model) => model.user?.username);
    final deploymentFlavor = context.select<GeneModel, DeploymentFlavor?>((model) => model.deploymentFlavor);
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
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
            Expanded(
              child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text(username ?? '',
                            style:
                                const TextStyle(fontStyle: FontStyle.italic)),
                      ),
                      if (GeneModel.of(context).isAdmin)
                        IconButton(
                            icon: const Icon(Icons.admin_panel_settings, size: 30),
                            onPressed: () async {
                              await launchUrl(
                                Uri.parse(adminUrl),
                                webOnlyWindowName: '_blank'
                                );
                            }),
                      if (GeneModel.of(context).isSignedIn)
                        IconButton(
                            icon: const Icon(Icons.logout, size: 30),
                            onPressed: () async {
                              final logoutResponse =
                                  await ApiService.instance.post("/auth/logout");
                              if (context.mounted && logoutResponse.success) {
                                GeneModel.of(context).user = null;
                              }
                            })
                      else
                        IconButton(
                            icon: const Icon(Icons.login, size: 30),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LockScreen()));
                            }),
                    ],
                  )),
            )
          ],
        ),
        backgroundColor: public ? null : const Color(0xffEC6138),
        actions: deploymentFlavor != null
            ? null
            : <Widget>[
                IconButton(
                  icon: public ? const Icon(Icons.lock_open) : const Icon(Icons.lock),
                  onPressed: () => GeneModel.of(context).setPublicSite(!public),
                ),
              ],
      ),
      body: const Home(),
    );
  }
}
