Esimport 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BakeryApp());
}

class RawMaterial {
  final int id;
  String name;
  String unit; // "جرام" أو "حبة"
  double stockQty;
  double costPerUnit;

  RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    this.stockQty = 0,
    this.costPerUnit = 0,
  });
}

class RecipeItem {
  final int materialId;
  final double qtyNeeded;

  RecipeItem({required this.materialId, required this.qtyNeeded});
}

class Product {
  final int id;
  String name;
  double salePrice;
  List<RecipeItem> recipe;

  Product({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.recipe,
  });
}

class SaleRecord {
  final String productName;
  final int qty;
  final double totalPrice;
  final double totalCost;
  final DateTime date;

  SaleRecord({
    required this.productName,
    required this.qty,
    required this.totalPrice,
    required this.totalCost,
    required this.date,
  });
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متجر الحلويات',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<RawMaterial> materials = [
    RawMaterial(id: 1, name: "دقيق فاخر", unit: "جرام", stockQty: 5000, costPerUnit: 0.004),
    RawMaterial(id: 2, name: "شوكولاتة داكنة", unit: "جرام", stockQty: 1000, costPerUnit: 0.05),
    RawMaterial(id: 3, name: "شوكولاتة بيضاء", unit: "جرام", stockQty: 1000, costPerUnit: 0.045),
    RawMaterial(id: 4, name: "بيض", unit: "حبة", stockQty: 30, costPerUnit: 0.6),
  ];

  List<Product> products = [];
  List<SaleRecord> salesHistory = [];

  @override
  void initState() {
    super.initState();
    products.add(
      Product(
        id: 1,
        name: "كيكة الشوكولاتة وسط",
        salePrice: 60.0,
        recipe: [
          RecipeItem(materialId: 1, qtyNeeded: 200),
          RecipeItem(materialId: 2, qtyNeeded: 10),
          RecipeItem(materialId: 3, qtyNeeded: 10),
          RecipeItem(materialId: 4, qtyNeeded: 2),
        ],
      ),
    );
  }

  void _sellProduct(Product product) {
    for (var item in product.recipe) {
      final mat = materials.firstWhere((m) => m.id == item.materialId);
      if (mat.stockQty < item.qtyNeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("المخزون غير كافٍ من: ${mat.name} (المتبقي: ${mat.stockQty} ${mat.unit})"),
          ),
        );
        return;
      }
    }

    double cakeCost = 0;
    setState(() {
      for (var item in product.recipe) {
        final mat = materials.firstWhere((m) => m.id == item.materialId);
        mat.stockQty -= item.qtyNeeded;
        cakeCost += (item.qtyNeeded * mat.costPerUnit);
      }

      salesHistory.insert(
        0,
        SaleRecord(
          productName: product.name,
          qty: 1,
          totalPrice: product.salePrice,
          totalCost: cakeCost,
          date: DateTime.now(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("تم البيع بنجاح! خصم المكونات تم آلياً. الربح: ${(product.salePrice - cakeCost).toStringAsFixed(2)} ر.س"),
      ),
    );
  }

  void _addPurchase(RawMaterial mat, double addedQty, double totalPrice) {
    setState(() {
      double totalOldValue = mat.stockQty * mat.costPerUnit;
      double newTotalQty = mat.stockQty + addedQty;
      double newCostPerUnit = (totalOldValue + totalPrice) / newTotalQty;

      mat.stockQty = newTotalQty;
      mat.costPerUnit = newCostPerUnit;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF5D4037),
        content: Text("تمت إضافة $addedQty ${mat.unit} إلى ${mat.name}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildSalesScreen(),
      _buildInventoryScreen(),
      _buildProductsRecipeScreen(),
      _buildReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("متجر الكيك والحلويات", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF5D4037),
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: "الكاشير"),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: "المشتريات والمخزن"),
          NavigationDestination(icon: Icon(Icons.cake), label: "الأصناف المجمعة"),
          NavigationDestination(icon: Icon(Icons.analytics), label: "التقارير"),
        ],
      ),
    );
  }

  Widget _buildSalesScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("الأصناف المتوفرة للبيع:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD7CCC8),
                      child: Icon(Icons.cake, color: Color(0xFF5D4037)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text("السعر: ${p.salePrice} ر.س"),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _sellProduct(p),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text("بيع"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("المخزون بالجرام والحبة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("مادة جديدة"),
                onPressed: _showAddNewMaterialDialog,
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: materials.length,
              itemBuilder: (ctx, i) {
                final m = materials[i];
                return Card(
                  child: ListTile(
                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("الرصيد: ${m.stockQty.toStringAsFixed(1)} ${m.unit}\nسعر الـ ${m.unit}: ${(m.costPerUnit).toStringAsFixed(4)} ر.س"),
                    trailing: ElevatedButton(
                      child: const Text("+ توريد"),
                      onPressed: () => _showPurchaseDialog(m),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductsRecipeScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("شجرة المكونات والوصفات:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("كيكة جديدة"),
                onPressed: _showAddProductDialog,
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return ExpansionTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("سعر البيع: ${p.salePrice} ر.س"),
                  children: p.recipe.map((r) {
                    final mat = materials.firstWhere((m) => m.id == r.materialId);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, size: 18),
                      title: Text("${mat.name}: ${r.qtyNeeded} ${mat.unit}"),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportsScreen() {
    double totalSales = salesHistory.fold(0, (sum, s) => sum + s.totalPrice);
    double totalCost = salesHistory.fold(0, (sum, s) => sum + s.totalCost);
    double netProfit = totalSales - totalCost;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            color: const Color(0xFFEFEBE9),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("المبيعات", "${totalSales.toStringAsFixed(1)} ر.س", Colors.blue),
                  _statItem("التكلفة", "${totalCost.toStringAsFixed(1)} ر.س", Colors.orange),
                  _statItem("الأرباح", "${netProfit.toStringAsFixed(1)} ر.س", Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Align(alignment: Alignment.centerRight, child: Text("سجل العمليات:", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: salesHistory.isEmpty
                ? const Center(child: Text("لا توجد مبيعات"))
                : ListView.builder(
                    itemCount: salesHistory.length,
                    itemBuilder: (ctx, i) {
                      final s = salesHistory[i];
                      return ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text(s.productName),
                        trailing: Text("+${s.totalPrice} ر.س"),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _statItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showPurchaseDialog(RawMaterial mat) {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("توريد ${mat.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "الكمية بـ (${mat.unit})")),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "إجمالي الفاتورة (ريال)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              if (qtyCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                _addPurchase(mat, double.parse(qtyCtrl.text), double.parse(costCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  void _showAddNewMaterialDialog() {
    final nameCtrl = TextEditingController();
    String unit = "جرام";
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text("إضافة مادة خام"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم المادة")),
              DropdownButton<String>(
                value: unit,
                isExpanded: true,
                items: ["جرام", "حبة", "مل"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setDState(() => unit = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    materials.add(RawMaterial(id: materials.length + 1, name: nameCtrl.text, unit: unit));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    List<RecipeItem> tempRecipe = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text("إنشاء صنف مجمع"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم الكيكة")),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "سعر البيع")),
                const Divider(),
                const Text("المكونات المضافة:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...tempRecipe.map((r) {
                  final m = materials.firstWhere((item) => item.id == r.materialId);
                  return Text("- ${m.name}: ${r.qtyNeeded} ${m.unit}");
                }),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("إضافة مكون بالجرام/الحبة"),
                  onPressed: () async {
                    int selectedMatId = materials.first.id;
                    final qCtrl = TextEditingController();
                    await showDialog(
                      context: ctx,
                      builder: (c2) => StatefulBuilder(
                        builder: (c2, setSub) => AlertDialog(
                          title: const Text("اختر المكون"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<int>(
                                value: selectedMatId,
                                isExpanded: true,
                                items: materials.map((m) => DropdownMenuItem(value: m.id, child: Text("${m.name} (${m.unit})"))).toList(),
                                onChanged: (v) => setSub(() => selectedMatId = v!),
                              ),
                              TextField(controller: qCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "الكمية المطلوبة")),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                if (qCtrl.text.isNotEmpty) {
                                  setDState(() {
                                    tempRecipe.add(RecipeItem(materialId: selectedMatId, qtyNeeded: double.parse(qCtrl.text)));
                                  });
                                  Navigator.pop(c2);
                                }
                              },
                              child: const Text("إضافة"),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty && tempRecipe.isNotEmpty) {
                  setState(() {
                    products.add(Product(
                      id: products.length + 1,
                      name: nameCtrl.text,
                      salePrice: double.parse(priceCtrl.text),
                      recipe: tempRecipe,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("حفظ الكيكة"),
            )
          ],
        ),
      ),
    );
  }
}

class _TaskHomePageState extends State<TaskHomePage>
    with SingleTickerProviderStateMixin {
  static const String _storageKey = 'klencod_tasks_v1';

  final List<Task> _tasks = [];
  final TextEditingController _searchController = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';
  bool _loading = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        _tasks.clear();
        _tasks.addAll(list.map((e) => Task.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    setState(() => _loading = false);
    _fadeController.forward();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }

  void _addTask(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _tasks.insert(
        0,
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: trimmed,
          createdAt: DateTime.now(),
        ),
      );
    });
    _saveTasks();
    HapticFeedback.lightImpact();
    _showSnack('تمت إضافة المهمة', success: true);
  }

  void _toggleTask(Task task) {
    setState(() => task.done = !task.done);
    _saveTasks();
    HapticFeedback.selectionClick();
  }

  void _deleteTask(Task task) {
    final index = _tasks.indexOf(task);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _saveTasks();
    _showSnack(
      'تم حذف المهمة',
      actionLabel: 'تراجع',
      onAction: () {
        setState(() => _tasks.insert(index, task));
        _saveTasks();
      },
    );
  }

  void _clearCompleted() {
    final completed = _tasks.where((t) => t.done).toList();
    if (completed.isEmpty) {
      _showSnack('لا توجد مهام مكتملة');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _buildConfirmDialog(
        ctx,
        title: 'حذف المهام المكتملة',
        message: 'سيتم حذف ${completed.length} مهمة مكتملة. لا يمكن التراجع.',
        onConfirm: () {
          setState(() => _tasks.removeWhere((t) => t.done));
          _saveTasks();
          Navigator.pop(ctx);
          _showSnack('تم حذف ${completed.length} مهمة', success: true);
        },
      ),
    );
  }

  void _showSnack(String message,
      {String? actionLabel, VoidCallback? onAction, bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: success ? AppTheme.success : AppTheme.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppTheme.primaryLight,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  Widget _buildConfirmDialog(
    BuildContext ctx, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      content: Text(message, style: const TextStyle(color: AppTheme.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('تأكيد',
              style: TextStyle(
                  color: AppTheme.danger, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _openAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.add_task_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 10),
            Text('مهمة جديدة',
                style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            _addTask(v);
            Navigator.pop(ctx);
          },
          decoration: const InputDecoration(
            hintText: 'اكتب المهمة...',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              _addTask(controller.text);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  List<Task> get _visibleTasks {
    Iterable<Task> result = _tasks;
    if (_filter == TaskFilter.active) {
      result = result.where((t) => !t.done);
    } else if (_filter == TaskFilter.completed) {
      result = result.where((t) => t.done);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
      );
    }

    final visible = _visibleTasks;
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.done).length;
    final active = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASKAR'),
        actions: [
          if (completed > 0)
            IconButton(
              tooltip: 'حذف المكتملة',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearCompleted,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('مهمة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildHeader(total, completed, active, progress),
          _buildSearchBar(),
          _buildFilters(total, active, completed),
          Expanded(
            child: visible.isEmpty
                ? _buildEmptyState()
                : _buildTaskList(visible),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int total, int completed, int active, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F6FEB), Color(0xFF0D419D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  total == 0 ? 'لا توجد مهام بعد' : 'مهامك',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statChip('الإجمالي', total, Colors.white),
                _statChip('نشطة', active, AppTheme.warning),
                _statChip('مكتملة', completed, AppTheme.success),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% إنجاز',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'بحث في المهام...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters(int total, int active, int completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _filterChip('الكل', TaskFilter.all, total),
          const SizedBox(width: 8),
          _filterChip('نشطة', TaskFilter.active, active),
          const SizedBox(width: 8),
          _filterChip('مكتملة', TaskFilter.completed, completed),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TaskFilter filter, int count) {
    final selected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> visible) {
    return FadeTransition(
      opacity: _fadeController,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final task = visible[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        _deleteTask(task);
        return false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.done
                ? AppTheme.success.withOpacity(0.4)
                : AppTheme.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggleTask(task),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: task.done
                          ? AppTheme.success
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.done
                            ? AppTheme.success
                            : AppTheme.textMuted,
                        width: 2,
                      ),
                    ),
                    child: task.done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: task.done
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 15,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(task.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.textMuted),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} يوم';
  }

  Widget _buildEmptyState() {
    final String message;
    final IconData icon;
    if (_searchQuery.isNotEmpty) {
      message = 'لا توجد نتائج للبحث';
      icon = Icons.search_off_rounded;
    } else if (_filter == TaskFilter.completed) {
      message = 'لا توجد مهام مكتملة بعد';
      icon = Icons.check_circle_outline_rounded;
    } else if (_filter == TaskFilter.active) {
      message = 'كل المهام مكتملة!';
      icon = Icons.celebration_rounded;
    } else {
      message = 'ابدأ بإضافة مهمتك الأولى';
      icon = Icons.playlist_add_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 56, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'استخدم الزر أدناه للبدء',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}