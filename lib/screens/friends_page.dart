import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_page.dart'; // Import the user's home page

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    // Fetch friends' document IDs from the user's friends subcollection
    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    List<Map<String, dynamic>> friends = [];

    // Fetch details for each friend from the users collection
    for (var friendDoc in friendsSnapshot.docs) {
      try {
        final friendData = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendDoc.id) // Use friendDoc.id to fetch user details
            .get();

        if (friendData.exists) {
          friends.add({
            'id': friendDoc.id,
            'username': friendData.data()?['username'] ?? 'Unknown',
            'rating': friendData.data()?['rating'] ?? 0.0,
          });
        } else {
          print("Friend with ID ${friendDoc.id} does not exist.");
        }
      } catch (e) {
        print("Error fetching friend data for ID ${friendDoc.id}: $e");
      }
    }

    // Sort friends by rating in descending order
    friends.sort((a, b) => b['rating'].compareTo(a['rating']));

    // Update state
    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  } catch (e) {
    print("Error fetching friends: $e");
    setState(() {
      _isLoading = false;
    });
  }
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

  void _navigateToUserHomePage(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserHomePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends", style: GoogleFonts.poppins(fontSize: 18)),
        backgroundColor: Color(0xFF65558F),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? Center(
                  child: Text(
                    "You have no friends added yet.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF65558F),
                        child: Text(
                          friend['username'].isNotEmpty
                              ? friend['username'][0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () => _navigateToUserHomePage(friend['id']),
                        child: Text(
                          friend['username'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: _buildStarRating(friend['rating']),
                    );
                  },
                ),
    );
  }
}
