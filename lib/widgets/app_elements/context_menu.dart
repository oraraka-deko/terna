// define your context menu entries
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

final entries = <ContextMenuEntry>[
  const MenuHeader(text: "Context Menu"),
  MenuItem(
    label: const Text('Copy'),
    icon: const Icon(Icons.copy),
    onSelected: (value) {
      // implement copy
    },
  ),
  MenuItem(
    enabled: false, // disable this item
    label: const Text('Cut'),
    icon: const Icon(Icons.cut),
    onSelected: (value) {
      // implement cut
    },
  ),
  MenuItem(
    label: const Text('Paste'),
    icon: const Icon(Icons.paste),
    onSelected: (value) {
      // implement paste
    },
  ),
  const MenuDivider(),
  MenuItem.submenu(
    label: const Text('Edit'),
    icon: const Icon(Icons.edit),
    items: [
      MenuItem(
        label: const Text('Undo'),
        value: "Undo",
        icon: const Icon(Icons.undo),
        onSelected: (value) {
          // implement undo
        },
      ),
      MenuItem(
        label: const Text('Redo'),
        value: 'Redo',
        icon: const Icon(Icons.redo),
        onSelected: (value) {
          // implement redo
        },
      ),
    ],
  ),
];

// initialize a context menu
final menu = ContextMenu(
  entries: entries,
  position: const Offset(300, 300),
  padding: const EdgeInsets.all(8.0),
);
