import 'package:flame/components.dart';
import 'package:flutter/material.dart';

@immutable
class ScenarioEvent<T> {
  const ScenarioEvent({
    required this.emitter,
    required this.name,
    this.data,
  });

  final Component emitter;
  final String name;
  final T? data;
}
