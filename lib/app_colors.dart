import 'package:flutter/material.dart';

class AppColors {
  // This class is not meant to be instantiated.
  AppColors._(); 

  // --- PRIMARY PALETTE ---
  /// Vibrant Blue (Primary/Accent): #4C5DF4
  static const Color primary = Color.fromARGB(255, 158, 164, 207);
  
  /// Pure White (Content Background): #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  /// Dark Gray (Primary Text): #1D1D1F
  static const Color primaryText = Color(0xFF1D1D1F);

  /// Medium Gray (Secondary Text): #8E8E93
  static const Color secondaryText = Color.fromARGB(255, 62, 62, 70);

  // --- SECONDARY & ACCENT PALETTE ---
  /// Light Lavender Gray (Overall Background): #EAEFFB
  static const Color background = Color(0xFFEAEFFB);

  /// Light Gray (Placeholders & Borders): #C7C7CD
  static const Color placeholder = Color(0xFFC7C7CD);
  
  /// Accent Green (Progress Indicator): #4AD0A0
  static const Color progress = Color(0xFF4AD0A0);

  /// Notification Red: #FF3B30
  static const Color notification = Color(0xFFFF3B30);

  /// Primary Button (Light Mode): #805CF5
  static const Color primaryButton = Color(0xFF805CF5);

  /// Background (Dark Mode): #1E1E2A
  static const Color darkBackground = Color(0xFF1E1E2A);
} 