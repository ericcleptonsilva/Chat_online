import 'dart:io';

import 'package:chat_online/chat_messeger.dart';
import 'package:chat_online/tex_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User _currentUser;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future _getUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    try {
      final GoogleSignInAccount googleSignInAccount =
          await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final GoogleAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User user = userCredential.user;
      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMassage({String text, File imgFile}) async {
    final User user = await _getUser();
    if (user == null) {
      // ignore: deprecated_member_use
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Não foi possível fazer longin. Tente Novamente!"),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      'uid': user.uid,
      'senderName': user.displayName,
      'senderPhotoUrl': user.photoURL,
    };

    if (imgFile != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child("pasta")
          .child(DateTime.now().microsecondsSinceEpoch.toString())
          .putFile(imgFile);
      TaskSnapshot taskSnapshot = await task.whenComplete(() => task);
      String url = await taskSnapshot.ref.getDownloadURL();
      data["imgUrl"] = url;
    }

    if (text != null) data["text"] = text;
    FirebaseFirestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: Text(_currentUser != null
              ? "Usuári: ${_currentUser.displayName}"
              : "Chat App"),
          elevation: 0,
          actions: <Widget>[
            _currentUser != null ? IconButton(icon: Icon(Icons.exit_to_app), onPressed: (){
              FirebaseAuth.instance.signOut();
              googleSignIn.signOut();
              // ignore: deprecated_member_use
              _scaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text("Você saiu com sucesso!"),
                backgroundColor: Colors.green,
              ));
            }): Container()
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('messages').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> docs =
                        snapshot.data.docs.reversed.toList();

                    return ListView.builder(
                        itemCount: docs.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return ChatMessage(docs[index].data(), true);
                        });
                }
              },
            )),
            TextComposer(_sendMassage),
          ],
        ));
  }
}
