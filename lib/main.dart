import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await DbService.instance.init();
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      title: 'Proportional Recipe Calculator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const RecipeListScreen(),
    );
  }
}

class MasterRecipe {
  const MasterRecipe({
    this.id,
    required this.name,
    required this.ingredients,
  });

  final int? id;
  final String name;
  final List<IngredientItem> ingredients;
}

class IngredientItem {
  const IngredientItem({
    required this.name,
    required this.baseAmount,
    required this.currentAmount,
    required this.unit,
  });

  final String name;
  final double baseAmount;
  final double currentAmount;
  final String unit;

  IngredientItem copyWith({double? currentAmount, String? unit}) {
    return IngredientItem(
      name: name,
      baseAmount: baseAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      unit: unit ?? this.unit,
    );
  }
}

class AdjustmentNote {
  const AdjustmentNote({
    this.id,
    required this.recipeId,
    required this.title,
    required this.memo,
    required this.createdAt,
    required this.items,
  });

  final int? id;
  final int recipeId;
  final String title;
  final String memo;
  final DateTime createdAt;
  final List<NoteItem> items;
}

class NoteItem {
  const NoteItem({
    required this.name,
    required this.baseAmount,
    required this.adjustedAmount,
    required this.unit,
  });

  final String name;
  final double baseAmount;
  final double adjustedAmount;
  final String unit;
}

class DbService {
  DbService._();

  static final DbService instance = DbService._();
  Database? _db;
  bool _isMemoryFallback = false;

  bool get isMemoryFallback => _isMemoryFallback;

  Future<void> init() async {
    if (_db != null) {
      return;
    }
    final String dbPath;
    if (kIsWeb) {
      // path_provider's application documents directory is not available on web.
      dbPath = 'recipe_app.db';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      dbPath = path.join(directory.path, 'recipe_app.db');
    }

    if (kIsWeb) {
      try {
        _db = await _openDatabase(dbPath);
        _isMemoryFallback = false;
      } catch (error, stackTrace) {
        debugPrint(
          'Web database initialization failed. Falling back to in-memory DB: '
          '$error',
        );
        debugPrintStack(stackTrace: stackTrace);
        _db = await _openDatabase(inMemoryDatabasePath);
        _isMemoryFallback = true;
      }
      return;
    }

    _db = await _openDatabase(dbPath);
    _isMemoryFallback = false;
  }

