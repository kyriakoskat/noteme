import 'package:flutter/material.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_page.dart';

class AllCoursesPage extends StatefulWidget {
  final List<String> initialSubjects;

  const AllCoursesPage({Key? key, required this.initialSubjects})
      : super(key: key);

  @override
  _AllCoursesPageState createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  List<String> _selectedSubjects = [];
  List<Map<String, dynamic>> _allSubjects = []; // Store fetched subjects
  bool _isLoading = true; // Indicate loading state

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List<String>.from(widget.initialSubjects);
    _fetchSubjects(); // Fetch subjects from Firestore
  }

  Future<void> _fetchSubjects() async {
    try {
      // Fetch subjects from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('subjects').get();
      final subjects = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "name": doc["name"], // Assuming each subject has a 'name' field
          "description": doc["description"] ?? "No description available", // Optional description
        };
      }).toList();

      setState(() {
        _allSubjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      setState(() => _isLoading = false);
    }
  }

  void _toggleSubject(String subjectName) {
    setState(() {
      if (_selectedSubjects.contains(subjectName)) {
        _selectedSubjects.remove(subjectName);
      } else {
        _selectedSubjects.add(subjectName);
      }
    });
  }

  void _navigateToSubjectPage(String subjectName, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectPage(subjectName: subjectName, description: description),
      ),
    );
  }

  void _submitSelection() {
    Navigator.pop(context, _selectedSubjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Courses"),
        backgroundColor: Color(0xFF65558F),
      ),
      backgroundColor: Colors.white, // Set page background to white
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _allSubjects[index];
                        final subjectName = subject["name"];
                        final description = subject["description"] ?? "No description available"; // Ensure description is defined
                        final isSelected = _selectedSubjects.contains(subjectName);

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, // Always white background
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Color(0xFF65558F) : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Circle toggle button
                              GestureDetector(
                                onTap: () => _toggleSubject(subjectName),
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? Color(0xFF65558F) : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              // Subject name and navigation
                              GestureDetector(
                                onTap: () => _navigateToSubjectPage(subjectName, description),
                                child: Text(
                                  subjectName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF65558F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
