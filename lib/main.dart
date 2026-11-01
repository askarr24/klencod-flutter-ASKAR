import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BakeryApp());
}

// ------------------- النماذج (Models) -------------------

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'unit': unit,
    'stockQty': stockQty,
    'costPerUnit': costPerUnit,
  };

  factory RawMaterial.fromMap(Map<String, dynamic> map) => RawMaterial(
    id: map['id'],
    name: map['name'],
    unit: map['unit'],
    stockQty: (map['stockQty'] as num).toDouble(),
    costPerUnit: (map['costPerUnit'] as num).toDouble(),
  );
}

class RecipeItem {
  final int materialId;
  final double qtyNeeded;

  RecipeItem({required this.materialId, required this.qtyNeeded});

  Map<String, dynamic> toMap() => {
    'materialId': materialId,
    'qtyNeeded': qtyNeeded,
  };

  factory RecipeItem.fromMap(Map<String, dynamic> map) => RecipeItem(
    materialId: map['materialId'],
    qtyNeeded: (map['qtyNeeded'] as num).toDouble(),
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'salePrice': salePrice,
    'recipe': recipe.map((r) => r.toMap()).toList(),
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    name: map['name'],
    salePrice: (map['salePrice'] as num).toDouble(),
    recipe: (map['recipe'] as List).map((r) => RecipeItem.fromMap(r)).toList(),
  );
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

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'qty': qty,
    'totalPrice': totalPrice,
    'totalCost': totalCost,
    'date': date.toIso8601String(),
  };

  factory SaleRecord.fromMap(Map<String, dynamic> map) => SaleRecord(
    productName: map['productName'],
    qty: map['qty'],
    totalPrice: (map['totalPrice'] as num).toDouble(),
    totalCost: (map['totalCost'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

// ------------------- التطبيق الأساسي -------------------

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام إدارة الحلويات',
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
  bool _isLoading = true;

  List<RawMaterial> materials = [];
  List<Product> products = [];
  List<SaleRecord> salesHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // تحميل البيانات المحفوظة في ذاكرة الهاتف
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    final matString = prefs.getString('raw_materials');
    if (matString != null) {
      final List decoded = jsonDecode(matString);
      materials = decoded.map((m) => RawMaterial.fromMap(m)).toList();
    } else {
      // بيانات افتراضية لأول مرة
      materials = [
        RawMaterial(id: 1, name: "دقيق فاخر", unit: "جرام", stockQty: 5000, costPerUnit: 0.004),
        RawMaterial(id: 2, name: "شوكولاتة داكنة", unit: "جرام", stockQty: 1000, costPerUnit: 0.05),
        RawMaterial(id: 3, name: "شوكولاتة بيضاء", unit: "جرام", stockQty: 1000, costPerUnit: 0.045),
        RawMaterial(id: 4, name: "بيض", unit: "حبة", stockQty: 30, costPerUnit: 0.6),
      ];
    }

    final prodString = prefs.getString('products');
    if (prodString != null) {
      final List decoded = jsonDecode(prodString);
      products = decoded.map((p) => Product.fromMap(p)).toList();
    } else {
      // كيكة افتراضية بالمكونات بالجرام
      products = [
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
        )
      ];
    }

    final salesString = prefs.getString('sales_history');
    if (salesString != null) {
      final List decoded = jsonDecode(salesString);
      salesHistory = decoded.map((s) => SaleRecord.fromMap(s)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // حفظ التعديلات في ذاكرة الهاتف فوراً
  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('raw_materials', jsonEncode(materials.map((m) => m.toMap()).toList()));
    await prefs.setString('products', jsonEncode(products.map((p) => p.toMap()).toList()));
    await prefs.setString('sales_history', jsonEncode(salesHistory.map((s) => s.toMap()).toList()));
  }

  // عملية البيع وخصم المكونات بالجرام
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

    _saveAllData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("تم البيع بنجاح! خصم المكونات تم آلياً. صافي الربح: ${(product.salePrice - cakeCost).toStringAsFixed(2)} ر.س"),
      ),
    );
  }

  // توريد ومشتريات
  void _addPurchase(RawMaterial mat, double addedQty, double totalPrice) {
    setState(() {
      double totalOldValue = mat.stockQty * mat.costPerUnit;
      double newTotalQty = mat.stockQty + addedQty;
      double newCostPerUnit = (totalOldValue + totalPrice) / newTotalQty;

      mat.stockQty = newTotalQty;
      mat.costPerUnit = newCostPerUnit;
    });

    _saveAllData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF5D4037),
        content: Text("تمت إضافة $addedQty ${mat.unit} إلى ${mat.name}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

  // 1. شاشة الكاشير
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

  // 2. شاشة المشتريات والمخزن
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

  // 3. شاشة الأصناف المجمعة (الوصفات)
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

  // 4. شاشة التقارير
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

  // حوارات الإدخال
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
                  _saveAllData();
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
                  _saveAllData();
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