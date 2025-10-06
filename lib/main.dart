import 'package:flutter/material.dart';
import 'package:vendwise/screens/splash_screen.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Exploring Flutter UI Widgets",
      theme: ThemeData(
        fontFamily: 'Inter'
      ),
      home: Splashscreen(),
    ),
  );
}

