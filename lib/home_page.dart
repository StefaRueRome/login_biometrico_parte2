import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_biometrico/login_page.dart';
import 'package:login_biometrico/storage_item.dart';

import 'package:shared_preferences/shared_preferences.dart';
class HomePage extends StatefulWidget{
  final bool boolFinal;
  final StorageItem? user;

  const HomePage({super.key, required this.boolFinal, required this.user});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(onPressed: () async {final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fingerprint_enabled', false);
      Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginPage(boolI: true, usuarioAuth: widget.user,)));;}, icon: Icon(Icons.logout_outlined))],
        automaticallyImplyLeading: false,
        title: Text('Home'),
      ),
      body: Center(
        child: Text(
          'Bienvenido ${widget.user?.key}',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
    );
  }
}