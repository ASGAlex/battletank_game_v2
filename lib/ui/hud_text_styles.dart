import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

final hudTextPaintNormal = TextPaint(
    style: TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
  backgroundColor: Colors.white.withOpacity(0.5),
));

final hudTextPaintGood = TextPaint(
    style: const TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.green,
  backgroundColor: Colors.black12,
));

final hudTextPaintDanger = TextPaint(
    style: const TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.red,
  backgroundColor: Colors.black12,
));
