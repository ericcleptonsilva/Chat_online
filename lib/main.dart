import 'package:chat_online/chat_screen.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';

Future<void> main()  async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.orange,
        iconTheme: IconThemeData(
          color: Colors.orange
        )
      ),
      home: ChatScreen(),
    );
  }
}
