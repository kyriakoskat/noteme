import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'add_friend_page.dart';
import 'subject_notebooks_page.dart';
import 'friends_page.dart'; 



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = "User"; // Default username
  List<String> _subjects = []; // Subjects the user has selected
  double _rating = 0.0;
  String _barcodeData = ""; // User's barcode data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Fetch user data
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _username = userData?['username'] ?? "User";
          _subjects = List<String>.from(userData?['subjects'] ?? []);
          _rating = (userDoc.data()?['rating'] ?? 0.0).toDouble(); // Fetch rating
          _barcodeData = userData?['barcode'] ?? ""; // Safely fetch barcode data
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddFriendPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddFriendPage()),
    );
  }



  void _showBarcodeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        "Your Barcode",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF65558F)),
      ),
      content: Container(
        width: 200, // Ensure width
        height: 200, // Ensure height
        alignment: Alignment.center,
        child: _barcodeData.isNotEmpty
            ? QrImageView(
                data: _barcodeData,
                version: QrVersions.auto,
                size: 200.0, // Explicit size for the QR code
              )
            : Text("No barcode available", style: TextStyle(color: Colors.grey)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close", style: TextStyle(color: Color(0xFF65558F))),
        ),
      ],
    ),
  );
}


  Future<void> _saveSelectedSubjects(List<String> selectedSubjects) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Save the selected subjects to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'subjects': selectedSubjects});

      setState(() {
        _subjects = selectedSubjects;
      });
    } catch (e) {
      print("Error saving subjects: $e");
    }
  }





  void _navigateToAllCoursesPage() async {
    // Pass the current subjects to the All Courses page
    final selectedSubjects = await Navigator.pushNamed(
      context,
      '/all-courses',
      arguments: _subjects,
    ) as List<String>?;

    if (selectedSubjects != null) {
      // Save the selected subjects to Firestore
      _saveSelectedSubjects(selectedSubjects);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }


  Widget buildStarRating(double rating) {
    int fullStars = rating.floor(); // Number of full stars
    bool hasHalfStar = (rating - fullStars) > 0; // Check if there's a half star
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0); // Remaining empty stars

    return Row(
      children: [
        // Full stars
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.amber, size: 20),
        // Half star
        if (hasHalfStar) Icon(Icons.star_half, color: Colors.amber, size: 20),
        // Empty stars
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }


Future<void> calculateAndUpdateUserRating(String userId) async {
  try {
    // Reference to the notebooks collection
    final notebooksRef = FirebaseFirestore.instance.collection('notebooks');

    // Query all public notebooks created by the user
    final querySnapshot = await notebooksRef
        .where('created_by', isEqualTo: userId)
        .where('visibility', isEqualTo: 'public')
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("No public notebooks found for user: $userId");
      // If no public notebooks, set the rating to 0.0
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'rating': 0.0});
      return;
    }

    // Calculate the average rating of the user's public notebooks
    double totalRating = 0.0;
    int count = 0;

    for (var doc in querySnapshot.docs) {
      final notebookData = doc.data();
      if (notebookData.containsKey('rating')) {
        totalRating += notebookData['rating'] as double;
        count++;
      }
    }

    // If there are rated notebooks, calculate the average
    final averageRating = count > 0 ? (totalRating / count) : 0.0;

    // Update the user's rating in the users collection
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'rating': averageRating});

    print("User rating updated to $averageRating for user: $userId");
  } catch (e) {
    print("Error calculating and updating user rating: $e");
  }
}

  Future<void> updateNotebookRating(String notebookId, String raterId, int newRating) async {
  try {
    final notebookRef = FirebaseFirestore.instance.collection('notebooks').doc(notebookId);

    // Fetch the notebook
    final notebookSnapshot = await notebookRef.get();
    if (!notebookSnapshot.exists) {
      print("Notebook not found: $notebookId");
      return;
    }

    final notebookData = notebookSnapshot.data();
    if (notebookData == null) return;

    // Update the `rated_by` map
    Map<String, dynamic> ratedBy = Map<String, dynamic>.from(notebookData['rated_by'] ?? {});
    ratedBy[raterId] = newRating;

    // Recalculate the notebook's average rating
    double totalRating = ratedBy.values.fold(0.0, (sum, value) => sum + (value as int));
    double averageRating = totalRating / ratedBy.length;

    // Update the notebook's `rating` and `rated_by`
    await notebookRef.update({
      'rated_by': ratedBy,
      'rating': averageRating,
    });

    print("Notebook rating updated to $averageRating");

    // Update the creator's overall rating
    final createdBy = notebookData['created_by'] as String?;
    if (createdBy != null) {
      await calculateAndUpdateUserRating(createdBy);
    }
  } catch (e) {
    print("Error updating notebook rating: $e");
  }
}




  void _navigateToSubjectPage(String subject) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubjectNotebooksPage(subjectName: subject),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
    drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      // Drawer Header
      DrawerHeader(
        decoration: BoxDecoration(
          color: Color(0xFF65558F),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // 5-star rating
            buildStarRating(_rating),
          ],
        ),
      ),
      // Add Friend Option
      ListTile(
        leading: Icon(Icons.person_add, color: Color(0xFF65558F)),
        title: Text("Add Friend"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFriendPage()),
          );
        },
      ),
      // Friends Page Option
      ListTile(
        leading: Icon(Icons.people, color: Color(0xFF65558F)),
        title: Text("Friends"),
        onTap: () {
          Navigator.pushNamed(context, '/friends');
        },
      ),
    ],
  ),
),

    appBar: AppBar(
      title: Text("Home"),
      backgroundColor: Color(0xFF65558F),
    ),
      
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showBarcodeDialog(context), // Show barcode dialog on tap
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Color(0xFF65558F),
                            child: Text(
                              _username.isNotEmpty
                                  ? _username[0].toUpperCase()
                                  : "U",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
                            SizedBox(height: 5),
                            // 5-star rating
                            buildStarRating(_rating),
                          ],
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.logout,
                              color: Color(0xFF65558F), size: 30),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),

                    // My Notes Title
                    Text(
                      "My Subjects",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF65558F),
                      ),
                    ),
                    Divider(color: Color(0xFF65558F), thickness: 1),
                    SizedBox(height: 20),

                    // Subject items
                    Expanded(
                      child: ListView.builder(
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final subjectName = _subjects[index];
                          return GestureDetector(
                            onTap: () => _navigateToSubjectPage(subjectName),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFFECE6F0),
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
                                  Icon(Icons.folder,
                                      color: Color(0xFF65558F), size: 30),
                                  SizedBox(width: 10),
                                  Text(
                                    subjectName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF65558F),
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
        backgroundColor: Color(0xFF65558F),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


