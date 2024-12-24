import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notebook_viewer_page.dart'; // Import your NotebookViewerPage

class SubjectNotebooksPage extends StatefulWidget {
  final String subjectName;

  const SubjectNotebooksPage({Key? key, required this.subjectName})
      : super(key: key);

  @override
  _SubjectNotebooksPageState createState() => _SubjectNotebooksPageState();
}

class _SubjectNotebooksPageState extends State<SubjectNotebooksPage> {
  List<Map<String, dynamic>> _notebooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotebooks();
  }

  Future<void> fetchNotebooks() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Query all notebooks created by the user for the subject
      final notebooksSnapshot = await FirebaseFirestore.instance
          .collection('notebooks')
          .where('created_by', isEqualTo: userId)
          .where('subject', isEqualTo: widget.subjectName)
          .get();

      setState(() {
        _notebooks = notebooksSnapshot.docs.map((doc) {
          return {
            "id": doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching notebooks: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewNotebook(String title, String visibility) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("Error: User not logged in.");
        return;
      }

      final newNotebook = {
        "title": title,
        "created_by": userId,
        "subject": widget.subjectName,
        "visibility": visibility,
        "created_at": FieldValue.serverTimestamp(),
        "rating": visibility == "public" ? 0.0 : null, // Only public notebooks have ratings
        "rated_by": [], // Track users who have rated
      };

      // Save notebook to the global notebooks collection
      final notebookRef = await FirebaseFirestore.instance
          .collection('notebooks')
          .add(newNotebook);

      print("Notebook created in global collection: ${notebookRef.id}");

      // Save notebook to the user's notebooks subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notebooks')
          .doc(notebookRef.id)
          .set(newNotebook);

      print("Notebook added to user's notebooks subcollection.");

      // Refresh the notebooks list (if applicable)
      fetchNotebooks();
    } catch (e) {
      print("Error creating notebook: $e");
    }
  }

  void _showCreateNotebookDialog() {
    String notebookName = ""; // Store the notebook name
    String visibility = "private"; // Default visibility is private

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF65558F),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notebook Name Input
                  TextField(
                    onChanged: (value) => notebookName = value,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter notebook name",
                      hintStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      fillColor: Color(0xFF8E78C9),
                      prefixIcon: Icon(Icons.edit, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Visibility Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildVisibilityOption("Private", "private", visibility,
                          (value) => setState(() => visibility = value)),
                      _buildVisibilityOption("Public", "public", visibility,
                          (value) => setState(() => visibility = value)),
                      _buildVisibilityOption("Friends", "friends", visibility,
                          (value) => setState(() => visibility = value)),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (notebookName.isNotEmpty) {
                        Navigator.pop(context); // Close the dialog
                        _createNewNotebook(notebookName, visibility); // Create notebook
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Notebook name cannot be empty."),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Icon(Icons.check, color: Color(0xFF65558F)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisibilityOption(
      String label, String value, String groupValue, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: groupValue == value ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (groupValue == value)
            Container(
              margin: EdgeInsets.only(top: 5),
              height: 5,
              width: 20,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  void _navigateToNotebookViewer(String notebookId, String notebookTitle) {
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
        title: Text(widget.subjectName),
        backgroundColor: Color(0xFF65558F),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notebooks.isEmpty
              ? Center(
                  child: Text(
                    "No notebooks found for this subject.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = _notebooks[index];
                    return ListTile(
                      title: Text(
                        notebook['title'] ?? 'Untitled Notebook',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      subtitle: Text(
                        "Visibility: ${notebook['visibility']}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () => _navigateToNotebookViewer(
                        notebook['id'],
                        notebook['title'] ?? 'Untitled Notebook',
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNotebookDialog,
        backgroundColor: Color(0xFF65558F),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
