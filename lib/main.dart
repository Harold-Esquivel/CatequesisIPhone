import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutExpo,
      ),
    );

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
        MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        ),
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
                      Image.asset(
                        "assets/images/logo.png",
                        width: 140,
                      ),

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
      ),
      home: const SplashScreen(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 360,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/fondo.jpeg"),
                  fit: BoxFit.cover,
                  opacity: 0.25,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width - 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "ESCJ - Catequesis",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2A44),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Icon(
                      Icons.church,
                      color: Color(0xFF1E2A44),
                      size: 40,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '"Donde dos o tres están reunidos en\nmi nombre, allí estoy yo en medio de\nellos."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF28344A),
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "MATEO 18:20",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // CONTENIDO
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      fontSize: 38,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A44),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Por favor, seleccione su rol para continuar su jornada.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CATEQUISTA
                  RoleCard(
                    title: "Catequista",
                    subtitle: "Gestionar grupos y lecciones",
                    icon: Icons.menu_book_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginPage(selectedRole: "Catequista"),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // SUPERIOR
                  RoleCard(
                    title: "Superior",
                    subtitle: "Administración parroquial",
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginPage(selectedRole: "Superior"),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  const Center(
                    child: Text(
                      "ESCJ - Catequesis",
                      style: TextStyle(
                        color: Colors.grey,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFDDE6FF),
              child: Icon(
                icon,
                color: const Color(0xFF1E2A44),
                size: 30,
              ),
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String selectedRole;

  const LoginPage({
    super.key,
    required this.selectedRole,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> login() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final username = _emailController.text.trim().toLowerCase();
      var email = "";

      if (widget.selectedRole == "Catequista") {
        email = "$username@catequista.com";
      } else if (widget.selectedRole == "Superior") {
        email = "$username@superior.com";
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: Text("Bienvenido ${widget.selectedRole}"),
        ),
      );
    } on FirebaseAuthException {
      showError("Error al iniciar sesion");
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
            child: Image.asset(
              "assets/images/fondo.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.14),
            ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
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
                          widget.selectedRole == "Catequista"
                              ? Icons.menu_book_rounded
                              : Icons.admin_panel_settings,
                          size: 76,
                          color: const Color(0xFF1E2A44),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Bienvenido ${widget.selectedRole}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A44),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            labelText: "Nombre de usuario",
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
                            onPressed: login,
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
                        )
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