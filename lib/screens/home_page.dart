import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'all_courses_page.dart';
import 'package:image_picker/image_picker.dart';



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = "User"; // Default username
  List<String> _folders = []; // Folders to display on the home page


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSubjects();
  }

  Future<void> _openCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image captured: ${pickedFile.path}")),
        );
        // Add further logic to save or process the captured image.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No image captured.")),
      );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to open camera: $e")),
    );
    }
  }


  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _username = data['username'] ?? "User";
            _folders = List<String>.from(data['folders'] ?? []);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch user data: $e")),
      );
    }
  }


  Future<void> _addFolders(List<String> newFolders) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    setState(() {
      _folders.addAll(newFolders.where((folder) => !_folders.contains(folder)));
    });

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await docRef.update({
      'folders': _folders,
    }); 
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save folders: $e")),
    );
  }
}




  Future<void> _fetchSubjects() async {
    try {
      final userId = "your-firebase-user-id"; // Replace with actual user ID.
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

      userDoc.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _folders = List<String>.from(snapshot.data()?['subjects'] ?? []);
          });
        }
      });
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }


  void _navigateToAllCoursesPage() async {
    final selectedSubjects = await Navigator.pushNamed(
      context,
      '/all-courses',
      arguments: _folders, // Pass the current folders list
    ) as List<String>?;

    if (selectedSubjects != null) {
      setState(() {
        _folders = selectedSubjects;
      });
      _saveSubjectsToFirestore(selectedSubjects);
    }
  }


  Future<void> _saveSubjectsToFirestore(List<String> subjects) async {
    try {
      final userId = "your-firebase-user-id"; // Replace with actual user ID.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'subjects': subjects,
      });
    } catch (e) {
      print("Error saving subjects: $e");
    }
  }

  Future<void> _logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await docRef.update({
          'folders': _folders,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save folders before logout: $e")),
        );
      }
    }

  await FirebaseAuth.instance.signOut();
  Navigator.pushReplacementNamed(context, '/login');
}

void _navigateToSubjectPage(String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectPage(subjectName: subject),
      ),
    );
  }

void _navigateToQrCode() {
    Navigator.pushNamed(context, '/qr-code');
  }


  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFECE6F0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : "U",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _username,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.camera, color: Colors.purple),
            title: Text(
              'Open Camera',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              _openCamera();
            },
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.purple,
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : "U",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.purple, size: 30),
                  onPressed: _logout,
                ),
              ],
            ),
            SizedBox(height: 30),
            // My Notes Title
            Text(
              "My Notes",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            Divider(color: Colors.purple, thickness: 1),
            SizedBox(height: 20),
            // Folder items
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folderName = _folders[index];
                  return GestureDetector(
                    onTap: () => _navigateToSubjectPage(folderName),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder, color: Colors.purple, size: 30),
                          SizedBox(width: 10),
                          Text(
                            folderName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToAllCoursesPage,
      backgroundColor: Colors.purple,
      child: Icon(Icons.add, color: Colors.white),
    ),
  );
}

}

class SubjectPage extends StatelessWidget {
  final String subjectName;

  const SubjectPage({Key? key, required this.subjectName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Text(
          "Welcome to $subjectName!",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

  