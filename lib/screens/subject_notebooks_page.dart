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

Widget _buildCustomVisibilityButton(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged, {
    required bool isLeft,
    required bool isRight,
  }) {
  return Expanded(
    child: GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 8), // Even smaller vertical padding
        decoration: BoxDecoration(
          color: groupValue == value ? Color(0xFF8E78C9) : Colors.transparent, // Active/inactive state
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? Radius.circular(10) : Radius.zero, // Smaller rounded corners
            right: isRight ? Radius.circular(10) : Radius.zero, // Smaller rounded corners
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10, // Significantly smaller font size
              fontWeight: FontWeight.bold,
              color: groupValue == value ? Colors.white : Color(0xFF65558F), // Text color
            ),
          ),
        ),
      ),
    ),
  );
}






 void _showCreateNotebookDialog() {
  String notebookName = ""; // Store the notebook name
  String visibility = "private"; // Default visibility is private

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Ensures the modal adjusts to the content
    backgroundColor: Colors.transparent, // Makes the background transparent
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Color(0xFF65558F), // Purple background color
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60), // Larger rounded top-left corner
            topRight: Radius.circular(60), // Larger rounded top-right corner
          ),
        ),
        padding: EdgeInsets.only(
          left: 20, // More padding on the sides
          right: 20,
          top: 32, // Increase top padding for a better fit
          bottom: MediaQuery.of(context).viewInsets.bottom + 32, // Adjust for the keyboard
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notebook Name Input
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Adjust padding for size
                  decoration: BoxDecoration(
                    color: Color(0xFFECE6F0), // Light purple background
                    borderRadius: BorderRadius.circular(16), // Slightly larger rounded corners
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF65558F), size: 18), // Adjust icon size
                      SizedBox(width: 8), // Adjust spacing
                      Expanded(
                        child: TextField(
                          onChanged: (value) => notebookName = value, // Capture user input
                          style: TextStyle(
                            color: Color(0xFF65558F), // Purple text
                            fontSize: 14, // Adjusted font size
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter notebook name", // Placeholder text
                            hintStyle: TextStyle(
                              color: Color(0xFF65558F).withOpacity(0.6), // Light purple placeholder
                              fontSize: 14, // Match adjusted font size
                            ),
                            border: InputBorder.none, // Remove default borders
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Increase spacing

                // Visibility Options
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 40), // Add horizontal margin for better fit
                  padding: EdgeInsets.all(4), // Adjust padding inside the container
                  decoration: BoxDecoration(
                    color: Color(0xFFECE6F0), // Shared background color
                    borderRadius: BorderRadius.circular(16), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3), // Subtle shadow
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly spaced buttons
                    children: [
                      _buildCustomVisibilityButton(
                        "Private",
                        "private",
                        visibility,
                        (value) => setState(() => visibility = value),
                        isLeft: true, // Left-most button
                        isRight: false,
                      ),
                      Container(
                        width: 1, // Separator line
                        height: 30, // Adjust height for better fit
                        color: Colors.grey[400], // Light gray color
                      ),
                      _buildCustomVisibilityButton(
                        "Public",
                        "public",
                        visibility,
                        (value) => setState(() => visibility = value),
                        isLeft: false,
                        isRight: false,
                      ),
                      Container(
                        width: 1, // Separator line
                        height: 30, // Adjust height for better fit
                        color: Colors.grey[400], // Light gray color
                      ),
                      _buildCustomVisibilityButton(
                        "Only Friends",
                        "friends",
                        visibility,
                        (value) => setState(() => visibility = value),
                        isLeft: false,
                        isRight: true, // Right-most button
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Increase spacing

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
                    backgroundColor: Color(0xFFECE6F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Adjusted radius
                    ),
                  ),
                  child: Icon(Icons.check, color: Color(0xFF65558F), size: 20), // Adjusted size
                ),
              ],
            );
          },
        ),
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
      backgroundColor: Colors.white, // Background color of the page
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
    return GestureDetector(
      onTap: () => _navigateToNotebookViewer(
        notebook['id'],
        notebook['title'] ?? 'Untitled Notebook',
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Spacing around each notebook
        padding: EdgeInsets.all(16), // Inner padding
        decoration: BoxDecoration(
          color: Color(0xFFECE6F0), // Light purple background
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3), // Shadow color
              blurRadius: 8, // Blur effect
              offset: Offset(0, 4), // Shadow position
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out title and "By me"
              children: [
                Text(
                  notebook['title'] ?? 'Notebook name', // Notebook title
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65558F), // Purple text
                  ),
                ),
                Text(
                  "By me", // Static text for now
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF65558F),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8), // Space between rows
            Text(
              "Revised: Just now!", // Placeholder for revision info
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87, // Darker text
              ),
            ),
            SizedBox(height: 4), // Space between lines
            Text(
              "For: ${notebook['visibility'] ?? 'Only me'}", // Dynamic visibility text
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54, // Slightly faded text
              ),
            ),
          ],
        ),
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
