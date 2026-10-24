import 'dart:async';
import 'firebase_options.dart';
import 'home_screen_superior.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen_catequista.dart'; // Ajusta la ruta según tu estructura

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  Timer? _textTimer;
  Timer? _navigationTimer;

  int currentText = 0;

  final List<String> textos = [
    "Preparando tu experiencia espiritual...",
    "Conectando con la comunidad...",
    "Cargando módulos de catequesis...",
    "Bienvenido a Esclavas del Sagrado Corazón de Jesús",
  ];

  @override
  void initState() {
    super.initState();

    // Animación del logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoAnimation = Tween<double>(
      begin: 120,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));

    _controller.forward();

    // Cambiar textos cada cierto tiempo
    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;
      if (currentText < textos.length - 1) {
        setState(() {
          currentText++;
        });
      }
    });

    // Espera 5 segundos y manda al login
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget jumpingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 12),
          duration: Duration(milliseconds: 500 + (index * 200)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -value),
                child: child,
              ),
            );
          },
          onEnd: () {
            setState(() {});
          },
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF1E2A44),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO ANIMADO
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _logoAnimation.value),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Image.asset("assets/images/logo.png", width: 140),

                      const SizedBox(height: 25),

                      const Text(
                        "Bienvenido",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A44),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // PUNTITOS
                jumpingDots(),

                const SizedBox(height: 35),

                // TEXTOS CAMBIANTES
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    textos[currentText],
                    key: ValueKey(currentText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Esclavas del Sagrado Corazón de Jesús Catequesis',
      theme: ThemeData(
        fontFamily: 'Georgia',
        scaffoldBackgroundColor: const Color(0xFFF5F3F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB83357),
          primary: const Color(0xFF1E2A44),
          secondary: const Color(0xFFB83357),
          surface: const Color(0xFFF5F3F2),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF5F3F2),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFFF5F3F2),
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFFF5F3F2),
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFF5F3F2),
          surfaceTintColor: Colors.transparent,
        ),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Color(0xFFF5F3F2),
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: Color(0xFF1E2A44),
          headerForegroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E2A44),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB83357),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E2A44),
            side: const BorderSide(color: Color(0xFFB83357)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB83357), width: 1.4),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home-catequista': (context) => const HomeCatequistaScreen(),
        '/home-superior': (context) => const HomeSuperiorScreen(),
      },
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E1DE)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.church,
                            color: Color(0xFFB83357),
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "ESCJ - Catequesis",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A44),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Seleccione su rol para iniciar sesion.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E2A44),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    RoleCard(
                      title: "Catequista",
                      subtitle: "Gestionar grupos y lecciones",
                      icon: Icons.menu_book_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    RoleCard(
                      title: "Superior",
                      subtitle: "Administracion parroquial",
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        "ESCJ - Catequesis",
                        style: TextStyle(
                          color: Colors.grey,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3F2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFE5E1DE),
              child: Icon(icon, color: const Color(0xFF1E2A44), size: 30),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A44),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoggingIn = false;

  Future<void> login() async {
    final userInput = _emailController.text.trim().toLowerCase();
    if (userInput.isEmpty || _passwordController.text.isEmpty) {
      showError('Ingresa tu usuario o correo y tu contrasena');
      return;
    }

    try {
      setState(() {
        _errorMessage = null;
        _isLoggingIn = true;
      });

      final emails = userInput.contains('@')
          ? <String>[userInput]
          : <String>['$userInput@catequista.com', '$userInput@superior.com'];
      UserCredential? credential;

      for (final email in emails) {
        try {
          credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );
          break;
        } on FirebaseAuthException {
          // Se revisan ambos correos autorizados antes de mostrar error.
        }
      }

      if (credential == null) {
        showError('Usuario, correo o contrasena incorrectos');
        return;
      }

      if (!mounted) return;

      final email = credential.user?.email?.toLowerCase() ?? '';
      if (email.endsWith('@catequista.com')) {
        Navigator.pushReplacementNamed(context, '/home-catequista');
      } else if (email.endsWith('@superior.com')) {
        // Aquí puedes agregar el home para Superior
        Navigator.pushReplacementNamed(context, '/home-superior');
      } else {
        await FirebaseAuth.instance.signOut();
        showError('Este correo no tiene un rol autorizado');
      }
    } on FirebaseAuthException {
      showError("Error al iniciar sesion");
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  void showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/fondo.jpeg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.14)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: const Color(0xFF1E2A44),
                            tooltip: "Volver",
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.church,
                          size: 76,
                          color: const Color(0xFF1E2A44),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Inicie sesion",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                  color: Colors.white,
                                  tooltip: "Cerrar",
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        TextField(
                          controller: _emailController,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            labelText: "Usuario o correo",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Contrasena",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2A44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "Ingresar",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
