import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notebook_viewer_page.dart'; // Import the notebook viewer

class UserHomePage extends StatefulWidget {
  final String userId;

  const UserHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  String _username = "User";
  double _rating = 0.0;
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _username = userDoc['username'] ?? "User";
          _rating = (userDoc['rating'] ?? 0.0).toDouble();
          _subjects = List<String>.from(userDoc['subjects'] ?? []);
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

  void _navigateToNotebooks(String subjectName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSubjectNotebooksPage(
          userId: widget.userId,
          subjectName: subjectName,
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = rating - fullStars >= 0.5;

    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: 20));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: 20));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.grey, size: 20));
      }
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _username,
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        backgroundColor: Color(0xFF65558F),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF65558F),
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                _buildStarRating(_rating),
                SizedBox(height: 20),
                Text(
                  "Notes",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65558F),
                  ),
                ),
                Divider(color: Color(0xFF65558F), thickness: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subjectName = _subjects[index];
                      return GestureDetector(
                        onTap: () => _navigateToNotebooks(subjectName),
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder,
                                color: Color(0xFF65558F),
                                size: 30,
                              ),
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
    );
  }
}

class UserSubjectNotebooksPage extends StatelessWidget {
  final String userId;
  final String subjectName;

  const UserSubjectNotebooksPage({
    Key? key,
    required this.userId,
    required this.subjectName,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchNotebooks() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notebooks')
          .where('created_by', isEqualTo: userId)
          .where('subject', isEqualTo: subjectName)
          .where('visibility', whereIn: ['public', 'friends'])
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print("Error fetching notebooks: $e");
      return [];
    }
  }

  void _navigateToNotebookViewer(BuildContext context, String notebookId, String notebookTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotebookViewerPage(
          notebookId: notebookId,
          notebookTitle: notebookTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        backgroundColor: Color(0xFF65558F),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotebooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No notebooks found.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notebooks = snapshot.data!;
          return ListView.builder(
            itemCount: notebooks.length,
            itemBuilder: (context, index) {
              final notebook = notebooks[index];
              return GestureDetector(
                onTap: () => _navigateToNotebookViewer(
                  context,
                  notebook['id'],
                  notebook['title'] ?? 'Untitled Notebook',
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.book,
                        color: Color(0xFF65558F),
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        notebook['title'] ?? 'Untitled Notebook',
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
          );
        },
      ),
    );
  }
}
