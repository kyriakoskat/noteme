import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationEnabled = true; // Initial state of the notification toggle

  // Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user
      Navigator.pushReplacementNamed(context, '/login'); // Navigate to the login screen
    } catch (e) {
      print("Error signing out: $e"); // Handle any errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the entire page
      body: Column(
        children: [
          // Purple header with "Settings" and back button
          Container(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Color(0xFF65558F), // Purple background
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Go back to the previous screen
                  },
                ),
                SizedBox(width: 10),
                Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Settings options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20), // Add padding for spacing
              children: [
                // Notification with toggle
                buildNotificationOption(),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.person,
                  title: "Account",
                  onTap: () {
                    Navigator.pushNamed(context, '/account'); // Navigate to Account page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.star,
                  title: "Rate App",
                  onTap: () {
                    Navigator.pushNamed(context, '/rate_app'); // Navigate to Rate App page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.share,
                  title: "Share App",
                  onTap: () {
                    Navigator.pushNamed(context, '/share_app'); // Navigate to Share App page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.lock,
                  title: "Privacy Policy",
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy_policy'); // Navigate to Privacy Policy page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.article,
                  title: "Terms and Conditions",
                  onTap: () {
                    Navigator.pushNamed(context, '/terms_conditions'); // Navigate to Terms page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.policy,
                  title: "Cookies Policy",
                  onTap: () {
                    Navigator.pushNamed(context, '/cookies_policy'); // Navigate to Cookies Policy page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.mail,
                  title: "Contact",
                  onTap: () {
                    Navigator.pushNamed(context, '/contact'); // Navigate to Contact page
                  },
                ),
                SizedBox(height: 20),
                buildSettingsOption(
                  context,
                  icon: Icons.feedback,
                  title: "Feedback",
                  onTap: () {
                    Navigator.pushNamed(context, '/feedback'); // Navigate to Feedback page
                  },
                ),
                SizedBox(height: 20),
                // Logout button with proper logout logic
                buildSettingsOption(
                  context,
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: _logout, // Call the logout function
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Notification toggle
  Widget buildNotificationOption() {
    return Container(
      color: Colors.white, // White background
      child: ListTile(
        leading: Icon(Icons.notifications, color: Colors.black),
        title: Text(
          "Notification",
          style: TextStyle(color: Colors.black),
        ),
        trailing: Switch(
          value: isNotificationEnabled,
          onChanged: (bool value) {
            setState(() {
              isNotificationEnabled = value; // Toggle the state
            });
          },
        ),
      ),
    );
  }

  // Widget for other settings options
  Widget buildSettingsOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      color: Colors.white, // White background
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
        onTap: onTap, // Navigate to the appropriate page
      ),
    );
  }
}

