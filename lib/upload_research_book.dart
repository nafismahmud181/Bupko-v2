import 'package:flutter/material.dart';

// Data Models
class Section {
  final String id;
  final String title;
  String? content; // New nullable field for section text
  // In the real app, this will hold rich text content
  Section({required this.id, required this.title, this.content});
}

class Chapter {
  final String id;
  final String title;
  final List<Section> sections;
  Chapter({required this.id, required this.title, required this.sections});
}

// Mock Data for Thesis/Report Template
final List<Chapter> mockChapters = [
  Chapter(
    id: 'ch1',
    title: 'Introduction',
    sections: [
      Section(id: 's1', title: 'Background'),
      Section(id: 's2', title: 'Problem Statement'),
      Section(id: 's3', title: 'Objectives'),
      Section(id: 's4', title: 'Scope'),
    ],
  ),
  Chapter(
    id: 'ch2',
    title: 'Literature Review',
    sections: [
      Section(id: 's5', title: 'Previous Work'),
      Section(id: 's6', title: 'Theoretical Framework'),
    ],
  ),
  Chapter(
    id: 'ch3',
    title: 'Methodology',
    sections: [
      Section(id: 's7', title: 'Research Design'),
      Section(id: 's8', title: 'Data Collection'),
      Section(id: 's9', title: 'Data Analysis'),
    ],
  ),
  Chapter(
    id: 'ch4',
    title: 'Results & Discussion',
    sections: [
      Section(id: 's10', title: 'Findings'),
      Section(id: 's11', title: 'Interpretation'),
    ],
  ),
  Chapter(
    id: 'ch5',
    title: 'Conclusion & Recommendations',
    sections: [
      Section(id: 's12', title: 'Summary'),
      Section(id: 's13', title: 'Recommendations'),
    ],
  ),
];

class UploadResearchBookPage extends StatefulWidget {
  const UploadResearchBookPage({Key? key}) : super(key: key);

  @override
  State<UploadResearchBookPage> createState() => _UploadResearchBookPageState();
}

// SectionTile: Displays a single section with edit/delete actions and content
class SectionTile extends StatelessWidget {
  final int chapterIndex;
  final int sectionIndex;
  final Section section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SectionTile({
    Key? key,
    required this.chapterIndex,
    required this.sectionIndex,
    required this.section,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.article_outlined),
      title: Row(
        children: [
          Expanded(child: Text('${chapterIndex + 1}.${sectionIndex + 1} ${section.title}')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: section.content != null && section.content!.trim().isNotEmpty
              ? Text(section.content!)
              : const Text('No content. Click edit to add.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ),
      ],
    );
  }
}

// ChapterTile: Displays a chapter as an ExpansionTile with its sections and add section button
class ChapterTile extends StatelessWidget {
  final int chapterIndex;
  final Chapter chapter;
  final void Function(String chapterId) onAddSection;
  final void Function(Section section) onEditSection;
  final void Function(Section section) onDeleteSection;

  const ChapterTile({
    Key? key,
    required this.chapterIndex,
    required this.chapter,
    required this.onAddSection,
    required this.onEditSection,
    required this.onDeleteSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey(chapter.id),
      initiallyExpanded: true,
      title: Text(
        'CHAPTER ${chapterIndex + 1}: ${chapter.title.toUpperCase()}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        // List all sections in this chapter
        ...chapter.sections.asMap().entries.map((sectionEntry) {
          final sectionIndex = sectionEntry.key;
          final section = sectionEntry.value;
          return SectionTile(
            chapterIndex: chapterIndex,
            sectionIndex: sectionIndex,
            section: section,
            onEdit: () => onEditSection(section),
            onDelete: () => onDeleteSection(section),
          );
        }),
        // Add Section button
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Section'),
            onPressed: () => onAddSection(chapter.id),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _UploadResearchBookPageState extends State<UploadResearchBookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // For demonstration, use a local copy of the mockChapters
  late List<Chapter> chapters;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    chapters = List<Chapter>.from(mockChapters);
  }

  // Shows a dialog to get a title from the user
  Future<String?> _showTitleDialog({required String title, String? hintText}) async {
    final TextEditingController controller = TextEditingController();
    String? result;
    await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: hintText ?? 'Enter title'),
                onChanged: (_) => setState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => result = value);
    return result;
  }

  // Add Chapter method
  Future<void> _addChapter() async {
    final newTitle = await _showTitleDialog(title: 'Add Chapter', hintText: 'Chapter title');
    if (newTitle != null) {
      setState(() {
        chapters.add(
          Chapter(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: newTitle,
            sections: [],
          ),
        );
      });
    }
  }

  // Shows a SnackBar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Edit a section: open SectionEditorPage and update content if changed
  Future<void> _editSection(Section section) async {
    final newContent = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SectionEditorPage(
          sectionTitle: section.title,
          sectionContent: section.content,
        ),
      ),
    );
    if (newContent != null) {
      setState(() {
        // Find and update the section's content
        for (final chapter in chapters) {
          for (final s in chapter.sections) {
            if (s.id == section.id) {
              s.content = newContent;
              break;
            }
          }
        }
      });
    }
  }

  // Add Section method
  Future<void> _addSection(String chapterId) async {
    final newTitle = await _showTitleDialog(title: 'Add Section', hintText: 'Section title');
    if (newTitle != null) {
      setState(() {
        final chapter = chapters.firstWhere((c) => c.id == chapterId, orElse: () => throw Exception('Chapter not found'));
        chapter.sections.add(
          Section(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: newTitle,
          ),
        );
      });
    }
  }

  // Builds the Outline tab UI
  Widget _buildOutlineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add Chapter button
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Chapter'),
          onPressed: _addChapter,
        ),
        const SizedBox(height: 16),
        // List all chapters using ChapterTile
        ...chapters.asMap().entries.map((chapterEntry) {
          final chapterIndex = chapterEntry.key;
          final chapter = chapterEntry.value;
          return ChapterTile(
            chapterIndex: chapterIndex,
            chapter: chapter,
            onAddSection: _addSection,
            onEditSection: _editSection,
            onDeleteSection: (section) => _showSnackBar('Delete ${section.title}'),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Awesome Thesis Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Outline'),
            Tab(text: 'Figures & Tables'),
            Tab(text: 'References'),
            Tab(text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOutlineTab(),
          // Placeholder for Figures & Tables tab
          const Center(child: Text('List of Figures and Tables will be generated here')),
          // Placeholder for References tab
          const Center(child: Text('Bibliography/References section')),
          // Placeholder for Export tab
          const Center(child: Text('Export options (PDF, Word) will be here')),
        ],
      ),
    );
  }
}

// SectionEditorPage: A simple text editor for editing section content
class SectionEditorPage extends StatefulWidget {
  final String sectionTitle;
  final String? sectionContent;

  const SectionEditorPage({Key? key, required this.sectionTitle, this.sectionContent}) : super(key: key);

  @override
  State<SectionEditorPage> createState() => _SectionEditorPageState();
}

class _SectionEditorPageState extends State<SectionEditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.sectionContent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _controller,
          maxLines: null,
          minLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Section Content',
            alignLabelWithHint: true,
          ),
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }
} 