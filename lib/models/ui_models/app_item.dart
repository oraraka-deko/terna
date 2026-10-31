import 'package:flutter/material.dart';

class AppItem {
  final String name;

  final Widget iconWidget;

  final bool hasDot;
  final Widget? screen;
  final Future<void> Function()? screenaction;
  const AppItem({
    required this.name,

    required this.iconWidget,

    this.hasDot = false,
    this.screen,
    this.screenaction,
  });
}
