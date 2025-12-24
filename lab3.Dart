// 1) Class แม่
class Product {
  final String _id; // Private property
  String name;
  double price;
  int? stock;

  // Constructor ด้วย named parameters และ required
  Product({
    required String id,
    required this.name,
    required this.price,
    this.stock,
  }) : _id = id;

  // Getter สำหรับอ่านค่า _id
  String get id => _id;

  // Setter สำหรับตรวจสอบราคา
  set updatePrice(double newPrice) {
    if (newPrice > 0) {
      price = newPrice;
    } else {
      print("⚠️ ราคาไม่ถูกต้อง (ต้อง > 0) -> ไม่เปลี่ยนค่า");
    }
  }

  // Method ลดราคา
  void applyDiscount(double percent) {
    if (percent >= 0 && percent <= 100) {
      price -= (price * percent / 100);
    } else {
      print("⚠️ เปอร์เซ็นต์ส่วนลดต้องอยู่ระหว่าง 0-100");
    }
  }

  // Method เพิ่มสต็อก
  void restock(int amount) {
    stock = (stock ?? 0) + amount;
  }

  // Method แสดงข้อมูล
  void showInfo() {
    print("----------------");
    print("ID: $_id");
    print("Name: $name");
    print("Price: ${price.toStringAsFixed(2)}");
    print("Stock: ${stock ?? 'ยังไม่ระบุสต็อก'}");
  }
}

// 2) Class ลูก
class DigitalProduct extends Product {
  double screenSize; // Changed from Screen_size to screenSize

  DigitalProduct({
    required String id,
    required String name,
    required double price,
    int? stock,
    required this.screenSize, // Changed from Screen_size to screenSize
  }) : super(id: id, name: name, price: price, stock: stock);

  @override
  void showInfo() {
    super.showInfo();
    print("Type: สินค้าแบบดิจิทัล");
    print("Screen size: $screenSize"); // Changed from Screen_size to screenSize
  }
}

// 3) Class ลูก
// Renamed IT_equipment to ItEquipment to follow UpperCamelCase convention.
class ItEquipment extends Product {
  String expireDate;

  ItEquipment({
    required String id,
    required String name,
    required double price,
    int? stock,
    required this.expireDate,
  }) : super(id: id, name: name, price: price, stock: stock);

  @override
  void showInfo() {
    super.showInfo();
    print("Type: สินค้าแบบดิจิทัล");
    print("Expire Date: $expireDate");
  }
}

// 4) Class ลูก
class ElectronicProduct extends Product {
  String brand;

  ElectronicProduct({
    required String id,
    required String name,
    required double price,
    int? stock,
    required this.brand,
  }) : super(id: id, name: name, price: price, stock: stock);

  @override
  void showInfo() {
    super.showInfo();
    print("Type: สินค้าอิเล็กทรอนิกส์");
    print("Brand: $brand");
  }
}

// 5) Main Function & Polymorphism
void main() {
  // สร้างสินค้าแต่ละประเภท
  Product p1 = Product(id: "P001", name: "laptop", price: 50, stock: 0);
  DigitalProduct d1 = DigitalProduct(
    id: "P002",
    name: "monitor",
    price: 199,
    screenSize: 30.0,
  );
  // Changed IT_equipment to ItEquipment
  ItEquipment f1 = ItEquipment(
    id: "P003",
    name: "keyboard",
    price: 25,
    stock: 15,
    expireDate: "2026-01-10",
  );
  ElectronicProduct e1 = ElectronicProduct(
    id: "E001",
    name: "Smartwatch",
    price: 300,
    stock: 10,
    brand: "TechCo",
  );

  print("New Product created: ${p1.name}");
  print("New Product created: ${d1.name}");
  print("New Product created: ${f1.name}");
  print("New Product created: ${e1.name}");

  // ทดสอบระบบป้องกันราคาติดลบ (Setter)
  p1.updatePrice = -100;

  // ทดสอบการลดราคาและเพิ่มสต็อก
  p1.applyDiscount(10); // ลด 10% จาก 50 เหลือ 45
  p1.restock(50);

  // เก็บสินค้าลง List เพื่อทำ Polymorphism
  List<Product> inventory = [p1, d1, f1, e1]; // เพิ่ม e1 เข้าไปใน inventory

  // วนลูปเรียก showInfo()
  for (var item in inventory) {
    item.showInfo();
  }
}
