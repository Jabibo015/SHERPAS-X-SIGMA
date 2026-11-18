import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SigmaDzyApp());
}

class SigmaDzyApp extends StatelessWidget {
  const SigmaDzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigma DZY Financial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          secondary: const Color(0xFFEA580C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: 'Roboto',
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sigma DZY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          actions: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaPerfil(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&fit=crop',
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFFEA580C),
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.insert_chart), text: 'Diagnostico'),
              Tab(icon: Icon(Icons.rule), text: 'Plan de Accion'),
              Tab(icon: Icon(Icons.support_agent), text: 'Asesor IA'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabResumenInteractivo(),
            TabObjetivosInteractivos(),
            TabChatbot(),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// PANTALLA DE PERFIL INTERACTIVA
// =========================================================================
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  String nombre = 'Timothy Perez';
  String correo = 'timothy.perez@email.com';
  String telefono = '+34 600 123 456';

  bool suscritoNewsletter = false;
  bool enviandoNewsletter = false;

  Future<void> _suscribirNewsletter() async {
    final emailValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo);
    if (!emailValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un correo válido antes de suscribirte.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => enviandoNewsletter = true);
    try {
      final respuestas = await Future.wait([
        // 1. Correo de bienvenida
        http
            .post(
              Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'service_id': 'service_btyebnu',
                'template_id': 'template_bcbwdqd',
                'user_id': 'WsUOtg9J7nv_ql5Bz',
                'template_params': {'to_email': correo, 'nombre': nombre},
              }),
            )
            .timeout(const Duration(seconds: 15)),
        // 2. Informe mensual
        http
            .post(
              Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'service_id': 'service_btyebnu',
                'template_id': 'template_o1r2uzf',
                'user_id': 'WsUOtg9J7nv_ql5Bz',
                'template_params': {'to_email': correo, 'nombre': nombre},
              }),
            )
            .timeout(const Duration(seconds: 15)),
      ]);

      if (!mounted) return;
      if (respuestas[0].statusCode == 200 && respuestas[1].statusCode == 200) {
        setState(() => suscritoNewsletter = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correos de bienvenida y resumen enviados a $correo'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'Error ${respuestas[0].statusCode} / ${respuestas[1].statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo suscribir. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => enviandoNewsletter = false);
    }
  }

  void _editarDato(
    String titulo,
    String valorActual,
    Function(String) onGuardar,
  ) {
    TextEditingController controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Introduce tu nuevo $titulo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              onGuardar(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoLegal(String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFEA580C)),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            contenido,
            style: const TextStyle(height: 1.5, color: Color(0xFF475569)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&fit=crop',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Abriendo galeria del dispositivo...',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Datos Personales',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          _crearCampoPerfil(Icons.person, 'Nombre completo', nombre, () {
            _editarDato(
              'Nombre',
              nombre,
              (nuevoValor) => setState(() => nombre = nuevoValor),
            );
          }),
          _crearCampoPerfil(Icons.email, 'Correo electronico', correo, () {
            _editarDato(
              'Correo',
              correo,
              (nuevoValor) => setState(() => correo = nuevoValor),
            );
          }),
          _crearCampoPerfil(Icons.phone, 'Telefono', telefono, () {
            _editarDato(
              'Telefono',
              telefono,
              (nuevoValor) => setState(() => telefono = nuevoValor),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Newsletter',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Icon(
                suscritoNewsletter ? Icons.mark_email_read : Icons.mail_outline,
                color: const Color(0xFFEA580C),
              ),
              title: Text(
                suscritoNewsletter
                    ? 'Suscrito a la newsletter'
                    : 'Suscribirme a la newsletter',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                suscritoNewsletter
                    ? 'Recibirás novedades en $correo'
                    : 'Recibe consejos financieros en tu correo.',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: enviandoNewsletter
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (suscritoNewsletter
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right, color: Colors.grey)),
              onTap: (suscritoNewsletter || enviandoNewsletter)
                  ? null
                  : _suscribirNewsletter,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Soporte y Legal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          _crearBotonAccion(
            Icons.help_outline,
            'Ayuda y Contacto',
            'Contacta con el soporte tecnico.',
            () {
              _mostrarInfoLegal(
                'Centro de Soporte',
                'Si necesitas ayuda con tu plan financiero, nuestro equipo de Sherpas esta disponible.\n\n Correo: soporte@sigmadzy.com\n Telefono: +34 900 123 456\n Horario: L-V de 9:00 a 18:00\n\nTambien puedes usar el Asesor IA en la pestana principal para dudas rapidas.',
              );
            },
          ),
          _crearBotonAccion(
            Icons.privacy_tip_outlined,
            'Terminos y Condiciones',
            'Lee nuestras politicas de servicio.',
            () {
              _mostrarInfoLegal(
                'Terminos de Servicio',
                'Ultima actualizacion: Noviembre 2026\n\n1. Introduccion\nBienvenido a Sigma DZY. Al usar nuestra aplicacion, aceptas estar sujeto a estos terminos.\n\n2. Servicios Financieros\nLa informacion proporcionada en esta app es para fines de planificacion y no constituye asesoramiento de inversion vinculante. Las proyecciones son hipoteticas.\n\n3. Responsabilidad\nEl usuario asume el riesgo de cualquier decision financiera tomada basandose en este diagnostico.',
              );
            },
          ),
          _crearBotonAccion(
            Icons.cookie,
            'Politica de Cookies y Datos',
            'Gestiona como tratamos tu informacion.',
            () {
              _mostrarInfoLegal(
                'Privacidad y Datos',
                'Tus datos estan seguros.\n\nEn Sigma DZY utilizamos cifrado de extremo a extremo para proteger tu informacion bancaria y diagnosticos patrimoniales. No vendemos tus datos a terceros.\n\nUsamos cookies tecnicas estrictamente necesarias para mantener tu sesion activa y guardar tus preferencias entre el modo visual y analitico.',
              );
            },
          ),

          const SizedBox(height: 40),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Cerrar Sesion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crearCampoPerfil(
    IconData icono,
    String titulo,
    String valor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icono, color: const Color(0xFF0F172A)),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _crearBotonAccion(
    IconData icono,
    String titulo,
    String subtitulo,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icono, color: const Color(0xFFEA580C)),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class TabResumenInteractivo extends StatefulWidget {
  const TabResumenInteractivo({super.key});

  @override
  State<TabResumenInteractivo> createState() => _TabResumenInteractivoState();
}

class _TabResumenInteractivoState extends State<TabResumenInteractivo> {
  bool esModoAnalitico = false;

  Color _obtenerColorPuntuacion(int puntuacion) {
    if (puntuacion < 50) return Colors.red;
    if (puntuacion <= 75) return const Color(0xFFEA580C);
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    const int miPuntuacion = 60;
    final Color colorScore = _obtenerColorPuntuacion(miPuntuacion);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Tu Puntuacion de Salud Financiera',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$miPuntuacion',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: colorScore,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 4),
                    child: Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Estais logrando salir adelante, pero aun no estais prosperando al maximo. Mejorar vuestra salud financiera y crear un plan estrategico desbloqueara el potencial de vuestro dinero.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => esModoAnalitico = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !esModoAnalitico
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          color: !esModoAnalitico
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informe Visual',
                          style: TextStyle(
                            color: !esModoAnalitico
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => esModoAnalitico = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: esModoAnalitico
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subject,
                          color: esModoAnalitico
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informe Detallado',
                          style: TextStyle(
                            color: esModoAnalitico
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _crearBotonVivaGym(
              context,
              'Hogar e Ingresos',
              Icons.family_restroom,
              'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&fit=crop',
            ),
            _crearBotonVivaGym(
              context,
              'Jubilacion',
              Icons.elderly,
              'https://images.unsplash.com/photo-1473186578172-c141e6798cf4?w=400&fit=crop',
            ),
            _crearBotonVivaGym(
              context,
              'Patrimonio',
              Icons.house,
              'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&fit=crop',
            ),
            _crearBotonVivaGym(
              context,
              'Deudas',
              Icons.credit_score,
              'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=400&fit=crop',
            ),
            _crearBotonVivaGym(
              context,
              'Ahorros y Gastos',
              Icons.savings,
              'https://images.unsplash.com/photo-1579621970588-a35d0e7ab9b6?w=400&fit=crop',
            ),
            // FOTO DE PROTECCIÓN ACTUALIZADA (Enlace de seguridad genérico y ultra estable)
            _crearBotonVivaGym(
              context,
              'Proteccion',
              Icons.shield,
              'https://images.unsplash.com/photo-1614064641936-3bce5c5c0d29?w=400&fit=crop',
            ),
          ],
        ),
      ],
    );
  }

  Widget _crearBotonVivaGym(
    BuildContext context,
    String titulo,
    IconData icono,
    String urlImagen,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaDetalle(
              titulo: titulo,
              icono: icono,
              esModoAnalitico: esModoAnalitico,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: Color(0xFFEA580C), width: 3),
            bottom: BorderSide(color: Color(0xFFEA580C), width: 3),
          ),
          image: DecorationImage(
            image: NetworkImage(urlImagen),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(180),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaDetalle extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final bool esModoAnalitico;

  const PantallaDetalle({
    super.key,
    required this.titulo,
    required this.icono,
    required this.esModoAnalitico,
  });

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  double _touchX = 150.0;

  // Controladores de scroll para la barrita interactiva inferior
  final ScrollController _scrollFlujo = ScrollController();
  final ScrollController _scrollHistograma = ScrollController();

  @override
  void dispose() {
    _scrollFlujo.dispose();
    _scrollHistograma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.titulo, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icono, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.esModoAnalitico
                      ? 'Reporte Textual Completo'
                      : 'Analisis Estructural',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          widget.esModoAnalitico
              ? _construirContenidoAnalitico()
              : _construirContenidoVisual(),
        ],
      ),
    );
  }

  Widget _construirContenidoVisual() {
    if (widget.titulo == 'Deudas') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Distribucion de Pasivos",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Vuestra deuda es manejable en terminos generales: \$93,000 en total. La hipoteca, los prestamos de estudios y los del coche tienen intereses controlados. El punto de maxima tension financiera es la tarjeta de credito Chase.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _cajaRatio('DEBT-TO-INCOME', '13%', Colors.black87),
              const SizedBox(width: 12),
              _cajaRatio('HOUSING RATIO', '11%', Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          _graficoHistograma("Deudas por Tipo y Coste", [
            {
              "label": "Hipoteca (6%)",
              "valor": 50000.0,
              "color": const Color(0xFF0F172A),
            },
            {
              "label": "Tarjeta (18%)",
              "valor": 18000.0,
              "color": const Color(0xFFEA580C),
            },
            {
              "label": "Estudios (5%)",
              "valor": 15000.0,
              "color": const Color(0xFF64748B),
            },
            {
              "label": "Coche (4%)",
              "valor": 10000.0,
              "color": const Color(0xFF94A3B8),
            },
          ], 50000.0),
          const SizedBox(height: 24),
          _cajaGlosario(
            "Estrategia Inmediata",
            "La tarjeta os cuesta unos \$270 al ano solo en intereses puros. Como disponeis de liquidez de sobra en el banco, el movimiento mas logico y rentable es pagarla integramente hoy.",
          ),
        ],
      );
    }

    if (widget.titulo == 'Jubilacion') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Proyeccion de Jubilacion y Activos",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Ambos quereis jubilaros en 2048 (edades 62 y 60). Vuestro plan tiene unos cimientos muy fuertes. Proyectando hacia el futuro, vuestros ingresos cubriran el 93% de las necesidades de gasto, y el dinero no se agotara antes de los 91 anos.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Proyeccion de Patrimonio Neto",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actual:\n\$696K',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Al jubilarse:\n\$2.8M',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Fin del plan:\n\$3.4M',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _touchX = details.localPosition.dx;
                  if (_touchX < 0) _touchX = 0;
                  if (_touchX > 320) _touchX = 320;
                });
              },
              child: CustomPaint(
                painter: GraficoJubilacionPainter(_touchX),
                child: Container(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Desliza el dedo sobre la grafica para ver la proyeccion por edad.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.titulo == 'Proteccion') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Seguros y Fondo de Emergencia",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Con Liam y Josh dependiendo de ambos ingresos, la proteccion es donde vuestra imagen es mas irregular. Vuestro fondo de emergencia es una fortaleza real, pero la cobertura de seguro de vida y responsabilidad civil (Umbrella) esta muy expuesta.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Fondo de Emergencia",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _graficoHaveVsNeed(
            'Recomendado',
            85000,
            'Actual',
            150801,
            Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            "Seguro de Vida (Timothy)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _graficoHaveVsNeed(
            'Recomendado Minimo',
            750000,
            'Cobertura Actual',
            140000,
            Colors.red,
          ),
          const SizedBox(height: 24),
          _cajaGlosario(
            "Poliza Umbrella",
            "Es un seguro de responsabilidad civil adicional que te protege si alguien te demanda por una cantidad que supera el limite de tu seguro de hogar o coche. Actualmente teneis \$0 de cobertura frente a un riesgo de \$1M.",
          ),
        ],
      );
    }

    if (widget.titulo == 'Ahorros y Gastos' ||
        widget.titulo == 'Hogar e Ingresos') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Flujo de Caja del Hogar",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Ingresais \$270,000 en conjunto. Ahorrais \$61,500 al ano (22.8%), lo cual esta perfectamente en ruta. Sin embargo, la educacion universitaria de vuestros hijos esta actualmente sin fondos (\$0 en 529s).",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Esquema de Ingresos y Salidas",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // SISTEMA DE SCROLL CON BARRITA INFERIOR PARA QUE NO SE CORTE
                Scrollbar(
                  controller: _scrollFlujo,
                  thumbVisibility: true,
                  thickness: 6.0,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollFlujo,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              _cajaFlujo(
                                'Timothy',
                                '\$150K',
                                const Color(0xFF3B82F6),
                              ),
                              const SizedBox(height: 8),
                              _cajaFlujo(
                                'Melanie',
                                '\$120K',
                                const Color(0xFF60A5FA),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.grey,
                            ),
                          ),
                          _cajaFlujo(
                            'Ingreso Total',
                            '\$270K',
                            const Color(0xFF0F172A),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.grey,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _cajaFlujoPequena(
                                'Impuestos',
                                '\$73K',
                                Colors.grey,
                              ),
                              _cajaFlujoPequena(
                                'Gastos Vida',
                                '\$72K',
                                Colors.indigo,
                              ),
                              _cajaFlujoPequena(
                                'Ahorros',
                                '\$48K',
                                Colors.blue,
                              ),
                              _cajaFlujoPequena(
                                'Vivienda',
                                '\$29K',
                                Colors.indigoAccent,
                              ),
                              _cajaFlujoPequena('Deudas', '\$12K', Colors.teal),
                              const SizedBox(height: 8),
                              _cajaFlujoPequena(
                                'FLUJO LIBRE',
                                '\$37K',
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _cajaGlosario(
            "Cuenta 529 (Educacion)",
            "Es un plan de ahorro con ventajas fiscales disenado especificamente para fomentar el ahorro para futuros costos de educacion de tus hijos (Liam y Josh). Se necesitan unos \$4,609 anuales para fondearlo.",
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vuestro Patrimonio Total",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Habeis logrado construir un patrimonio total de \$788,500. Sin embargo, hay un detalle importante: gran parte de vuestra riqueza esta invertida en los ladrillos de vuestra casa y en dinero en efectivo parado. Solo una parte pequena esta realmente invertida para generaros ganancias a largo plazo.",
          style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 24),
        _graficoDonut("Distribucion de \$788,500 en Activos", [
          {"label": "Vivienda (44.4%)", "color": const Color(0xFF0F172A)},
          {"label": "Inversiones (26.6%)", "color": const Color(0xFF475569)},
          {"label": "Efectivo (19.0%)", "color": const Color(0xFFEA580C)},
          {"label": "Otros (10.0%)", "color": const Color(0xFFCBD5E1)},
        ]),
      ],
    );
  }

  Widget _construirContenidoAnalitico() {
    if (widget.titulo == 'Deudas') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Debt Management",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Divider(height: 30, thickness: 2),
          Text(
            "• Your debt is manageable overall: \$93,000 in total, with debt payments equal to 13.2% of your \$270,000 income. The one costly exception is the \$18,000 Chase card at 18%, while your mortgage, student loan and vehicle loan carry lower rates of 6%, 5.5% and 4.5%.\n\n"
            "• Counting housing costs too, your obligations take 15.1% of income, well under the 36% level lenders often watch first. Your debt load isn't what limits you right now.\n\n"
            "• The card is paid at \$300 a month, which is close to the \$270 a year of interest it generates. That is a small slice of the payment, but it means the 18% rate is the part of your debt most worth understanding.\n\n"
            "• If the \$300 payment holds, the card is projected to be paid off in September 2039, about 12 years out. That is a projection, and it could shift because your monthly spending may be understated in the data.\n\n"
            "• You hold \$150,800 in accessible cash, above the \$75,180 to \$84,577.50 reserve of 8 to 9 months of essential expenses. About \$60,222.50 sits above the reserve and near-term goals. Weighing that cash against the 18% balance is the main trade-off, and keeping a healthy reserve matters more than the debt ratios.\n\n"
            "We should look into: how the credit card balance compares with the cash held above your reserve, the card's payoff timeline at the current payment, and confirming your monthly spending, since expense figures may be understated.",
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    if (widget.titulo == 'Proteccion') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insurance & Protection",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Divider(height: 30, thickness: 2),
          Text(
            "With Liam and Josh relying on both of your incomes, protection is where your picture is most uneven: your emergency fund is a real strength, giving you a solid cushion if something unexpected happens. Life insurance and umbrella coverage are where your household is more exposed, and the sections below explain each of these three areas in plain terms.\n\n"
            "Emergency fund\n"
            "• Your \$150,801 in accessible cash covers about 16 months of essential expenses, well above the 8 to 9 months recommended for a household with two young children and two incomes. There is no shortfall, so your cash cushion is a clear strength, and it still covers about 15.4 months after your \$6,000 vacation payment.\n\n"
            "• Cash above the emergency reserve and your near-term goals comes to \$60,223. That is a resource you have available as you look at the other protection gaps.\n\n"
            "Life insurance\n"
            "• Timothy has \$140,000 of life insurance against a recommended range of \$750,000 to \$1,500,000, a shortfall of \$610,000. Melanie has \$110,000 against a range of \$600,000 to \$1,200,000, a shortfall of \$490,000. Neither of you has any excess, and both of you do hold some coverage. With Liam (6) and Josh (3) depending on both incomes, these gaps matter for your household.\n\n"
            "• Your household relies on two incomes, \$150,000 from Timothy and \$120,000 from Melanie. Losing either one would be hard for two young children to absorb.\n\n"
            "• Obligations would remain if one of you were gone: you have \$93,000 of listed debt, including an 18% credit card of \$18,000, and you still need \$113,509 for college beyond current 529 balances.\n\n"
            "Umbrella insurance\n"
            "• You have no umbrella policy, against a recommended minimum of \$1,000,000, so the full \$1,000,000 is uncovered. A liability claim could reach your net worth of \$695,500, which makes this a real exposure rather than a prediction.\n\n"
            "• Your home and both vehicles are insured, but that cover is separate from umbrella liability protection and doesn't fill this gap.\n\n"
            "• A claim could reach \$428,500 of assets (\$368,500 of equity), and your \$360,000 in liquid assets would be within reach too. That is the savings you are building for Liam and Josh.\n\n"
            "• Your cash cushion is a genuine strength, but it would be the money exposed in a claim, not a substitute for liability cover.",
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    if (widget.titulo == 'Jubilacion') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Retirement & Goals",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Divider(height: 30, thickness: 2),
          Text(
            "• Your retirement plan looks well supported as a projection: income is projected to cover 93% of the \$184,303.51 you would need each year, averaged over 31 retirement years, and your money doesn't run out before age 91.\n\n"
            "• Almost all of that coverage comes from guaranteed income (Social Security and annuities, \$171,055.83 per year on average), while other income covers only 0.2%. The plan's strength therefore rests on those guaranteed sources holding up as projected.\n\n"
            "• Your savings are projected to cover only about \$12,852.82 per year of spending on average, and the average draw is 1.0% of savings at the start of retirement. Savings and investments of \$2,371,900.89 (today's dollars) are projected to remain at the end of the plan, which leaves a cushion if things come in worse than expected.\n\n"
            "• Cash flow is projected to turn negative in several years, including 2030, 2041 and 2048 to 2053. Given the large projected savings, this matters less than the overall picture, but it shows spending will not be smooth year to year. No long-term care cost is included, and you have other goals after retirement totaling \$673,481.06.\n\n"
            "• Timothy's Growth and Melanie's Moderate risk profiles differ, and the portfolio is about 77% equity against a 60% Moderate target. That could add growth over the 21 years before retirement but also brings larger swings, so agreeing on how much swing you both can accept is worth considering. Your spending picture is also low confidence, so the projection is only as firm as those expense figures.\n\n"
            "We should look into: how reliable the guaranteed income from Social Security and annuities is, since it carries most of the plan, how the plan pays for the years when cash flow turns negative, and confirming actual spending so the projection rests on firm figures.",
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    if (widget.titulo == 'Patrimonio') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assets & Investments",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Divider(height: 30, thickness: 2),
          Text(
            "• Your wealth sits mostly in your home: real estate is \$350,000, or 44.4% of your \$788,500 in total assets. That is a large share in one asset you can't easily spend, though you hold \$300,000 of equity in it, with only a \$50,000 mortgage (85.7% equity).\n\n"
            "• You hold \$150,000 in cash against \$210,000 in invested savings. Since invested savings are what retirement mostly rests on, this means a large part of your liquid wealth isn't set up to grow over the long term. The cash does give you a flexible cushion.\n\n"
            "• Your invested savings are 81.2% in stocks, against a 98.0% target. Timothy's risk profile is Growth and Melanie's is Moderate, so one household mix may fit each of you differently.\n\n"
            "• You are saving toward retirement steadily: both employer matches are fully captured, worth \$8,000 and \$6,000 a year, so no match is being left behind.\n\n"
            "We should look into: how the \$150,000 of cash fits alongside your invested savings, whether IRAs and an HSA could suit you given the limits you could contribute up to, and how the 81.2% stock mix compares with each person's risk profile, once the current mix per person is confirmed.",
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Savings & Expenses",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Divider(height: 30, thickness: 2),
        Text(
          "• You save \$61,500 a year, 22.8% of your \$270,000 income, and both employer matches are fully captured. Your retirement saving is on track, with no extra needed.\n\n"
          "• Your cash flow shows \$36,960.75 a year left over (13.7%), but this figure is low confidence and spending may be understated. It matters because every other goal draws on the same uncertain surplus.\n\n"
          "• You hold \$150,800 in cash, above the 8 to 9 months of essential expenses (\$75,180 to \$84,577.50) that would cover emergencies. About \$60,222.50 sits beyond that reserve and your \$6,000 vacation goal, so safety is well covered.\n\n"
          "• Education is your main unfunded goal: \$0 is in 529 accounts, and meeting it would take about \$4,609.22 more per year, a first-year projection that rises each year. That is 1.7% of your income, small next to the idle cash but dependent on your real spending.\n\n"
          "• Your Roth IRAs have \$0 contributed so far. You could each contribute up to \$5,250.10, though this competes with education for the same surplus.\n\n"
          "We should look into: confirming your actual day-to-day spending, how the cash you hold above your reserve could support education saving and the 18% card, and whether Roth IRA contributions fit your plans.",
          style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155)),
        ),
      ],
    );
  }

  Widget _graficoHistograma(String titulo, List datos, double maxValor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // SCROLL HORIZONTAL AÑADIDO PARA EL HISTOGRAMA
          Scrollbar(
            controller: _scrollHistograma,
            thumbVisibility: true,
            thickness: 6.0,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _scrollHistograma,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: datos.map((d) {
                      final Map data = d as Map;
                      final double valor = data['valor'] as double;
                      double altura = (valor / maxValor) * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ), // Separación añadida
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(valor / 1000).toInt()}k',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 36,
                              height: altura,
                              decoration: BoxDecoration(
                                color: data['color'] as Color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['label'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _graficoDonut(String titulo, List segmentos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 24,
                      color: (segmentos[0] as Map)['color'] as Color,
                    ),
                    CircularProgressIndicator(
                      value: 0.56,
                      strokeWidth: 24,
                      color: (segmentos[1] as Map)['color'] as Color,
                    ),
                    CircularProgressIndicator(
                      value: 0.29,
                      strokeWidth: 24,
                      color: (segmentos[2] as Map)['color'] as Color,
                    ),
                    CircularProgressIndicator(
                      value: 0.10,
                      strokeWidth: 24,
                      color: (segmentos[3] as Map)['color'] as Color,
                    ),
                    const Center(
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: segmentos.map((s) {
                  final Map sec = s as Map;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: sec['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sec['label'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _graficoHaveVsNeed(
    String titulo1,
    double valor1,
    String titulo2,
    double valor2,
    Color colorActual,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo1,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '\$${(valor1 / 1000).toInt()}k',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo2,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '\$${(valor2 / 1000).toInt()}k',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorActual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (valor2 / valor1) > 1.0 ? 1.0 : (valor2 / valor1),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorActual,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cajaRatio(String titulo, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cajaFlujo(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cajaFlujoPequena(String titulo, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cajaGlosario(String termino, String definicion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("💡", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  termino,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  definicion,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GraficoJubilacionPainter extends CustomPainter {
  final double touchX;
  GraficoJubilacionPainter(this.touchX);

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0F172A).withAlpha(150),
          const Color(0xFF0F172A).withAlpha(10),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final paintLine = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();

    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.1,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paintLine);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, paintFill);

    final paintTouch = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(touchX, 0), Offset(touchX, size.height), paintTouch);
    canvas.drawCircle(Offset(touchX, size.height * 0.4), 4.0, paintTouch);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Patrimonio Proyectado',
        style: TextStyle(
          color: Color(0xFFEA580C),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(touchX > size.width - 100 ? touchX - 110 : touchX + 10, 10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TabObjetivosInteractivos extends StatefulWidget {
  const TabObjetivosInteractivos({super.key});

  @override
  State<TabObjetivosInteractivos> createState() =>
      _TabObjetivosInteractivosState();
}

class _TabObjetivosInteractivosState extends State<TabObjetivosInteractivos> {
  var listaObjetivos = [
    {
      "titulo": "Contratar Seguro de Vida",
      "desc": "Incrementar poliza de Timothy a \$750k minimo.",
      "estado": null as bool?,
    },
    {
      "titulo": "Liquidar Tarjeta de Credito",
      "desc": "Pagar los \$18,000 del Chase con liquidez.",
      "estado": null as bool?,
    },
    {
      "titulo": "Abrir cuenta 529",
      "desc": "Configurar ahorro automatico para universidad.",
      "estado": null as bool?,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Tus 5 Objetivos Vitales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _crearFilaObjetivo(
          Icons.elderly,
          'Jubilacion conjunta en 2048 (Edades 62 y 60).',
        ),
        _crearFilaObjetivo(
          Icons.flight_takeoff,
          'Vacaciones anuales con presupuesto de \$6,000.',
        ),
        _crearFilaObjetivo(
          Icons.school,
          'Financiar educacion de 2 hijos (\$45k cada uno).',
        ),
        _crearFilaObjetivo(
          Icons.house,
          'Comprar vivienda de \$600k en el ano 2030.',
        ),
        _crearFilaObjetivo(
          Icons.directions_car,
          'Comprar vehiculo por \$45,000 en 2028.',
        ),
        const Divider(height: 40),

        const Text(
          '6 Recomendaciones Estrategicas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _crearRecomendacion(
          Icons.shield_outlined,
          'Brecha de Proteccion de Vida',
          'Utilizad parte del exceso de efectivo para aumentar los seguros de vida (Timothy necesita \$610k mas, Melanie \$490k). Los dos ninos dependen de ambos ingresos.',
        ),
        _crearRecomendacion(
          Icons.umbrella,
          'Poliza Umbrella',
          'Considerad una poliza paraguas (Umbrella) porque una reclamacion de responsabilidad civil podria alcanzar mas alla de lo que teneis cubierto actualmente (\$1 Millon de riesgo).',
        ),
        _crearRecomendacion(
          Icons.credit_score,
          'Liquidar Deuda Cara',
          'Priorizad pagar la tarjeta de credito de \$18,000 al 18% con vuestro exceso de efectivo. Es vuestra deuda mas cara y vuestro efectivo supera comodamente lo que necesitais mantener.',
        ),
        _crearRecomendacion(
          Icons.school,
          'Ahorro Universitario',
          'Decidid como distribuir el ahorro para la universidad de Liam y Josh compartiendo vuestro flujo de caja con otras prioridades, ya que no hay nada reservado para ello aun.',
        ),
        _crearRecomendacion(
          Icons.trending_up,
          'Mix de Inversion',
          'Revisad juntos vuestra distribucion de inversiones (actualmente 81% en acciones) para que se situe donde ambos os sintais comodos, dado que vuestros niveles de confort con el riesgo difieren.',
        ),
        _crearRecomendacion(
          Icons.verified_user,
          'Mantener Fortalezas',
          'Mantened el plan de jubilacion y las aportaciones de los empleadores (Matches) tal y como estan, es una gran fortaleza.',
        ),
        const Divider(height: 40),

        const Text(
          'Tus Tareas Pendientes (Checklist)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Acciones prioritarias de este mes. Marca con un check al completarlas.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        const SizedBox(height: 16),

        ...List.generate(listaObjetivos.length, (index) {
          final obj = listaObjetivos[index];
          final bool? estado = obj['estado'] as bool?;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: estado == true
                    ? Colors.green
                    : (estado == false ? Colors.red : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obj['titulo'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: estado == true
                                ? TextDecoration.lineThrough
                                : null,
                            color: estado == true
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          obj['desc'] as String,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: estado == false
                          ? Colors.red
                          : Colors.grey.shade300,
                      size: 28,
                    ),
                    onPressed: () => setState(
                      () => listaObjetivos[index]['estado'] = (estado == false)
                          ? null
                          : false,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: estado == true
                          ? Colors.green
                          : Colors.grey.shade300,
                      size: 28,
                    ),
                    onPressed: () => setState(
                      () => listaObjetivos[index]['estado'] = (estado == true)
                          ? null
                          : true,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _crearFilaObjetivo(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icono, color: const Color(0xFFEA580C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crearRecomendacion(IconData icono, String titulo, String texto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: const Color(0xFF0F172A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabChatbot extends StatefulWidget {
  const TabChatbot({super.key});

  @override
  State<TabChatbot> createState() => _TabChatbotState();
}

class _TabChatbotState extends State<TabChatbot> {
  var mensajesChat = [
    {
      "emisor": "bot",
      "texto":
          "¡Hola Timothy y Melanie! He analizado vuestro diagnostico. Teneis mucha liquidez (\$150k), pero la tarjeta al 18% os cuesta dinero. ¿En que os ayudo hoy?",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mensajesChat.length,
            itemBuilder: (context, index) {
              final msg = mensajesChat[index];
              final esBot = msg['emisor'] == 'bot';
              return Align(
                alignment: esBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, right: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: esBot ? Colors.white : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: esBot
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                  ),
                  child: Text(
                    msg['texto'] as String,
                    style: TextStyle(
                      color: esBot ? const Color(0xFF1E293B) : Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activando microfono IA...'),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    icon: const Icon(Icons.mic, color: Color(0xFF0F172A)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F172A)),
                    ),
                    label: const Text(
                      'Voz IA',
                      style: TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Formulario de cita abierto.'),
                      ),
                    ),
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                    ),
                    label: const Text(
                      'Agente Humano',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  suffixIcon: const Icon(Icons.send, color: Color(0xFF0F172A)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
