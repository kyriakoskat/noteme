import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllCoursesPage extends StatefulWidget {
  final List<String> initialSubjects;
  final List<String> availableSubjects;

  const AllCoursesPage({
    Key? key,
    required this.initialSubjects,
    this.availableSubjects = const [
      "Machine Learning",
      "Algorithms",
      "Computer Vision",
      "Data Science",
      "Artificial Intelligence",
      "Cybersecurity",
      "Software Engineering",
    ],
  }) : super(key: key);

  @override
  _AllCoursesPageState createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  late List<String> _selectedSubjects;

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List.from(widget.initialSubjects);
  }

  void _toggleSelection(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  void _saveSelection() {
    Navigator.pop(context, _selectedSubjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Subjects",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveSelection,
            tooltip: "Save Selection",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: widget.availableSubjects.length,
          itemBuilder: (context, index) {
            final subject = widget.availableSubjects[index];
            final isSelected = _selectedSubjects.contains(subject);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 3,
              child: CheckboxListTile(
                title: Text(
                  subject,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.purple : Colors.black,
                  ),
                ),
                value: isSelected,
                onChanged: (value) => _toggleSelection(subject),
                activeColor: Colors.purple,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          },
        ),
      ),
    );
  }
}
