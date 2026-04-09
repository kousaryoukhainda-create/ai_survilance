import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import 'register_person_screen.dart';

class KnownPersonsScreen extends StatefulWidget {
  const KnownPersonsScreen({super.key});

  @override
  State<KnownPersonsScreen> createState() => _KnownPersonsScreenState();
}

class _KnownPersonsScreenState extends State<KnownPersonsScreen> {
  List<Map<String, dynamic>> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final persons = await DatabaseHelper.instance.getAllPersons();
      setState(() {
        _persons = persons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load persons: $e')),
        );
      }
    }
  }

  Future<void> _deletePerson(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person'),
        content: const Text('Are you sure you want to delete this person? Their face data will be removed from the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deletePerson(id);
      await _loadPersons();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Known Persons'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _persons.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPersons,
                  child: ListView.builder(
                    itemCount: _persons.length,
                    itemBuilder: (context, index) {
                      final person = _persons[index];
                      return _buildPersonCard(person);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterPersonScreen(),
            ),
          );
          
          if (result == true) {
            await _loadPersons();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No known persons registered',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a person',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> person) {
    final photoPath = person['photoPath'] as String;
    final photoFile = File(photoPath);
    final hasPhoto = photoFile.existsSync();

    final createdAt = DateTime.parse(person['createdAt']);
    final lastSeen = person['lastSeen'] != null 
        ? DateTime.parse(person['lastSeen'])
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasPhoto
              ? Image.file(
                  photoFile,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 32),
                ),
        ),
        title: Text(
          person['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Registered: ${DateFormat('MMM dd, yyyy').format(createdAt)}'),
            if (lastSeen != null)
              Text('Last seen: ${DateFormat('MMM dd, yyyy HH:mm').format(lastSeen)}'),
            if (person['notes'] != null && person['notes'].toString().isNotEmpty)
              Text(
                person['notes'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${person['detectionCount']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Text(
                  'detections',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deletePerson(person['id']),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () {
          // Show person details
          _showPersonDetails(person);
        },
      ),
    );
  }

  void _showPersonDetails(Map<String, dynamic> person) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    person['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Registered', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(person['createdAt']))),
            if (person['lastSeen'] != null)
              _buildDetailRow('Last Seen', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(person['lastSeen']))),
            _buildDetailRow('Detections', '${person['detectionCount']}'),
            if (person['notes'] != null && person['notes'].toString().isNotEmpty)
              _buildDetailRow('Notes', person['notes']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
