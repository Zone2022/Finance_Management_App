import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int codePoint;
  final Color color;

  // Use constant icons so release builds can tree-shake the Material font.
  IconData get icon =>
      const {
        '餐饮': Icons.restaurant,
        '交通': Icons.directions_car,
        '购物': Icons.shopping_bag,
        '居住': Icons.home,
        '娱乐': Icons.sports_esports,
        '医疗': Icons.local_hospital,
        '教育': Icons.school,
        '通讯': Icons.phone_android,
      }[name] ??
      Icons.more_horiz;

  const Category({
    this.id,
    required this.name,
    required this.codePoint,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': codePoint.toString(),
      'color_value': color.toARGB32(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      codePoint:
          int.tryParse(map['icon'] as String) ?? Icons.help_outline.codePoint,
      color: Color(map['color_value'] as int),
    );
  }

  static const List<Category> defaults = [
    Category(
      name: '餐饮',
      codePoint: 0xe532,
      color: Color(0xFFE24B4A),
    ), // restaurant
    Category(
      name: '交通',
      codePoint: 0xe531,
      color: Color(0xFF378ADD),
    ), // directions_car
    Category(
      name: '购物',
      codePoint: 0xe547,
      color: Color(0xFFEF9F27),
    ), // shopping_bag
    Category(name: '居住', codePoint: 0xe88a, color: Color(0xFF1D9E75)), // home
    Category(
      name: '娱乐',
      codePoint: 0xea43,
      color: Color(0xFF7F77DD),
    ), // sports_esports
    Category(
      name: '医疗',
      codePoint: 0xe547,
      color: Color(0xFFD4537E),
    ), // local_hospital
    Category(name: '教育', codePoint: 0xe80c, color: Color(0xFF639922)), // school
    Category(
      name: '通讯',
      codePoint: 0xe325,
      color: Color(0xFF534AB7),
    ), // phone_android
    Category(
      name: '其他',
      codePoint: 0xe5d3,
      color: Color(0xFF888780),
    ), // more_horiz
  ];
}
