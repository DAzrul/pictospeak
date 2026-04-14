import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = 'Local Food';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEKSYEN 1: Tambah Pictogram Baru
          const Text('Add Local Context Pictogram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kotak Upload Gambar (Dotted style mockup)
                const Text('1. Image Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid)),
                  child: Column(
                    children: [
                      Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fastfood, color: Colors.orange, size: 30)),
                      const SizedBox(height: 8),
                      const Text('Nasi Lemak', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('nasi-lemak.png', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, side: BorderSide(color: Colors.grey.shade300)),
                          child: const Text('Change Image')
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Textfields Label & Category
                const Text('2. Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(decoration: InputDecoration(hintText: 'Nasi Lemak', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 16),

                const Text('3. Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: ['Local Food', 'Drinks', 'Places', 'Actions'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 16),

                const Text('4. Predictive Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(decoration: InputDecoration(hintText: 'Spicy, Sambal', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 4),
                Text('When this pictogram is selected, SVO engine will suggest this tag.', style: TextStyle(fontSize: 10, color: Colors.blueGrey[400])),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pictogram Added! (Mockup)')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Add Pictogram to Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // SEKSYEN 2: Senarai Pictogram Sedia Ada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Existing Pictograms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Text('8 items', style: TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(hintText: 'Search pictograms...', prefixIcon: const Icon(Icons.search), isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          // Mock List Item
          _buildListItem('Nasi Lemak', 'Local Food', 'local', '#Sambal', Icons.fastfood, Colors.orange),
          _buildListItem('Toilet', 'Needs', 'default', '#Urgent', Icons.wc, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildListItem(String name, String cat, String type, String tag, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(cat, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: type == 'local' ? Colors.orange.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: Text(type, style: TextStyle(fontSize: 10, color: type == 'local' ? Colors.orange.shade800 : Colors.blue.shade800))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: (){}),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: (){}),
        ],
      ),
    );
  }
}