import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'friends_page.dart'; // Update the path as necessary


class AddFriendPage extends StatefulWidget {
  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(); // Scanner controller
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();

    // Observe lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Start listening to barcode events
    _subscription = _controller.barcodes.listen(_handleBarcode);

    // Start the scanner
    _controller.start();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
  if (capture.barcodes.isNotEmpty) {
    final scannedUserId = capture.barcodes.first.rawValue; // Get the first scanned barcode
    if (scannedUserId != null) {
      await _addFriend(scannedUserId);
      _controller.stop(); // Stop scanning after a successful scan
      
      // Navigate to the Friends Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FriendsPage()),
      );
    }
  }
}


  Future<void> _addFriend(String friendId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No user is logged in");
      }

      final userId = currentUser.uid;

      if (friendId == userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You cannot add yourself as a friend!")),
        );
        return;
      }

      // Add friend to the current user's friends collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend added successfully!")),
      );
    } catch (e) {
      print("Error adding friend: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add friend.")),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_handleBarcode);
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _subscription?.cancel();
        _subscription = null;
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop observing lifecycle changes
    _subscription?.cancel(); // Cancel barcode stream
    _controller.dispose(); // Dispose of the scanner controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan QR to Add Friend"),
        backgroundColor: Color(0xFF65558F),
      ),
      body: MobileScanner(
        controller: _controller,
        fit: BoxFit.cover, // Cover the entire screen with the camera feed
      ),
    );
  }
}
