
import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type;
  final String mode;
  final String link;
  final String description;
  final String postedDate;
  final DateTime timestamp;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.mode,
    required this.link,
    required this.description,
    required this.postedDate,
    required this.timestamp,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? '',
      mode: data['mode'] ?? '',
      link: data['link'] ?? '',
      description: data['description'] ?? '',
      postedDate: data['postedDate'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'type': type,
      'mode': mode,
      'link': link,
      'description': description,
      'postedDate': postedDate,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
