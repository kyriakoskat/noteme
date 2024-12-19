import 'package:flutter/material.dart';

class AllCoursesPage extends StatefulWidget {
  final List<String> initialSubjects;

  AllCoursesPage({required this.initialSubjects});

  @override
  _AllCoursesPageState createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  final List<String> _allCourses = [
    "Algorithms",
    "Machine Learning",
    "Computer Vision",
    "Computer Science",
    "Computer Human Interaction",
    "Linear Algebra",
    "Artificial Intelligence",
    "Neural Networks",
    "Electromagnetic Fields A",
    "Digital Signal Processing",
    "Operating System I",
    "Robotics",
  ];
  String _selectedCourse = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Your Courses"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedCourse);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _allCourses.length,
        itemBuilder: (context, index) {
          final course = _allCourses[index];
          return RadioListTile(
            title: Text(course),
            value: course,
            groupValue: _selectedCourse,
            onChanged: (value) {
              setState(() {
                _selectedCourse = value.toString();
              });
            },
            activeColor: Colors.purple,
          );
        },
      ),
    );
  }
}
