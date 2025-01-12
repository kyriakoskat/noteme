// notification_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match HomePage background
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(), // Use the same font
        ),
        backgroundColor: Color(0xFF65558F), // Match HomePage AppBar color
        elevation: 0, // Optional: Remove AppBar shadow for a cleaner look
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional: Add an icon above the message
              Icon(
                Icons.notifications_off,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 20),
              Text(
                "You don't have any notifications",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600], // Subtle grey color for the message
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
