import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      theme: ThemeData(
        primaryColor: Color(0xFF6200EE),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6200EE),
          secondary: Color(0xFF03DAC6),
          background: Color(0xFFF5F5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFF6200EE)),
          titleTextStyle: TextStyle(color: Color(0xFF6200EE), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6200EE)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6200EE),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF6200EE),
            side: BorderSide(color: Color(0xFF6200EE)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: Color(0xFFBB86FC),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFFBB86FC)),
          titleTextStyle: TextStyle(color: Color(0xFFBB86FC), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFBB86FC),
            foregroundColor: Colors.black,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFFBB86FC),
            side: BorderSide(color: Color(0xFFBB86FC)),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: BMICalculator(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class BMICalculator extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const BMICalculator({Key? key, required this.onToggleTheme, required this.themeMode}) : super(key: key);

  @override
  BMICalculatorState createState() => BMICalculatorState();
}

class BMICalculatorState extends State<BMICalculator> {
  final DBHelper _dbHelper = DBHelper();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double? _bmi;
  String? _error;

  void _calculateBMI() async {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      setState(() {
        _error = 'Please enter valid height and weight';
      });
      return;
    }

    // Assume height entered is in centimeters, so convert to meters.
    final double heightInMeters = height >= 3 ? height / 100 : height;

    setState(() {
      _error = null;
      _bmi = weight / (heightInMeters * heightInMeters);  // Adjust for height in meters
    });

    await _dbHelper.insertBMI(heightInMeters, weight, _bmi!);
    
    if (mounted) {
      _showBMIResultDialog();
    }
  }

  void _showBMIResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildBMIResultDialog(),
    );
  }

  Widget _buildBMIResultDialog() {
    final category = _getBMICategory(_bmi!);
    final color = _getBMICategoryColor(_bmi!);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Your BMI Result',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _bmi!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getBMIDescription(category),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBMIDescription(String category) {
    switch (category) {
      case 'Underweight':
        return 'You may need to gain some weight. Consult with a healthcare professional for advice.';
      case 'Normal':
        return 'You have a healthy weight. Keep up the good work!';
      case 'Overweight':
        return 'You may need to lose some weight. Consider a balanced diet and regular exercise.';
      case 'Obese':
        return 'It\'s important to take steps to improve your health. Consult with a healthcare professional for guidance.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calculate Your BMI',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInputField(
              controller: _heightController,
              label: 'Height (m)',
              icon: Icons.height,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _weightController,
              label: 'Weight (kg)',
              icon: Icons.fitness_center,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: const Text('Calculate BMI'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BMIHistory(),
                  ),
                );
              },
              child: const Text('View BMI History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class BMIHistory extends StatefulWidget {
  const BMIHistory({Key? key}) : super(key: key);

  @override
  BMIHistoryState createState() => BMIHistoryState();
}

class BMIHistoryState extends State<BMIHistory> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>>? _bmiRecords;

  @override
  void initState() {
    super.initState();
    _loadBMIHistory();
  }

  void _loadBMIHistory() async {
    final records = await _dbHelper.getBMIRecords();
    setState(() {
      _bmiRecords = records.reversed.toList();  // Reverse the records list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
      ),
      body: _bmiRecords == null
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _bmiRecords!.isEmpty
              ? Center(
                  child: Text(
                    'No BMI records found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _bmiRecords!.length,
                  itemBuilder: (context, index) {
                    final record = _bmiRecords![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'BMI: ${record['bmi'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        subtitle: Text(
                          'Height: ${record['height']} m, Weight: ${record['weight']} kg',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
