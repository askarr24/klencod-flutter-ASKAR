import 'package:flutter/material.dart';

void main() {
  runApp(const BakeryApp());
}

// نموذج المادة الخام (دقيق، شوكولاتة، بيض...)
class RawMaterial {
  final int id;
  String name;
  String unit; // "جرام" أو "حبة"
  double stockQty;
  double costPerUnit; // تكلفة الجرام أو الحبة

  RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    this.stockQty = 0,
    this.costPerUnit = 0,
  });
}

// مكون داخل الوصفة
class RecipeItem {
  final int materialId;
  final double qtyNeeded;

  RecipeItem({required this.materialId, required this.qtyNeeded});
}

// المنتج المجمع (الكيكة)
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

// سجل عملية البيع
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
      title: 'نظام إدارة الحلويات',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D4C41)),
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

  // 1. المخزون والمواد الخام الابتدائية
  List<RawMaterial> materials = [
    RawMaterial(id: 1, name: "دقيق فاخر", unit: "جرام", stockQty: 5000, costPerUnit: 0.004), // 4 ريال للكيلو
    RawMaterial(id: 2, name: "شوكولاتة داكنة", unit: "جرام", stockQty: 1000, costPerUnit: 0.05), // 50 ريال للكيلو
    RawMaterial(id: 3, name: "شوكولاتة بيضاء", unit: "جرام", stockQty: 1000, costPerUnit: 0.045), // 45 ريال للكيلو
    RawMaterial(id: 4, name: "بيض", unit: "حبة", stockQty: 30, costPerUnit: 0.6),
  ];

  // 2. الأصناف المجمعة (الكيكات)
  List<Product> products = [];

  // 3. سجل المبيعات
  List<SaleRecord> salesHistory = [];

  @override
  void initState() {
    super.initState();
    // إضافة كيكة الشوكولاتة الافتراضية بمكوناتها بالجرام والحبة
    products.add(
      Product(
        id: 1,
        name: "كيكة الشوكولاتة وسط",
        salePrice: 60.0,
        recipe: [
          RecipeItem(materialId: 1, qtyNeeded: 200), // 200 جرام دقيق
          RecipeItem(materialId: 2, qtyNeeded: 10),  // 10 جرام شوكولاتة داكنة
          RecipeItem(materialId: 3, qtyNeeded: 10),  // 10 جرام شوكولاتة بيضاء
          RecipeItem(materialId: 4, qtyNeeded: 2),   // 2 حبة بيض
        ],
      ),
    );
  }

  // دالة بيع صنف مجمع وخصم المكونات آلياً
  void _sellProduct(Product product) {
    // 1. فحص كفاية المخزون بالجرام والحبة
    for (var item in product.recipe) {
      final mat = materials.firstWhere((m) => m.id == item.materialId);
      if (mat.stockQty < item.qtyNeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("عذراً، المخزون غير كافٍ من: ${mat.name} (المتوفر: ${mat.stockQty} ${mat.unit})"),
          ),
        );
        return;
      }
    }

    // 2. خصم الكميات وحساب التكلفة الفعلية
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
        content: Text("تم البيع بنجاح! تم خصم المكونات بالجرام. الربح: ${(product.salePrice - cakeCost).toStringAsFixed(2)} ر.س"),
      ),
    );
  }

  // تسجيل مشتريات (زيادة رصيد المواد الخام)
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
        backgroundColor: Colors.brown,
        content: Text("تمت إضافة $addedQty ${mat.unit} إلى رصيد ${mat.name}"),
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

  // 1. شاشة الكاشير والمبيعات
  Widget _buildSalesScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("اختر الصنف لإتمام عملية البيع وخصم المكونات فوراً:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD7CCC8),
                      child: Icon(Icons.cake, color: Color(0xFF5D4037)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("السعر: ${p.salePrice} ر.س | مكونات: ${p.recipe.length} عناصر"),
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

  // 2. شاشة المشتريات والمخزون
  Widget _buildInventoryScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("رصيد المواد الخام بالجرام والحبة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    subtitle: Text("الرصيد المتوفر: ${m.stockQty.toStringAsFixed(1)} ${m.unit}\nتكلفة الـ ${m.unit}: ${(m.costPerUnit).toStringAsFixed(4)} ر.س"),
                    trailing: ElevatedButton(
                      child: const Text("+ توريد / شراء"),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("الأصناف المصنعة وشجرة المكونات:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("صنف مجمع جديد"),
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

  // 4. شاشة التقارير والأرباح
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
                  _statItem("إجمالي المبيعات", "${totalSales.toStringAsFixed(1)} ر.س", Colors.blue),
                  _statItem("تكلفة المكونات", "${totalCost.toStringAsFixed(1)} ر.س", Colors.orange),
                  _statItem("صافي الأرباح", "${netProfit.toStringAsFixed(1)} ر.س", Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("سجل الفواتير السابقة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: salesHistory.isEmpty
                ? const Center(child: Text("لا توجد مبيعات بعد"))
                : ListView.builder(
                    itemCount: salesHistory.length,
                    itemBuilder: (ctx, i) {
                      final s = salesHistory[i];
                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(s.productName),
                        subtitle: Text("الوقت: ${s.date.hour}:${s.date.minute}"),
                        trailing: Text("+${s.totalPrice} ر.س\n(ربح: ${(s.totalPrice - s.totalCost).toStringAsFixed(1)})", textAlign: TextAlign.left),
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
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // نوافذ الحوار لإدخال البيانات:
  void _showPurchaseDialog(RawMaterial mat) {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("شراء / توريد ${mat.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "الكمية المشتراة بـ (${mat.unit})")),
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
            child: const Text("تأكيد الإضافة"),
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
          title: const Text("إضافة مادة خام جديدة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم المادة (مثال: سكر ناعم)")),
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
              child: const Text("إضافة"),
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
          title: const Text("إنشاء صنف مجمع (كيكة)"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم الكيكة / الصنف")),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "سعر البيع للزبون (ريال)")),
                const Divider(),
                const Text("المكونات المضافة للوصفة:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          title: const Text("اختر المكون والكمية"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<int>(
                                value: selectedMatId,
                                isExpanded: true,
                                items: materials.map((m) => DropdownMenuItem(value: m.id, child: Text("${m.name} (${m.unit})"))).toList(),
                                onChanged: (v) => setSub(() => selectedMatId = v!),
                              ),
                              TextField(controller: qCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "الكمية المطلوبة للقطعة")),
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
                              child: const Text("حفظ المكون"),
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
              child: const Text("حفظ الكيكة في القائمة"),
            )
          ],
        ),
      ),
    );
  }
}