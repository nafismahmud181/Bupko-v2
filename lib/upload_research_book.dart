import 'package:flutter/material.dart';

// Data Models
class Section {
  final String id;
  final String title;
  // In the real app, this will hold rich text content
  Section({required this.id, required this.title});
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

// SectionTile: Displays a single section with edit/delete actions
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
    return ListTile(
      leading: const Icon(Icons.article_outlined),
      title: Text('${chapterIndex + 1}.${sectionIndex + 1} ${section.title}'),
      trailing: Row(
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
    );
  }
}

// ChapterTile: Displays a chapter as an ExpansionTile with its sections and add section button
class ChapterTile extends StatelessWidget {
  final int chapterIndex;
  final Chapter chapter;
  final void Function(String chapterTitle) onAddSection;
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
            onPressed: () => onAddSection(chapter.title),
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

  // Shows a SnackBar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          onPressed: () => _showSnackBar('Add Chapter pressed'),
        ),
        const SizedBox(height: 16),
        // List all chapters using ChapterTile
        ...chapters.asMap().entries.map((chapterEntry) {
          final chapterIndex = chapterEntry.key;
          final chapter = chapterEntry.value;
          return ChapterTile(
            chapterIndex: chapterIndex,
            chapter: chapter,
            onAddSection: (chapterTitle) => _showSnackBar('Add Section to $chapterTitle'),
            onEditSection: (section) => _showSnackBar('Edit ${section.title}'),
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