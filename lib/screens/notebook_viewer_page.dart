import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


class NotebookViewerPage extends StatefulWidget {
  final String notebookId; // ID of the notebook to display
  final String notebookTitle;

  const NotebookViewerPage({
    Key? key,
    required this.notebookId,
    required this.notebookTitle,
  }) : super(key: key);

  @override
  _NotebookViewerPageState createState() => _NotebookViewerPageState();
}

class _NotebookViewerPageState extends State<NotebookViewerPage> {
  List<String> _images = []; // List of image URLs
  bool _isLoading = true;
  bool isEditable = false; // Dynamically determined based on user authorization
  double _currentNotebookRating = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNotebook();
  }

  Future<void> _initializeNotebook() async {
    try {
      final notebookDoc = await FirebaseFirestore.instance
          .collection('notebooks')
          .doc(widget.notebookId)
          .get();

      if (notebookDoc.exists) {
        final data = notebookDoc.data();

        // Check if the current user is the creator of the notebook
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && data?['created_by'] == currentUser.uid) {
          setState(() {
            isEditable = true;
          });
        }

        // Fetch images from the notebook
        setState(() {
          _images = List<String>.from(data?['images'] ?? []);
          _currentNotebookRating = data?['rating']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("Error initializing notebook: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRatingDialog() {
    double _selectedRating = 0.0; // Local variable to store selected rating

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Notebook"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select your rating:"),
            SizedBox(height: 10),
            RatingBar.builder(
              initialRating: _selectedRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _selectedRating = rating;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitRating(_selectedRating);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _notebookStream() {
  return FirebaseFirestore.instance
      .collection('notebooks')
      .doc(widget.notebookId)
      .snapshots();
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
        await updateUserRating(createdBy);
      }
    } catch (e) {
      print("Error updating notebook rating: $e");
    }
  }

  Future<double> calculateUserAverageRating(String userId) async {
  try {
    final notebooksSnapshot = await FirebaseFirestore.instance
        .collection('notebooks')
        .where('created_by', isEqualTo: userId)
        .where('visibility', isEqualTo: 'public')
        .get();

    if (notebooksSnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int count = 0;

    for (var notebook in notebooksSnapshot.docs) {
      final data = notebook.data();
      if (data.containsKey('rating') && data['rating'] is double) {
        totalRating += data['rating'] as double;
        count++;
      }
    }

    return count > 0 ? (totalRating / count) : 0.0;
  } catch (e) {
    print("Error calculating user average rating: $e");
    return 0.0; // Default to 0 if there's an error
  }
}


  Future<void> updateUserRating(String userId) async {
    final averageRating = await calculateUserAverageRating(userId);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'rating': averageRating});
      print("User rating updated to $averageRating");
    } catch (e) {
      print("Error updating user rating: $e");
    }
  }


  Future<void> _submitRating(double rating) async {
  try {
    final notebookRef = FirebaseFirestore.instance.collection('notebooks').doc(widget.notebookId);

    // Fetch the notebook document
    final snapshot = await notebookRef.get();
    if (!snapshot.exists) {
      throw Exception("Notebook not found");
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception("Invalid notebook data");
    }

    // Ensure `rated_by` is treated as a List
    List<Map<String, dynamic>> ratedBy = List<Map<String, dynamic>>.from(data['rated_by'] ?? []);

    // Get the current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Check if the user has already rated
      final existingRatingIndex =
          ratedBy.indexWhere((entry) => entry['user_id'] == currentUser.uid);

      if (existingRatingIndex != -1) {
        // Update the existing rating
        ratedBy[existingRatingIndex] = {'user_id': currentUser.uid, 'rating': rating};
      } else {
        // Add a new rating
        ratedBy.add({'user_id': currentUser.uid, 'rating': rating});
      }

      // Recalculate the average rating
      double totalRating = ratedBy.fold(0.0, (sum, entry) => sum + (entry['rating'] as double));
      double averageRating = totalRating / ratedBy.length;

      // Update the notebook with the new rating and `rated_by` list
      await notebookRef.update({
        'rated_by': ratedBy,
        'rating': averageRating,
      });

      // Update the creator's overall rating
      final creatorId = data['created_by'];
      if (creatorId != null) {
        await updateUserRating(creatorId);
      }

      // Update the UI
      setState(() {
        _currentNotebookRating = averageRating;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rating submitted successfully!")),
      );
    }
  } catch (e) {
    print("Error submitting rating: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to submit rating.")),
    );
  }
}


  Future<void> _deleteImage(String imageUrl) async {
    if (!isEditable) return; // Do nothing if not editable

    try {
      // Delete the image from Firebase Storage
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      // Remove the image from Firestore
      await FirebaseFirestore.instance
          .collection('notebooks')
          .doc(widget.notebookId)
          .update({
        'images': FieldValue.arrayRemove([imageUrl]),
      });

      // Update the UI
      setState(() {
        _images.remove(imageUrl);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete image.")),
      );
    }
  }

  void _showDeleteConfirmationDialog(String imageUrl) {
    if (!isEditable) return; // Do nothing if not editable

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Image"),
        content: Text("Are you sure you want to delete this image from your notebook?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(imageUrl);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    if (!isEditable) return; // Do nothing if not editable

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('notebooks/${widget.notebookId}/${DateTime.now().toIso8601String()}');
        final uploadTask = await storageRef.putFile(file);

        // Get the download URL
        final imageUrl = await uploadTask.ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('notebooks')
            .doc(widget.notebookId)
            .update({
          'images': FieldValue.arrayUnion([imageUrl]),
        });

        // Add the image to the list
        setState(() {
          _images.add(imageUrl);
        });
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _addImage() async {
    if (!isEditable) return; // Do nothing if not editable

    try {
      final picker = ImagePicker();

      // Handle image picking differently for web and mobile
      final pickedFile = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.gallery,
      );

      if (pickedFile != null) {
        String imageUrl;

        // For web, use `putData` instead of `putFile`
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('notebooks/${widget.notebookId}/${DateTime.now().toIso8601String()}');

          final uploadTask = await storageRef.putData(bytes);
          imageUrl = await uploadTask.ref.getDownloadURL();
        } else {
          final file = File(pickedFile.path);

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('notebooks/${widget.notebookId}/${DateTime.now().toIso8601String()}');

          final uploadTask = await storageRef.putFile(file);
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('notebooks')
            .doc(widget.notebookId)
            .update({
          'images': FieldValue.arrayUnion([imageUrl]),
        });

        // Add the image to the list
        setState(() {
          _images.add(imageUrl);
        });
      }
    } catch (e) {
      print("Error adding image: $e");
    }
  }

  void _viewImageFullscreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.notebookTitle),
      backgroundColor: Color(0xFF65558F),
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _notebookStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("Notebook not found."));
        }

        final notebookData = snapshot.data!.data();
        if (notebookData == null) {
          return Center(child: Text("No data available for this notebook."));
        }

        _currentNotebookRating = notebookData['rating']?.toDouble() ?? 0.0;

        return Column(
          children: [
            // Display notebook images
            Expanded(
              child: _images.isEmpty
                  ? Center(
                      child: Text(
                        "No images added yet.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _images[index];
                        return GestureDetector(
                          onTap: () => _viewImageFullscreen(index),
                          onLongPress: isEditable
                              ? () => _showDeleteConfirmationDialog(imageUrl)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              height: 300,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error, color: Colors.red);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (!isEditable)
              Column(
                children: [
                  Text(
                    "Current Rating: ${_currentNotebookRating.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showRatingDialog,
                    child: Text("Rate Notebook"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF65558F),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

            if (isEditable) ...[
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      height: 100,
                      width: 100,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF65558F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.white, size: 40),
                          SizedBox(height: 5),
                          Text(
                            "Gallery",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      height: 100,
                      width: 100,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF65558F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white, size: 40),
                          SizedBox(height: 5),
                          Text(
                            "Camera",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ],
        );
      },
    ),
  );
}

}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, color: Colors.red);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}