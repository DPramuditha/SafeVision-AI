import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_vision/firebase_service/register_user.dart';

class FirebaseServices {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> addUser(String name, String email, String busNumber, String route, int emergencyContact, DateTime dateTime) async{
    try{
      final userdata = RegisterUser(
        name: name,
        email: email,
        busNumber: busNumber,
        route: route,
        emergencyContact: emergencyContact,
        dateTime: dateTime,
      );
      final Map<String, dynamic> data = userdata.toJson();
      await _usersCollection.add(data);
      print("✅User data added successfully: ${userdata.name}");
    }
    catch (e) {
      print("❌Error adding user data: $e");
      throw Exception("Error adding user data: $e");
    }
  }

  Stream<List<RegisterUser>> getUsers(){
    return _usersCollection.snapshots().map((snapshot) => snapshot.docs.map((doc) => RegisterUser.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList());

    // return _registerUser.snapshots().map((snapshot) => snapshot.docs.map((doc) => Register.fromJson(doc.data() as Map<String, dynamic>,doc.id)).toList());
  }
}