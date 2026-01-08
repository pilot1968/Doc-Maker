import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/main.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:noteapp/database.dart';
import 'package:noteapp/document.dart';

class EditorPage extends StatefulWidget {
  final Document? document; // Null if creating new document

  const EditorPage({super.key, this.document});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // Controller for title
  late TextEditingController titleController;
  // Quill editor controller
  late quill.QuillController quillController;
  // Focus node for editor to maintain cursor
  late FocusNode editorFocusNode;
  // Track if document has changes
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize focus node
    editorFocusNode = FocusNode();

    // Initialize title
    titleController = TextEditingController(
      text: widget.document?.title ?? 'Untitled',
    );

    // Initialize Quill editor
    if (widget.document != null) {
      // Load existing document
      try {
        final doc = quill.Document.fromJson(
          jsonDecode(widget.document!.content),
        );
        quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If error loading, create empty document
        quillController = quill.QuillController.basic();
      }
    } else {
      // Create new empty document
      quillController = quill.QuillController.basic();
    }

    // Listen for changes
    titleController.addListener(() => hasChanges = true);
    quillController.addListener(() {
      hasChanges = true;
      // Ensure focus returns to editor after any change
      if (!editorFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            editorFocusNode.requestFocus();
          }
        });
      }
    });
  }

  // Save document to database
  Future<void> saveDocument() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Please enter a title');
      return;
    }

    // Convert Quill document to JSON
    final content = jsonEncode(
      quillController.document.toDelta().toJson(),
    );
    final now = DateTime.now().toIso8601String();

    if (widget.document == null) {
      // Create new document
      final newDoc = Document(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseHelper.instance.saveDocument(newDoc);
    } else {
      // Update existing document
      final updatedDoc = Document(
        id: widget.document!.id,
        title: title,
        content: content,
        createdAt: widget.document!.createdAt,
        updatedAt: now,
      );
      await DatabaseHelper.instance.updateDocument(updatedDoc);
    }

    hasChanges = false;
    _showMessage('Document saved');
  }

  // Show snackbar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Handle back button press
  Future<bool> onWillPop() async {
    if (hasChanges) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Leave anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Editor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveDocument,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Column(
          children: [
            // Title input field
            _buildTitleField(),

            const Divider(height: 1),
            // Toolbar for text formatting (now at bottom and scrollable)
            _buildToolbar(),

            const Divider(height: 1),
            // Editor area
            Expanded(child: _buildEditor()),
          ],
        ),
      ),
    );
  }

  // Title input field
  _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: titleController,
        decoration: const InputDecoration(
          hintText: 'Document title',
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Quill toolbar with formatting options - now horizontal and scrollable
  Widget _buildToolbar() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Refocus editor when toolbar area is tapped
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !editorFocusNode.hasFocus) {
            editorFocusNode.requestFocus();
          }
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          // Keep focus on editor when hovering toolbar
          if (!editorFocusNode.hasFocus) {
            editorFocusNode.requestFocus();
          }
        },
        child: quill.QuillSimpleToolbar(
          controller: quillController,
          config: const quill.QuillSimpleToolbarConfig(
            multiRowsDisplay: false,
            showAlignmentButtons: true,
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showStrikeThrough: true,
            showColorButton: true,
            showBackgroundColorButton: true,
            showListBullets: true,
            showListNumbers: true,
            showCodeBlock: true,
            showQuote: true,
            showIndent: true,
            showLink: true,
            showClearFormat: true,
          ),
        ),
      ),
    );
  }

  // Quill editor
  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: quill.QuillEditor.basic(
        controller: quillController,
        focusNode: editorFocusNode,
        config: const quill.QuillEditorConfig(
          scrollable: true,
          padding: EdgeInsets.zero,
          placeholder: 'Start writing...',
          autoFocus: true,
          expands: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.dispose();
    editorFocusNode.dispose();
    super.dispose();
  }
}
