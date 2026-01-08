import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:noteapp/database.dart';
import 'package:noteapp/document.dart';
import 'package:noteapp/editor.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List to store all documents
  List<Document> allDocuments = [];
  // List to store filtered documents when searching
  List<Document> displayedDocuments = [];
  // Controller for search text field
  final TextEditingController searchController =
      TextEditingController();
  // Track if we're in search mode
  bool isSearchMode = false;

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  // Load all documents from database
  Future<void> loadDocuments() async {
    final docs = await DatabaseHelper.instance.getAllDocuments();
    setState(() {
      allDocuments = docs;
      displayedDocuments = docs;
    });
  }

  // Filter documents based on search text
  void filterDocuments(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        displayedDocuments = allDocuments;
      });
      return;
    }

    // Filter by title or content
    final filtered = allDocuments.where((doc) {
      final titleMatch = doc.title.toLowerCase().contains(
        searchText.toLowerCase(),
      );
      final contentMatch = doc.content.toLowerCase().contains(
        searchText.toLowerCase(),
      );
      return titleMatch || contentMatch;
    }).toList();

    setState(() {
      displayedDocuments = filtered;
    });
  }

  // Toggle search mode on/off
  void toggleSearchMode() {
    setState(() {
      isSearchMode = !isSearchMode;
      if (!isSearchMode) {
        searchController.clear();
        displayedDocuments = allDocuments;
      }
    });
  }

  // Delete a document
  Future<void> deleteDocument(int id) async {
    await DatabaseHelper.instance.deleteDocument(id);
    loadDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
    }
  }

  // Navigate to editor page
  Future<void> openEditor({Document? document}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorPage(document: document),
      ),
    );
    // Reload documents when returning from editor
    loadDocuments();
  }

  // Extract plain text from Quill JSON for preview
  String getPreviewText(String jsonContent) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(jsonContent));
      final plainText = doc.toPlainText();
      // Return first 100 characters
      return plainText.length > 100
          ? '${plainText.substring(0, 100)}...'
          : plainText;
    } catch (e) {
      return 'No content';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearchMode
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                ),
                onChanged: filterDocuments,
              )
            : const Text('My Documents'),
        actions: [
          IconButton(
            icon: Icon(
              AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              // Toggle between light and dark mode
              if (AdaptiveTheme.of(context).mode ==
                  AdaptiveThemeMode.dark) {
                AdaptiveTheme.of(context).setLight();
              } else {
                AdaptiveTheme.of(context).setDark();
              }
            },
            tooltip: 'set light/dark mode',
          ),
          IconButton(
            icon: Icon(isSearchMode ? Icons.close : Icons.search),
            onPressed: toggleSearchMode,
            tooltip: isSearchMode ? 'Close search' : 'Search',
          ),
        ],
      ),
      body: displayedDocuments.isEmpty
          ? _buildEmptyState()
          : _buildDocumentList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEditor(),
        tooltip: 'New Document',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Show message when no documents exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchMode ? Icons.search_off : Icons.note_add,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchMode ? 'No documents found' : 'No documents yet',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (!isSearchMode) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap + to create your first document',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // Build the list of documents
  Widget _buildDocumentList() {
    return ListView.builder(
      itemCount: displayedDocuments.length,
      itemBuilder: (context, index) {
        final doc = displayedDocuments[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  // Build individual document card
  Widget _buildDocumentCard(Document doc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          doc.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          getPreviewText(doc.content),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(doc),
        ),
        onTap: () => openEditor(document: doc),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteDocument(doc.id!);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
