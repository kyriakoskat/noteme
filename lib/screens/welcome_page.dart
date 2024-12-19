import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/logo.png', height: 150), // Notebook Image
              SizedBox(height: 30),
              Text(
                "Explore our app",
                style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Now your notes are all in one place",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/login'); // Use named route
                },
                child: Text("Sign In",
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade200,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/create-account'); // Use named route
                },
                child: Text("Create account",
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