  Future<Database> _openDatabase(String dbPath) {
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<Database> get database async {
    if (_db == null) {
      await init();
    }
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE recipes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)',
    );
    await db.execute(
      "CREATE TABLE ingredients (id INTEGER PRIMARY KEY AUTOINCREMENT, recipe_id INTEGER NOT NULL, name TEXT NOT NULL, base_amount REAL NOT NULL, unit TEXT NOT NULL DEFAULT '')",
    );
    await db.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, recipe_id INTEGER NOT NULL, title TEXT NOT NULL, memo TEXT, created_at TEXT NOT NULL)',
    );
    await db.execute(
      "CREATE TABLE note_items (id INTEGER PRIMARY KEY AUTOINCREMENT, note_id INTEGER NOT NULL, name TEXT NOT NULL, base_amount REAL NOT NULL, adjusted_amount REAL NOT NULL, unit TEXT NOT NULL DEFAULT '')",
    );
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE ingredients ADD COLUMN unit TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE note_items ADD COLUMN unit TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  Future<List<MasterRecipe>> fetchRecipes() async {
    final db = await database;
    final recipeRows = await db.query('recipes', orderBy: 'id DESC');
    final recipes = <MasterRecipe>[];
    for (final row in recipeRows) {
      final id = row['id'] as int;
      final ingredientsRows = await db.query(
        'ingredients',
        where: 'recipe_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
      final ingredients = ingredientsRows
          .map(
            (ingredient) => IngredientItem(
              name: ingredient['name'] as String,
              baseAmount: (ingredient['base_amount'] as num).toDouble(),
              currentAmount: (ingredient['base_amount'] as num).toDouble(),
              unit: ((ingredient['unit'] as String?) ?? '').trim(),
            ),
          )
          .toList();
      recipes.add(
        MasterRecipe(
          id: id,
          name: row['name'] as String,
          ingredients: ingredients,
        ),
      );
    }
    return recipes;
  }

  Future<int> insertRecipe(MasterRecipe recipe) async {
    final db = await database;
    final recipeId = await db.insert('recipes', {'name': recipe.name});
    final batch = db.batch();
    for (final ingredient in recipe.ingredients) {
      batch.insert('ingredients', {
        'recipe_id': recipeId,
        'name': ingredient.name,
        'base_amount': ingredient.baseAmount,
        'unit': ingredient.unit,
      });
    }
    await batch.commit(noResult: true);
    return recipeId;
  }

  Future<void> updateRecipe(MasterRecipe recipe) async {
    final id = recipe.id;
    if (id == null) {
      return;
    }
    final db = await database;
    await db.update(
      'recipes',
      {'name': recipe.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [id],
    );
    final batch = db.batch();
    for (final ingredient in recipe.ingredients) {
      batch.insert('ingredients', {
        'recipe_id': id,
        'name': ingredient.name,
        'base_amount': ingredient.baseAmount,
        'unit': ingredient.unit,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteRecipe(int recipeId) async {
    final db = await database;
    final noteRows = await db.query(
      'notes',
      columns: ['id'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    final batch = db.batch();
    for (final row in noteRows) {
      batch.delete(
        'note_items',
        where: 'note_id = ?',
        whereArgs: [row['id']],
      );
    }
    batch.delete('notes', where: 'recipe_id = ?', whereArgs: [recipeId]);
    batch.delete(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    batch.delete('recipes', where: 'id = ?', whereArgs: [recipeId]);
    await batch.commit(noResult: true);
  }

  Future<int> insertNote({
    required int recipeId,
    required String title,
    required String memo,
    required List<NoteItem> items,
  }) async {
    final db = await database;
    final noteId = await db.insert('notes', {
      'recipe_id': recipeId,
      'title': title,
      'memo': memo,
      'created_at': DateTime.now().toIso8601String(),
    });
    final batch = db.batch();
    for (final item in items) {
      batch.insert('note_items', {
        'note_id': noteId,
        'name': item.name,
        'base_amount': item.baseAmount,
        'adjusted_amount': item.adjustedAmount,
        'unit': item.unit,
      });
    }
    await batch.commit(noResult: true);
    return noteId;
  }

  Future<List<AdjustmentNote>> fetchNotes(int recipeId) async {
    final db = await database;
    final noteRows = await db.query(
      'notes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'created_at DESC',
    );
    final notes = <AdjustmentNote>[];
    for (final row in noteRows) {
      final noteId = row['id'] as int;
      final itemRows = await db.query(
        'note_items',
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'id ASC',
      );
      final items = itemRows
          .map(
            (item) => NoteItem(
              name: item['name'] as String,
              baseAmount: (item['base_amount'] as num).toDouble(),
              adjustedAmount: (item['adjusted_amount'] as num).toDouble(),
              unit: ((item['unit'] as String?) ?? '').trim(),
            ),
          )
          .toList();
      notes.add(
        AdjustmentNote(
          id: noteId,
          recipeId: recipeId,
          title: row['title'] as String,
          memo: (row['memo'] as String?) ?? '',
          createdAt: DateTime.parse(row['created_at'] as String),
          items: items,
        ),
      );
    }
    return notes;
  }
}

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<MasterRecipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = DbService.instance.fetchRecipes();
  }

  void _refresh() {
    setState(() {
      _recipesFuture = DbService.instance.fetchRecipes();
    });
  }

  Future<void> _confirmDelete(MasterRecipe recipe) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text(
          'Delete "${recipe.name}". All history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true && recipe.id != null) {
      await DbService.instance.deleteRecipe(recipe.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
      ),
      body: FutureBuilder<List<MasterRecipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return const Center(
              child: Text('No recipes yet. Use the button below to add one.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                child: ListTile(
                  title: Text(recipe.name),
                  subtitle: Text('Ingredients: ${recipe.ingredients.length}'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveCalculatorScreen(recipe: recipe),
                      ),
                    );
                    _refresh();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MasterRecipeEditorScreen(recipe: recipe),
                            ),
                          );
                          _refresh();
                        },
                      ),
                      IconButton(
                        tooltip: 'History',
                        icon: const Icon(Icons.history),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistoryScreen(recipe: recipe),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(recipe),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterRecipeEditorScreen()),
          );
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
    );
  }
}

class MasterRecipeEditorScreen extends StatefulWidget {
  const MasterRecipeEditorScreen({super.key, this.recipe});

  final MasterRecipe? recipe;

  @override
  State<MasterRecipeEditorScreen> createState() =>
      _MasterRecipeEditorScreenState();
}

class _MasterRecipeEditorScreenState extends State<MasterRecipeEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<_IngredientEditor> _editors = [];

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe != null) {
      _nameController.text = recipe.name;
      for (final item in recipe.ingredients) {
        _editors.add(
          _IngredientEditor(
            nameController: TextEditingController(text: item.name),
            baseController:
                TextEditingController(text: formatAmount(item.baseAmount)),
            unitController: TextEditingController(text: item.unit),
          ),
        );
      }
    } else {
      _editors.add(_IngredientEditor.empty());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final editor in _editors) {
      editor.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _editors.add(_IngredientEditor.empty());
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a recipe name.');
      return;
    }
    final ingredients = <IngredientItem>[];
    for (final editor in _editors) {
      final ingredientName = editor.nameController.text.trim();
      final baseAmount = parseAmount(editor.baseController.text);
      final unit = editor.unitController.text.trim();
      final isEmptyRow =
          ingredientName.isEmpty && baseAmount == null && unit.isEmpty;
      if (isEmptyRow) {
        continue;
      }
      if (ingredientName.isEmpty || baseAmount == null) {
        _showMessage('Enter ingredient name and base amount.');
        return;
      }
      if (unit.length > maxUnitLength) {
        _showMessage('Unit must be at most $maxUnitLength characters.');
        return;
      }
      ingredients.add(
        IngredientItem(
          name: ingredientName,
          baseAmount: baseAmount,
          currentAmount: baseAmount,
          unit: unit,
        ),
      );
    }
    if (ingredients.isEmpty) {
      _showMessage('Add at least one ingredient.');
      return;
    }
    if (widget.recipe == null) {
      await DbService.instance.insertRecipe(
        MasterRecipe(name: name, ingredients: ingredients),
      );
    } else {
      await DbService.instance.updateRecipe(
        MasterRecipe(
          id: widget.recipe!.id,
          name: name,
          ingredients: ingredients,
        ),
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Create Recipe' : 'Edit Recipe'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Recipe name'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ingredients (base amount + unit)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _editors.length; i++)
            _IngredientEditorRow(
              editor: _editors[i],
              onRemove: _editors.length > 1
                  ? () {
                      setState(() {
                        _editors.removeAt(i).dispose();
                      });
                    }
                  : null,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
          ),
        ],
      ),
    );
  }
}

