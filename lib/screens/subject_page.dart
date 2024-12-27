import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notebook_viewer_page.dart';

class SubjectPage extends StatelessWidget {
  final String subjectName;
  final String description;

  const SubjectPage({
    Key? key,
    required this.subjectName,
    required this.description,
  }) : super(key: key);

  

  void _navigateToFriendsNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsNotesPage(subjectName: subjectName),
      ),
    );
  }

  void _navigateToPublicNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicNotesPage(subjectName: subjectName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF65558F),
        title: Text(subjectName),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width, // Ensure it spans the full width of the screen
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/subject_background.png"),
                      fit: BoxFit.cover, // Ensures the image covers the entire area
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            GestureDetector(
  onTap: () => _navigateToFriendsNotes(context),
  child: Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical margin
    padding: EdgeInsets.all(24), // Increased padding
    decoration: BoxDecoration(
      color: Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(16), // Increased border radius
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Friends Notes",
          style: GoogleFonts.poppins(
            fontSize: 20, // Increased font size
            fontWeight: FontWeight.bold,
            color: Color(0xFF65558F),
          ),
        ),
        SizedBox(height: 8), // Increased spacing between title and subtitle
        Text(
          "Check out your friends notes",
          style: GoogleFonts.poppins(
            fontSize: 16, // Increased font size
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),
),
GestureDetector(
  onTap: () => _navigateToPublicNotes(context),
  child: Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical margin
    padding: EdgeInsets.all(24), // Increased padding
    decoration: BoxDecoration(
      color: Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(16), // Increased border radius
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Public Notes",
          style: GoogleFonts.poppins(
            fontSize: 20, // Increased font size
            fontWeight: FontWeight.bold,
            color: Color(0xFF65558F),
          ),
        ),
        SizedBox(height: 8), // Increased spacing between title and subtitle
        Text(
          "Never miss notes posted in public",
          style: GoogleFonts.poppins(
            fontSize: 16, // Increased font size
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),
),

          ],
        ),
      ),
    );
  }
}

class FriendsNotesPage extends StatelessWidget {
  final String subjectName;

  const FriendsNotesPage({Key? key, required this.subjectName}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchFriendsNotes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("User not logged in");
      return [];
    }

    try {
      // Fetch IDs of all friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch notebooks created by friends for the specific subject
      final notesQuery = await FirebaseFirestore.instance
          .collection('notebooks')
          .where('created_by', whereIn: friendIds)
          .where('subject', isEqualTo: subjectName)
          .where('visibility', isEqualTo: 'friends')
          .get();

      return notesQuery.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();
    } catch (e) {
      print("Error fetching friends' notes: $e");
      return [];
    }
  }

  Future<String> _fetchUsername(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['username'] ?? 'Unknown'; // Assuming `username` field exists
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends Notes"),
        backgroundColor: Color(0xFF65558F),
      ),
      backgroundColor: Colors.white, // Set background color to white
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFriendsNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No notes found."));
          }

          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return FutureBuilder<String>(
                future: _fetchUsername(note['created_by'] ?? ''), // Fetch username based on creator ID
                builder: (context, usernameSnapshot) {
                  final username =
                      usernameSnapshot.connectionState == ConnectionState.done
                          ? usernameSnapshot.data ?? 'Unknown'
                          : 'Loading...';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotebookViewerPage(
                            notebookId: note['id'],
                            notebookTitle: note['title'] ?? 'Notebook',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFECE6F0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['title'] ?? 'Notebook name',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF65558F),
                                ),
                              ),
                              Text(
                                "By $username",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFF65558F),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            note['last_opened'] != null
                                ? "Last opened: ${_formatTimestamp(note['last_opened'].toDate())}"
                                : "Never opened",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Rating: ${note['rating']?.toStringAsFixed(1) ?? 'No rating'}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class PublicNotesPage extends StatelessWidget {
  final String subjectName;

  const PublicNotesPage({Key? key, required this.subjectName}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchPublicNotes() async {
    try {
      final notesQuery = await FirebaseFirestore.instance
          .collection('notebooks')
          .where('visibility', isEqualTo: 'public')
          .get();

      final notes = notesQuery.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();
      return notes;
    } catch (e) {
      print("Error fetching public notes: $e");
      return [];
    }
  }

  Future<String> _fetchUsername(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['username'] ?? 'Unknown'; // Assuming `username` is the field in the user's document
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Public Notes"),
        backgroundColor: Color(0xFF65558F),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPublicNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No notes found."));
          }

          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return FutureBuilder<String>(
                future: _fetchUsername(note['created_by'] ?? ''), // Fetch username based on creator ID
                builder: (context, usernameSnapshot) {
                  final username =
                      usernameSnapshot.connectionState == ConnectionState.done
                          ? usernameSnapshot.data ?? 'Unknown'
                          : 'Loading...';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotebookViewerPage(
                            notebookId: note['id'],
                            notebookTitle: note['title'] ?? 'Notebook',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFECE6F0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['title'] ?? 'Notebook name',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF65558F),
                                ),
                              ),
                              Text(
                                "By $username",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFF65558F),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            note['last_opened'] != null
                                ? "Last opened: ${_formatTimestamp(note['last_opened'].toDate())}"
                                : "Never opened",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Rating: ${note['rating']?.toStringAsFixed(1) ?? 'No rating'}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

