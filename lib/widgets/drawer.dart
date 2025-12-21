import 'package:chatapp_light/services/auth_service.dart';
import 'package:chatapp_light/views/login_page.dart';
import 'package:chatapp_light/views/settings_page.dart';
import 'package:flutter/material.dart';


class MyDrawer extends StatelessWidget{
  const MyDrawer({super.key});



  @override
  Widget build(BuildContext context){
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
            child: Center(
              child: Icon(
                Icons.message,
                color: Theme.of(context).colorScheme.primary,
                size:40,
              )
            )
          ),
          Padding(
            padding: EdgeInsets.only(left: 25),
            child: ListTile(
              title: Text('Home'),
              leading: Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
              },
            )
          ),
          Padding(
            padding: EdgeInsets.only(left: 25),
            child: ListTile(
              title: Text('Settings'),
              leading: Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(),
                ),
                );

              },
            )
          )
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 25),
            child: ListTile(
              title: Text('Log out'),
              leading: Icon(Icons.logout),
              onTap: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Voulez-vous vraiment vous déconnecter ?',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Déconnexion'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final _auth = AuthService();
                  await _auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            )
          )
        ],),
    ); 

  } 

}