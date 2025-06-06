import 'package:flutter/material.dart';

class TabGroup {
  final String id;
  String name;
  Color color;
  DateTime createdAt;
  
  TabGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TabGroup.fromJson(Map<String, dynamic> json) {
    return TabGroup(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static List<Color> get defaultColors => [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
}
