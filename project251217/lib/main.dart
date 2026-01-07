import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyLifeHelperApp());
}

class MyLifeHelperApp extends StatelessWidget {
  const MyLifeHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '生活助手',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainHomePage(),
    );
  }
}

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _currentIndex = 0;
  late Database _db;
  bool _isDbLoaded = false;

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  // --- 資料庫邏輯 ---
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'helper.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY, title TEXT, amount REAL, date TEXT)');
        await db.execute('CREATE TABLE todos (id INTEGER PRIMARY KEY, content TEXT, isDone INTEGER)');
      },
    );
    _refreshData();
  }

  Future<void> _refreshData() async {
    final expData = await _db.query('expenses', orderBy: 'id DESC');
    final todoData = await _db.query('todos', orderBy: 'id DESC');
    setState(() {
      _expenses = expData;
      _todos = todoData;
      _isDbLoaded = true;
    });
  }

  // --- 記帳功能 ---
  Future<void> _addExpense(String title, double amount) async {
    await _db.insert('expenses', {
      'title': title,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    });
    _refreshData();
  }

  // --- 待辦功能 ---
  Future<void> _addTodo(String content) async {
    await _db.insert('todos', {'content': content, 'isDone': 0});
    _refreshData();
  }

  Future<void> _toggleTodo(int id, int currentStatus) async {
    await _db.update('todos', {'isDone': currentStatus == 0 ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  Future<void> _deleteItem(String table, int id) async {
    await _db.delete(table, where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  // --- UI 組件 ---
  @override
  Widget build(BuildContext context) {
    if (!_isDbLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? '我的記帳本' : '待辦清單'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _currentIndex == 0 ? _buildExpensePage() : _buildTodoPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.money), label: '記帳'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: '待辦'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpensePage() {
    double total = _expenses.fold(0, (sum, item) => sum + item['amount']);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('總支出：', style: TextStyle(fontSize: 18)), Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red))],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _expenses.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.shopping_cart)),
              title: Text(_expenses[i]['title']),
              subtitle: Text(_expenses[i]['date']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\$${_expenses[i]['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _deleteItem('expenses', _expenses[i]['id'])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoPage() {
    return ListView.builder(
      itemCount: _todos.length,
      itemBuilder: (ctx, i) => ListTile(
        leading: Checkbox(
          value: _todos[i]['isDone'] == 1,
          onChanged: (_) => _toggleTodo(_todos[i]['id'], _todos[i]['isDone']),
        ),
        title: Text(_todos[i]['content'], style: TextStyle(decoration: _todos[i]['isDone'] == 1 ? TextDecoration.lineThrough : null)),
        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteItem('todos', _todos[i]['id'])),
      ),
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_currentIndex == 0 ? '新增消費' : '新增待辦'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: _currentIndex == 0 ? '項目名稱' : '內容')),
            if (_currentIndex == 0) TextField(controller: amountController, decoration: const InputDecoration(labelText: '金額'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (_currentIndex == 0) {
                _addExpense(titleController.text, double.tryParse(amountController.text) ?? 0);
              } else {
                _addTodo(titleController.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}