class _IngredientEditor {
  _IngredientEditor({
    required this.nameController,
    required this.baseController,
    required this.unitController,
  });

  factory _IngredientEditor.empty() => _IngredientEditor(
        nameController: TextEditingController(),
        baseController: TextEditingController(),
        unitController: TextEditingController(),
      );

  final TextEditingController nameController;
  final TextEditingController baseController;
  final TextEditingController unitController;

  void dispose() {
    nameController.dispose();
    baseController.dispose();
    unitController.dispose();
  }
}

class _IngredientEditorRow extends StatelessWidget {
  const _IngredientEditorRow({
    required this.editor,
    required this.onRemove,
  });

  final _IngredientEditor editor;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: editor.nameController,
              decoration: const InputDecoration(labelText: 'Ingredient'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: editor.baseController,
              decoration: const InputDecoration(labelText: 'Base amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: editor.unitController,
              decoration: const InputDecoration(
                labelText: 'Unit (optional)',
              ),
              maxLength: maxUnitLength,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class LiveCalculatorScreen extends StatefulWidget {
  const LiveCalculatorScreen({super.key, required this.recipe});

  final MasterRecipe recipe;

  @override
  State<LiveCalculatorScreen> createState() => _LiveCalculatorScreenState();
}

class _LiveCalculatorScreenState extends State<LiveCalculatorScreen> {
  late List<IngredientItem> _items;
  final List<TextEditingController> _controllers = [];
  bool _isUpdating = false;
  double _ratio = 1;

  @override
  void initState() {
    super.initState();
    _items = widget.recipe.ingredients
        .map(
          (item) => IngredientItem(
            name: item.name,
            baseAmount: item.baseAmount,
            currentAmount: item.baseAmount,
            unit: item.unit,
          ),
        )
        .toList();
    for (final item in _items) {
      _controllers.add(
        TextEditingController(text: formatAmount(item.currentAmount)),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyRatio(double ratio) {
    if (ratio.isNaN || ratio.isInfinite) {
      return;
    }
    _isUpdating = true;
    setState(() {
      _ratio = ratio;
      for (int i = 0; i < _items.length; i++) {
        final adjusted = _items[i].baseAmount * ratio;
        _items[i] = _items[i].copyWith(currentAmount: adjusted);
        _controllers[i].text = formatAmount(adjusted);
      }
    });
    _isUpdating = false;
  }

  void _onAmountChanged(int index, String value) {
    if (_isUpdating) {
      return;
    }
    final newValue = parseAmount(value);
    if (newValue == null) {
      return;
    }
    final base = _items[index].baseAmount;
    if (base == 0) {
      return;
    }
    _applyRatio(newValue / base);
  }

  Future<void> _saveNote() async {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: memoController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Memo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != true || widget.recipe.id == null) {
      titleController.dispose();
      memoController.dispose();
      return;
    }
    final title = titleController.text.trim();
    final memo = memoController.text.trim();
    await DbService.instance.insertNote(
      recipeId: widget.recipe.id!,
      title: title.isEmpty ? 'Adjustment note' : title,
      memo: memo,
      items: _items
          .map(
            (item) => NoteItem(
              name: item.name,
              baseAmount: item.baseAmount,
              adjustedAmount: item.currentAmount,
              unit: item.unit,
            ),
          )
          .toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved note.')),
      );
    }
    titleController.dispose();
    memoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ratio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAmount(_ratio),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyRatio(1),
                        child: const Text('Reset to base'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _saveNote,
                        icon: const Icon(Icons.save),
                        label: const Text('Save note'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _items.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _items[i].name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ValueBlock(
                            label: 'Base',
                            value: formatAmountWithUnit(
                              _items[i].baseAmount,
                              _items[i].unit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controllers[i],
                            decoration: InputDecoration(
                              labelText: 'Adjusted',
                              suffixText: _items[i].unit.isEmpty
                                  ? null
                                  : _items[i].unit,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) => _onAmountChanged(i, value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.recipe});

  final MasterRecipe recipe;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<AdjustmentNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = DbService.instance.fetchNotes(widget.recipe.id ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.recipe.name} History'),
      ),
      body: FutureBuilder<List<AdjustmentNote>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                child: ExpansionTile(
                  title: Text(note.title),
                  subtitle: Text(formatDate(note.createdAt)),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (note.memo.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(note.memo),
                      ),
                    for (final item in note.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${item.name}  ${formatAmountWithUnit(item.baseAmount, item.unit)} -> ${formatAmountWithUnit(item.adjustedAmount, item.unit)}',
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

double? parseAmount(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

String formatAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

const int maxUnitLength = 20;

String formatAmountWithUnit(double value, String unit) {
  final normalizedUnit = unit.trim();
  if (normalizedUnit.isEmpty) {
    return formatAmount(value);
  }
  return '${formatAmount(value)} $normalizedUnit';
}

String formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
