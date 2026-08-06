import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const BarkodApp());
}

class BarkodApp extends StatelessWidget {
  const BarkodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Besin Analiz Sistemi',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}

// --- ANA EKRAN (Alt Menü: Tarayıcı ve Favoriler) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> favoriteItems = []; // Favori ürünler listesi

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ScannerScreen(onFavoriteAdded: (item) {
        setState(() {
          if (!favoriteItems.any((element) => element['code'] == item['code'])) {
            favoriteItems.add(item);
          }
        });
      }),
      FavoritesScreen(favorites: favoriteItems),
      const PremiumScreen(), // Uygulama İçi Satın Alma Ekranı
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Tara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star, color: Colors.amber),
            label: 'Pro Sürüm',
          ),
        ],
      ),
    );
  }
}

// --- 1. TARAMA EKRANI ---
class ScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onFavoriteAdded;

  const ScannerScreen({super.key, required this.onFavoriteAdded});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Besin Karekod Okuyucu'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _isScanned = true;
              String codeContent = barcode.rawValue!;
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    scannedData: codeContent,
                    onFavoriteAdded: widget.onFavoriteAdded,
                  ),
                ),
              ).then((_) {
                setState(() {
                  _isScanned = false;
                });
              });
              break;
            }
          }
        },
      ),
    );
  }
}

// --- 2. SONUÇ EKRANI ---
class ResultScreen extends StatefulWidget {
  final String scannedData;
  final Function(Map<String, dynamic>) onFavoriteAdded;

  const ResultScreen({super.key, required this.scannedData, required this.onFavoriteAdded});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int healthScore;
  late Color screenColor;
  late String statusTitle;
  late String statusMessage;
  late IconData statusIcon;
  late String productName;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() {
    final Map<String, Map<String, dynamic>> mockDatabase = {
      "apple": {"name": "Taze Elma", "score": 95, "msg": "Doğal vitamin ve lif deposu."},
      "bread": {"name": "Beyaz Unlu Tost Ekmeği", "score": 60, "msg": "İşlenmiş karbonhidrat oranı yüksek."},
      "cola": {"name": "Gazlı Kola", "score": 15, "msg": "Yüksek mısır şurubu ve kimyasal barındırır."},
    };

    if (mockDatabase.containsKey(widget.scannedData)) {
      var item = mockDatabase[widget.scannedData]!;
      productName = item["name"];
      healthScore = item["score"];
      statusMessage = "${item["msg"]} (%$healthScore)";
    } else {
      productName = "Ürün (${widget.scannedData})";
      healthScore = 50;
      statusMessage = "Sınırda değerlere sahip ürün. (%$healthScore)";
    }

    if (healthScore > 70) {
      screenColor = Colors.green.shade600;
      statusTitle = "Tüketim İçin Uygun";
      statusIcon = Icons.check_circle_outline;
    } else if (healthScore >= 40) {
      screenColor = Colors.orange.shade600;
      statusTitle = "Dikkatli Tüketin";
      statusIcon = Icons.warning_amber_rounded;
    } else {
      screenColor = Colors.red.shade600;
      statusTitle = "Tüketim Önerilmez";
      statusIcon = Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenColor,
      appBar: AppBar(
        title: const Text('Analiz Sonucu'),
        backgroundColor: Colors.black26,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              widget.onFavoriteAdded({
                'code': widget.scannedData,
                'name': productName,
                'score': healthScore,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorilere eklendi!')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: Colors.white, size: 90),
            const SizedBox(height: 15),
            Text(statusTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text(productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  Text("Sağlık Skoru", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 5),
                  Text("%$healthScore", style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: screenColor)),
                  const SizedBox(height: 15),
                  Text(statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: screenColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Yeni Besin Okut", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 3. FAVORİLER EKRANI ---
class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favori Ürünlerim'), backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
      body: favorites.isEmpty
          ? const Center(child: Text('Henüz favoriye eklenen ürün yok.', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                var item = favorites[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item['score'] > 70 ? Colors.green : (item['score'] >= 40 ? Colors.orange : Colors.red),
                      child: Text("%${item['score']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Kod: ${item['code']}"),
                  ),
                );
              },
            ),
    );
  }
}

// --- 4. UYGULAMA İÇİ SATIN ALMA (PRO SÜRÜM) EKRANI ---
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro Sürüm'), backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            const Text("Pro Sürüme Geçin", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Sınırsız tarama, detaylı katkı maddesi analizi ve reklamsız deneyim için Pro pakete sahip olun.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Burada Google Play Billing (Uygulama İçi Satın Alma) tetiklenecek
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Play İçi Satın Alma ekranı açılıyor...')),
                );
              },
              child: const Text("Hemen Yükselt - 49.99 TL / Ay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
