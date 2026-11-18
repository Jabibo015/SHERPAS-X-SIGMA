import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Cambia esta URL por tu túnel HTTPS (ej. https://tu-subdominio.trycloudflare.com)
const String API_BASE_URL = "http://127.0.0.1:8000";

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

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  List _listaClientes = [];
  String _userIdSeleccionado = "user_timothy_01";
  Map _clienteActual = {};
  bool _cargandoDatos = true;
  String? _errorCarga;

  String get _baseUrl {
    if (API_BASE_URL != "http://127.0.0.1:8000") return API_BASE_URL;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000";
    }
    return API_BASE_URL;
  }

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    setState(() {
      _cargandoDatos = true;
      _errorCarga = null;
    });

    try {
      final respClientes = await http
          .get(Uri.parse("$_baseUrl/api/clientes"))
          .timeout(const Duration(seconds: 15));

      if (respClientes.statusCode == 200) {
        _listaClientes = jsonDecode(utf8.decode(respClientes.bodyBytes)) as List;
        if (_listaClientes.isNotEmpty) {
          final existeActual = _listaClientes.any(
            (c) => (c as Map)['user_id'] == _userIdSeleccionado,
          );
          if (!existeActual) {
            _userIdSeleccionado =
                (_listaClientes.first as Map)['user_id'].toString();
          }
        }
      }
      await _cargarDetalleCliente(_userIdSeleccionado);
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
        _errorCarga =
            "No se pudo conectar con $_baseUrl.\nVerifica que FastAPI y tu túnel estén activos.";
      });
    }
  }

  Future<void> _cargarDetalleCliente(String userId) async {
    setState(() {
      _cargandoDatos = true;
      _errorCarga = null;
    });

    try {
      final resp = await http
          .get(Uri.parse("$_baseUrl/api/cliente/$userId"))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
        setState(() {
          _userIdSeleccionado = userId;
          _clienteActual = data;
          _cargandoDatos = false;
        });
      } else {
        setState(() {
          _cargandoDatos = false;
          _errorCarga = "Error ${resp.statusCode} al cargar perfil $userId";
        });
      }
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
        _errorCarga = "Error de red al obtener datos de $userId";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'Sigma DZY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              if (_listaClientes.isNotEmpty)
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _userIdSeleccionado,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFFEA580C),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _listaClientes.map((item) {
                          final cliente = item as Map;
                          final id = cliente['user_id'].toString();
                          final nom = cliente['nombre'].toString();
                          final sc = cliente['puntuacion_salud'] ?? '';
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              "$nom ($sc)",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (nuevoId) {
                          if (nuevoId != null &&
                              nuevoId != _userIdSeleccionado) {
                            _cargarDetalleCliente(nuevoId);
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Recargar datos',
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              onPressed: _inicializarApp,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaPerfil(
                      nombreInicial:
                          _clienteActual['nombre']?.toString() ?? 'Cliente',
                      correoInicial:
                          _clienteActual['correo']?.toString() ??
                          'cliente@sigmadzy.com',
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 16.0, left: 4.0),
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
        body: _cargandoDatos
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFEA580C)),
                    SizedBox(height: 16),
                    Text(
                      'Cargando diagnostico desde Sherpas...',
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
              )
            : _errorCarga != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorCarga!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _inicializarApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      TabResumenInteractivo(
                        userId: _userIdSeleccionado,
                        clienteData: _clienteActual,
                      ),
                      TabObjetivosInteractivos(
                        key: ValueKey("obj_$_userIdSeleccionado"),
                        userId: _userIdSeleccionado,
                        baseUrl: _baseUrl,
                        clienteData: _clienteActual,
                      ),
                      TabChatbot(
                        key: ValueKey("chat_$_userIdSeleccionado"),
                        userId: _userIdSeleccionado,
                        nombreCliente:
                            _clienteActual['nombre']?.toString() ?? 'Familia',
                        baseUrl: _baseUrl,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class PantallaPerfil extends StatefulWidget {
  final String nombreInicial;
  final String correoInicial;

  const PantallaPerfil({
    super.key,
    required this.nombreInicial,
    required this.correoInicial,
  });

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  late String nombre;
  late String correo;
  String telefono = '+34 600 123 456';

  @override
  void initState() {
    super.initState();
    nombre = widget.nombreInicial;
    correo = widget.correoInicial;
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
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&fit=crop',
              ),
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
          _crearCampoPerfil(Icons.person, 'Hogar / Titular', nombre, () {
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
          const SizedBox(height: 32),
          _crearBotonAccion(
            Icons.help_outline,
            'Ayuda y Contacto',
            'Contacta con el soporte tecnico.',
            () {
              _mostrarInfoLegal(
                'Centro de Soporte',
                'Nuestro equipo de Sherpas esta disponible en soporte@sigmadzy.com o mediante el Asesor IA.',
              );
            },
          ),
          _crearBotonAccion(
            Icons.privacy_tip_outlined,
            'Terminos y Privacidad',
            'Informacion educativa, no asesoramiento vinculante.',
            () {
              _mostrarInfoLegal(
                'Aviso Legal',
                'La informacion proporcionada en Sigma DZY tiene fines educativos y de planificacion.',
              );
            },
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
  final String userId;
  final Map clienteData;

  const TabResumenInteractivo({
    super.key,
    required this.userId,
    required this.clienteData,
  });

  @override
  State<TabResumenInteractivo> createState() => _TabResumenInteractivoState();
}

class _TabResumenInteractivoState extends State<TabResumenInteractivo> {
  bool esModoAnalitico = false;

  Color _obtenerColorPuntuacion(int puntuacion) {
    if (puntuacion < 55) return Colors.red;
    if (puntuacion <= 75) return const Color(0xFFEA580C);
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final resumen = (widget.clienteData['resumen_ui'] as Map?) ?? {};
    final int miPuntuacion =
        (resumen['puntuacion_salud'] ??
                widget.clienteData['puntuacion_salud'] ??
                60)
            as int;
    final Color colorScore = _obtenerColorPuntuacion(miPuntuacion);

    final String nombreHogar =
        (resumen['nombre'] ?? widget.clienteData['nombre'] ?? 'Familia')
            .toString();
    final String ubicacion = (resumen['ubicacion'] ?? '').toString();
    final String mensajeScore =
        (resumen['mensaje_score'] ??
                "Estais logrando salir adelante, pero aun no estais prosperando al maximo. Mejorar vuestra salud financiera desbloqueara el potencial de vuestro dinero.")
            .toString();
    final List pilares = (resumen['pilares'] as List?) ?? [];

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
              Text(
                ubicacion.isNotEmpty
                    ? '$nombreHogar • $ubicacion'
                    : nombreHogar,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEA580C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Puntuacion de Salud Financiera',
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
              Text(
                mensajeScore,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              if (pilares.isNotEmpty) ...[
                const Divider(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Desglose por Pilares (Sherpas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...pilares.map((p) {
                  final pilar = p as Map;
                  final String nombrePilar = (pilar['pillar'] ?? '').toString();
                  final int scorePilar = (pilar['score'] ?? 0) as int;
                  final String puntos =
                      (pilar['points_shown_in_app'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nombrePilar,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '$scorePilar/100 ($puntos)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _obtenerColorPuntuacion(scorePilar),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (scorePilar / 100.0).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: Colors.grey.shade200,
                            color: _obtenerColorPuntuacion(scorePilar),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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
            _crearBotonArea(
              context,
              'Hogar e Ingresos',
              Icons.family_restroom,
              'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&fit=crop',
            ),
            _crearBotonArea(
              context,
              'Jubilacion',
              Icons.elderly,
              'https://images.unsplash.com/photo-1473186578172-c141e6798cf4?w=400&fit=crop',
            ),
            _crearBotonArea(
              context,
              'Patrimonio',
              Icons.house,
              'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&fit=crop',
            ),
            _crearBotonArea(
              context,
              'Deudas',
              Icons.credit_score,
              'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=400&fit=crop',
            ),
            _crearBotonArea(
              context,
              'Ahorros y Gastos',
              Icons.savings,
              'https://images.unsplash.com/photo-1579621970588-a35d0e7ab9b6?w=400&fit=crop',
            ),
            _crearBotonArea(
              context,
              'Proteccion',
              Icons.shield,
              'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?w=400&fit=crop',
            ),
          ],
        ),
      ],
    );
  }

  Widget _crearBotonArea(
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
              clienteData: widget.clienteData,
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
  final Map clienteData;

  const PantallaDetalle({
    super.key,
    required this.titulo,
    required this.icono,
    required this.esModoAnalitico,
    required this.clienteData,
  });

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  double _touchX = 150.0;
  final ScrollController _scrollFlujo = ScrollController();
  final ScrollController _scrollHistograma = ScrollController();

  @override
  void dispose() {
    _scrollFlujo.dispose();
    _scrollHistograma.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // Diagnóstico compacto: permite inspeccionar el esquema recibido por API
  // sin copiar ni compartir el JSON financiero completo.
  // Los valores numéricos y los datos personales se omiten deliberadamente.
  // ----------------------------------------------------------------------
  String _tipoDato(dynamic valor) {
    if (valor == null) return 'null';
    if (valor is bool) return 'booleano';
    if (valor is num) return 'numero';
    if (valor is String) return 'texto';
    if (valor is List) return 'lista';
    if (valor is Map) return 'objeto';
    return valor.runtimeType.toString();
  }

  Map<String, dynamic> _resumirEsquema(dynamic nodo, {int profundidad = 0}) {
    final tipo = _tipoDato(nodo);
    if (profundidad >= 4) return {'tipo': tipo};

    if (nodo is Map) {
      final campos = <String, dynamic>{};
      final entradas = nodo.entries.take(30);
      for (final entrada in entradas) {
        campos[entrada.key.toString()] = _resumirEsquema(
          entrada.value,
          profundidad: profundidad + 1,
        );
      }
      return {
        'tipo': 'objeto',
        'numero_campos': nodo.length,
        'campos': campos,
        if (nodo.length > 30) 'campos_omitidos': nodo.length - 30,
      };
    }

    if (nodo is List) {
      return {
        'tipo': 'lista',
        'elementos': nodo.length,
        'muestra_del_primer_elemento': nodo.isEmpty
            ? null
            : _resumirEsquema(nodo.first, profundidad: profundidad + 1),
      };
    }

    // No se devuelve el contenido de textos, importes, fechas ni identificadores.
    return {'tipo': tipo};
  }

  void _buscarMetricasParaDiagnostico(
    dynamic nodo,
    String ruta,
    List<Map<String, dynamic>> salida,
    List<int> visitas, {
    int profundidad = 0,
  }) {
    if (salida.length >= 150 || visitas.first >= 5000 || profundidad > 18) {
      return;
    }
    visitas[0]++;

    if (nodo is List) {
      final limite = nodo.length < 100 ? nodo.length : 100;
      for (int i = 0; i < limite; i++) {
        _buscarMetricasParaDiagnostico(
          nodo[i], '$ruta[$i]', salida, visitas,
          profundidad: profundidad + 1,
        );
      }
      return;
    }

    if (nodo is! Map) return;

    final tieneValue = nodo.containsKey('value') || nodo.containsKey('amount') ||
        nodo.containsKey('score');
    final tieneEtiqueta = nodo.containsKey('label') || nodo.containsKey('name') ||
        nodo.containsKey('title');
    if (tieneValue && (tieneEtiqueta || nodo.containsKey('unit'))) {
      final valor = nodo.containsKey('value')
          ? nodo['value']
          : (nodo.containsKey('amount') ? nodo['amount'] : nodo['score']);
      salida.add({
        'ruta': ruta,
        'etiqueta': (nodo['label'] ?? nodo['name'] ?? nodo['title'] ?? '').toString(),
        'unidad': (nodo['unit'] ?? nodo['currency'] ?? '').toString(),
        'periodo': (nodo['period'] ?? nodo['date'] ?? nodo['year'] ?? '').toString(),
        'tipo_valor': _tipoDato(valor),
        'valor_disponible': valor != null,
      });
    }

    for (final entrada in nodo.entries) {
      _buscarMetricasParaDiagnostico(
        entrada.value,
        ruta.isEmpty ? entrada.key.toString() : '$ruta.${entrada.key}',
        salida,
        visitas,
        profundidad: profundidad + 1,
      );
      if (salida.length >= 150 || visitas.first >= 5000) break;
    }
  }

  String _crearInformeDiagnosticoJson() {
    final resumen = widget.clienteData['resumen_ui'];
    final metricasSalud = resumen is Map ? resumen['metricas_salud'] : null;
    final metricasInversion = resumen is Map ? resumen['metricas_inversion'] : null;
    final candidatos = <Map<String, dynamic>>[];
    final visitas = <int>[0];

    _buscarMetricasParaDiagnostico(
      metricasSalud, 'resumen_ui.metricas_salud', candidatos, visitas,
    );
    _buscarMetricasParaDiagnostico(
      metricasInversion, 'resumen_ui.metricas_inversion', candidatos, visitas,
    );
    _buscarMetricasParaDiagnostico(
      resumen is Map ? resumen['pilares'] : null,
      'resumen_ui.pilares', candidatos, visitas,
    );

    final informe = <String, dynamic>{
      'diagnostico': 'Sigma DZY - esquema para selección de gráficos',
      'version': 1,
      'seccion_abierta': widget.titulo,
      'privacidad': 'Omite valores financieros e identificadores. Conserva rutas, etiquetas, unidades y periodos; revisa estos textos antes de compartirlos.',
      'campos_raiz': widget.clienteData.keys.map((e) => e.toString()).toList(),
      'esquema_resumen_ui': resumen is Map
          ? _resumirEsquema(resumen)
          : {'tipo': _tipoDato(resumen)},
      'metricas_detectadas': candidatos,
      'limites_inspeccion': {
        'maximo_metricas': 150,
        'nodos_inspeccionados': visitas.first,
        'nota': 'La muestra describe rutas y tipos; no contiene importes reales.',
      },
    };
    return const JsonEncoder.withIndent('  ').convert(informe);
  }

  Future<void> _mostrarDiagnosticoJson() async {
    final informe = _crearInformeDiagnosticoJson();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Diagnóstico de datos para gráficos'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: SelectableText(
              informe,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: informe));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe reducido copiado al portapapeles')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar informe'),
          ),
        ],
      ),
    );
  }

  bool get _esCasoRealSherpas {
    final resumen = widget.clienteData['resumen_ui'];
    if (resumen is! Map) return false;
    final pilares = resumen['pilares'];
    return (pilares is List && pilares.isNotEmpty) ||
        resumen['metricas_salud'] != null ||
        resumen['metricas_inversion'] != null;
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
        actions: [
          IconButton(
            tooltip: 'Preparar informe reducido de datos para gráficos',
            icon: const Icon(Icons.data_object, color: Colors.white),
            onPressed: _mostrarDiagnosticoJson,
          ),
        ],
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
          const SizedBox(height: 24),
          if (_esCasoRealSherpas)
            _construirContenidoRealSherpas()
          else
            (widget.esModoAnalitico
                ? _construirContenidoAnalitico()
                : _construirContenidoVisual()),
        ],
      ),
    );
  }

  // ======================================================================
  // DATOS REALES SHERPAS: graficos + informacion adicional (sin volcar JSON)
  // ======================================================================
  static const Map<String, List<String>> _palabrasClave = {
    'Hogar e Ingresos': ['household', 'income', 'cashflow', 'cash flow', 'salary', 'hogar', 'ingres'],
    'Jubilacion': ['retire', 'jubil', 'longevity', 'pension', 'invest', 'portfolio'],
    'Patrimonio': ['net worth', 'networth', 'wealth', 'asset', 'allocation', 'patrim', 'portfolio', 'invest'],
    'Deudas': ['debt', 'deud', 'liabilit', 'loan', 'credit', 'mortgage'],
    'Ahorros y Gastos': ['saving', 'expens', 'ahorro', 'gasto', 'liquid', 'emergency', 'cash'],
    'Proteccion': ['protect', 'insur', 'seguro', 'coverage', 'emergency'],
  };

  bool _coincideSeccion(String texto) {
    final t = texto.toLowerCase();
    final claves = _palabrasClave[widget.titulo] ?? const <String>[];
    return claves.any((k) => t.contains(k));
  }

  // Recorre el JSON y recoge todo nodo con forma {label, value, unit, ...}
  void _extraerMetricas(
    dynamic nodo,
    String grupo,
    String clave,
    List<Map<String, dynamic>> out,
  ) {
    // Algunos endpoints entregan bloques de métricas dentro de arrays.
    // También los recorremos para no perder datos anidados en listas.
    if (nodo is List) {
      for (int i = 0; i < nodo.length; i++) {
        _extraerMetricas(nodo[i], grupo, '$clave[$i]', out);
      }
      return;
    }
    if (nodo is! Map) return;
    final bool esMetrica = nodo.containsKey('value') &&
        (nodo.containsKey('label') || nodo.containsKey('unit'));
    if (esMetrica) {
      final v = nodo['value'];
      if (v == null || v is Map || v is List) return;
      out.add({
        'grupo': grupo,
        'clave': clave,
        'label': (nodo['label'] ?? clave).toString(),
        'value': v,
        'unit': (nodo['unit'] ?? '').toString(),
        'period': (nodo['period'] ?? '').toString(),
      });
      return;
    }
    nodo.forEach((k, v) {
      _extraerMetricas(v, grupo.isEmpty ? k.toString() : grupo, k.toString(), out);
    });
  }

  bool _esNumerico(dynamic v) {
    if (v is num) return true;
    return RegExp(r'^\s*[-\$]?\s*[\d,]+(\.\d+)?\s*%?\s*$').hasMatch(v.toString());
  }

  double? _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''));
  }

  String _miles(double v) {
    final s = v.abs().round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return (v < 0 ? '-' : '') + b.toString();
  }

  String _numTexto(double x) {
    if (x.abs() >= 1000 || x == x.roundToDouble()) return _miles(x);
    return x.toStringAsFixed(1);
  }

  String _normUnidad(String unit) {
    final u = unit.toLowerCase();
    if (u.contains('%') || u.contains('percent')) return '%';
    if (u.contains('usd') || u.contains('\$') || u.contains('currency') || u.contains('dollar')) return 'usd';
    if (u.contains('month')) return 'months';
    if (u.contains('year')) return 'years';
    if (u.isEmpty || u == 'n/a' || u == 'ratio' || u == 'number') return 'n';
    return u;
  }

  String _formatearValor(dynamic v, String unit) {
    if (!_esNumerico(v)) return v.toString();
    final n = _num(v);
    if (n == null) return v.toString();
    switch (_normUnidad(unit)) {
      case '%':
        return '${_numTexto(n)}%';
      case 'usd':
        return '\$${_miles(n)}';
      case 'months':
        return '${_numTexto(n)} meses';
      case 'years':
        return '${_numTexto(n)} años';
      case 'n':
        return _numTexto(n);
      default:
        return '${_numTexto(n)} $unit';
    }
  }

  String _tituloUnidad(String u) {
    switch (u) {
      case '%':
        return 'Porcentajes clave';
      case 'usd':
        return 'Importes clave';
      case 'months':
        return 'Cobertura en meses';
      case 'years':
        return 'Horizonte en años';
      default:
        return 'Otros indicadores';
    }
  }

  Color _colorScore(double s) {
    if (s < 55) return Colors.red;
    if (s <= 75) return const Color(0xFFEA580C);
    return Colors.green;
  }

  Widget _tarjetaSeccion(String titulo, Widget hijo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          hijo,
        ],
      ),
    );
  }

  Widget _kpi(Map<String, dynamic> m, double ancho) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatearValor(m['value'], m['unit'].toString()),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            m['label'].toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _barrasHorizontales(List<Map<String, dynamic>> items, String unidad) {
    const colores = [
      Color(0xFF0F172A),
      Color(0xFFEA580C),
      Color(0xFF475569),
      Color(0xFF94A3B8),
      Color(0xFF334155),
      Color(0xFFFB923C),
    ];
    final valores = items.map((m) => (_num(m['value']) ?? 0).abs()).toList();
    double maximo = valores.fold<double>(0, (a, b) => b > a ? b : a);
    if (unidad == '%' && maximo <= 100) maximo = 100;
    if (maximo == 0) maximo = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comparación entre indicadores', style: TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500,
                )),
                Text('Escala: ${_formatearValor(maximo, items.first['unit'].toString())}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ...List.generate(items.length, (i) {
        final m = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      m['label'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatearValor(m['value'], m['unit'].toString()),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (valores[i] / maximo).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: colores[i % colores.length],
                ),
              ),
            ],
          ),
        );
      }),
      ],
    );
  }

  Widget _listaIndicadores(List<Map<String, dynamic>> metricas, {required bool conPeriodo}) {
    final List<Widget> filas = [];
    String grupoActual = '';
    for (final m in metricas) {
      final grupo = m['grupo'].toString();
      if (grupo != grupoActual) {
        grupoActual = grupo;
        filas.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            grupo.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFFEA580C),
            ),
          ),
        ));
      }
      final period = m['period'].toString();
      filas.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['label'].toString(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                  ),
                  if (conPeriodo && period.isNotEmpty)
                    Text(
                      period,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                _formatearValor(m['value'], m['unit'].toString()),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ));
      filas.add(Divider(height: 1, color: Colors.grey.shade200));
    }
    return Column(children: filas);
  }

  // ----------------------------------------------------------------------
  // Gráficos específicos construidos directamente desde rutas del JSON.
  // No se inventan valores: cada serie se dibuja solo si sus campos existen.
  // ----------------------------------------------------------------------
  dynamic _leerRuta(dynamic raiz, String ruta) {
    dynamic actual = raiz;
    for (final parte in ruta.split('.')) {
      if (actual is Map && actual.containsKey(parte)) {
        actual = actual[parte];
      } else {
        return null;
      }
    }
    return actual;
  }

  double? _leerNumeroJson(dynamic valor, {int profundidad = 0}) {
    if (valor == null || profundidad > 3) return null;
    if (valor is num) {
      final n = valor.toDouble();
      return n.isFinite ? n : null;
    }
    if (valor is Map) {
      for (final clave in ['value', 'amount', 'score', 'numericValue']) {
        if (valor.containsKey(clave)) {
          final n = _leerNumeroJson(valor[clave], profundidad: profundidad + 1);
          if (n != null) return n;
        }
      }
      return null;
    }
    final texto = valor.toString().trim();
    if (texto.isEmpty) return null;
    final limpio = texto.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.\-]'), '');
    final n = double.tryParse(limpio);
    return n != null && n.isFinite ? n : null;
  }

  List<Map<String, dynamic>> _puntosDeRutas(
    Map resumen,
    List<Map<String, String>> definiciones, {
    required String unidad,
  }) {
    final puntos = <Map<String, dynamic>>[];
    for (final d in definiciones) {
      final valor = _leerNumeroJson(_leerRuta(resumen, d['ruta']!));
      if (valor == null) continue;
      puntos.add({
        'label': d['etiqueta']!,
        'value': valor,
        'unit': unidad,
        'period': '',
      });
    }
    return puntos;
  }

  Widget? _graficoDeRutas(
    Map resumen,
    String titulo,
    List<Map<String, String>> definiciones, {
    required String unidad,
  }) {
    final puntos = _puntosDeRutas(resumen, definiciones, unidad: unidad);
    // Dos puntos como mínimo para que exista una comparación real.
    if (puntos.length < 2) return null;
    // No convertir cifras negativas en barras positivas.
    final positivos = puntos.where((p) => (p['value'] as double) >= 0).toList();
    if (positivos.length < 2) return null;
    return _tarjetaSeccion(titulo, _barrasHorizontales(positivos, unidad));
  }

  Widget? _graficoRango(
    Map resumen,
    String titulo, {
    required String rutaActual,
    required String rutaMinimo,
    required String rutaMaximo,
    required String unidad,
    String etiquetaActual = 'Actual',
    String etiquetaRango = 'Rango recomendado',
  }) {
    final actual = _leerNumeroJson(_leerRuta(resumen, rutaActual));
    final minimo = _leerNumeroJson(_leerRuta(resumen, rutaMinimo));
    final maximo = _leerNumeroJson(_leerRuta(resumen, rutaMaximo));
    if (actual == null || minimo == null || maximo == null ||
        actual < 0 || minimo < 0 || maximo < 0) {
      return null;
    }
    final inferior = math.min(minimo, maximo).toDouble();
    final superior = math.max(minimo, maximo).toDouble();
    final escala = math.max(math.max(actual, superior), 1.0).toDouble();
    return _tarjetaSeccion(
      titulo,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(etiquetaActual, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(_formatearValor(actual, unidad), style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A),
              )),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            width: double.infinity,
            child: CustomPaint(
              painter: _RangeIndicatorPainter(actual, inferior, superior, escala),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$etiquetaRango · mínimo: ${_formatearValor(inferior, unidad)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('máximo: ${_formatearValor(superior, unidad)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _graficosDeLaSeccion(Map resumen) {
    final graficos = <Widget>[];
    void agregar(
      String titulo,
      List<Map<String, String>> campos,
      String unidad,
    ) {
      final grafico = _graficoDeRutas(
        resumen, titulo, campos, unidad: unidad,
      );
      if (grafico != null) graficos.add(grafico);
    }

    switch (widget.titulo) {
      case 'Hogar e Ingresos':
        agregar('Flujo de caja del hogar · importes recibidos', [
          {'ruta': 'metricas_salud.cashflowStatement.inflows.total', 'etiqueta': 'Ingresos totales'},
          {'ruta': 'metricas_salud.cashflowStatement.outflows.total', 'etiqueta': 'Gastos totales'},
          {'ruta': 'metricas_salud.cashflowStatement.freeCashflow.total', 'etiqueta': 'Flujo libre'},
        ], 'USD');
        break;

      case 'Jubilacion':
        agregar('Necesidades e ingresos durante la jubilación', [
          {'ruta': 'metricas_salud.facts.retirement.spendingNeed', 'etiqueta': 'Necesidad anual de gasto'},
          {'ruta': 'metricas_salud.facts.retirement.guaranteedIncome', 'etiqueta': 'Ingresos garantizados'},
          {'ruta': 'metricas_salud.facts.retirement.spendingGap', 'etiqueta': 'Déficit anual cubierto con ahorro'},
        ], 'USD/año');
        agregar('Capital previsto y brecha al jubilarse', [
          {'ruta': 'metricas_salud.ratios.retirementSavings.balanceInRetirementAccountsAtRetirementAge', 'etiqueta': 'Saldo previsto en cuentas de jubilación'},
          {'ruta': 'metricas_salud.ratios.retirementSavings.planningGapAtRetirementAge', 'etiqueta': 'Brecha de planificación'},
        ], 'USD');
        agregar('Cobertura de necesidades de jubilación', [
          {'ruta': 'metricas_salud.retirementAndOtherGoals.incomeVsIncomeNeeds.guaranteedIncomeVsIncomeNeeded', 'etiqueta': 'Ingresos garantizados / necesidad'},
          {'ruta': 'metricas_salud.retirementAndOtherGoals.incomeVsIncomeNeeds.otherIncomeVsIncomeNeeded', 'etiqueta': 'Otros ingresos / necesidad'},
          {'ruta': 'metricas_salud.retirementAndOtherGoals.incomeVsIncomeNeeds.allIncomesVsIncomeNeeded', 'etiqueta': 'Todos los ingresos / necesidad'},
        ], 'ratio');
        break;

      case 'Patrimonio':
        agregar('Balance patrimonial · activos, pasivos y patrimonio neto', [
          {'ruta': 'metricas_salud.netWorthStatement.assets.total', 'etiqueta': 'Activos'},
          {'ruta': 'metricas_salud.netWorthStatement.liabilities.total', 'etiqueta': 'Pasivos'},
          {'ruta': 'metricas_salud.netWorthStatement.netWorth.total', 'etiqueta': 'Patrimonio neto'},
        ], 'USD');
        final donut = _graficoDistribucionPosiciones();
        if (donut != null) {
          graficos.add(_tarjetaSeccion('Distribución de la cartera por categoría', donut));
        }
        break;

      case 'Deudas':
        agregar('Ratio deuda / ingresos frente a umbrales', [
          {'ruta': 'metricas_salud.debtManagement.debtToIncomeAndMonthlyObligations.dti', 'etiqueta': 'Ratio actual deuda / ingresos'},
          {'ruta': 'metricas_salud.debtManagement.debtToIncomeAndMonthlyObligations.dtiFirstThreshold', 'etiqueta': 'Primer umbral'},
          {'ruta': 'metricas_salud.debtManagement.debtToIncomeAndMonthlyObligations.dtiSecondThreshold', 'etiqueta': 'Segundo umbral'},
          {'ruta': 'metricas_salud.debtManagement.debtToIncomeAndMonthlyObligations.dtiThirdThreshold', 'etiqueta': 'Tercer umbral'},
        ], 'ratio');
        agregar('Peso de la vivienda frente a sus umbrales', [
          {'ruta': 'metricas_salud.debtManagement.housingExpenses.housingRatio', 'etiqueta': 'Ratio de vivienda actual'},
          {'ruta': 'metricas_salud.debtManagement.housingExpenses.housingRatioFirstThreshold', 'etiqueta': 'Primer umbral'},
          {'ruta': 'metricas_salud.debtManagement.housingExpenses.housingRatioSecondThreshold', 'etiqueta': 'Segundo umbral'},
        ], 'ratio');
        break;

      case 'Ahorros y Gastos':
        agregar('Ahorro anual por tipo de cuenta', [
          {'ruta': 'metricas_salud.savingsAndExpenses.annualSavings.currentAnnualSavingsAtRetirementAccounts', 'etiqueta': 'Cuentas de jubilación'},
          {'ruta': 'metricas_salud.savingsAndExpenses.annualSavings.currentAnnualSavingsAtTaxableAccounts', 'etiqueta': 'Cuentas imponibles'},
          {'ruta': 'metricas_salud.savingsAndExpenses.annualSavings.currentAnnualSavingsAt529Accounts', 'etiqueta': 'Cuentas educativas 529'},
          {'ruta': 'metricas_salud.savingsAndExpenses.annualSavings.currentAnnualSavingsAtHSA', 'etiqueta': 'Cuenta HSA'},
        ], 'USD/año');
        final liquidez = _graficoRango(
          resumen,
          'Liquidez frente al rango objetivo del fondo de emergencia',
          rutaActual: 'metricas_salud.savingsAndExpenses.liquidityContext.emergencyFundInCash',
          rutaMinimo: 'metricas_salud.savingsAndExpenses.liquidityContext.minEmergencyFundTargetInCash',
          rutaMaximo: 'metricas_salud.savingsAndExpenses.liquidityContext.maxEmergencyFundTargetInCash',
          unidad: 'USD',
        );
        if (liquidez != null) graficos.add(liquidez);
        break;

      case 'Proteccion':
        final fondo = _graficoRango(
          resumen,
          'Fondo de emergencia · situación frente al rango recomendado',
          rutaActual: 'metricas_salud.ratios.emergencyFund.emergencyFund',
          rutaMinimo: 'metricas_salud.ratios.emergencyFund.minRecommendedEmergencyFund',
          rutaMaximo: 'metricas_salud.ratios.emergencyFund.maxRecommendedEmergencyFund',
          unidad: 'USD',
        );
        if (fondo != null) graficos.add(fondo);
        final vida = _graficoRango(
          resumen,
          'Seguro de vida · cobertura del titular frente al rango recomendado',
          rutaActual: 'metricas_salud.ratios.lifeInsurance.clientCoverage',
          rutaMinimo: 'metricas_salud.ratios.lifeInsurance.recommendedClientMinCoverage',
          rutaMaximo: 'metricas_salud.ratios.lifeInsurance.recommendedClientMaxCoverage',
          unidad: 'USD',
        );
        if (vida != null) graficos.add(vida);
        final umbrella = _graficoRango(
          resumen,
          'Seguro umbrella · cobertura actual y objetivo',
          rutaActual: 'metricas_salud.ratios.umbrella.currentCoverage',
          rutaMinimo: 'metricas_salud.ratios.umbrella.recommendedCoverage',
          rutaMaximo: 'metricas_salud.ratios.umbrella.recommendedCoverage',
          unidad: 'USD',
          etiquetaRango: 'Objetivo recomendado',
        );
        if (umbrella != null) graficos.add(umbrella);
        break;
    }
    return graficos;
  }

  Widget? _graficoDistribucionPosiciones() {
    // Según el esquema de Sherpas, posiciones cuelga de resumen_ui.
    final resumen = widget.clienteData['resumen_ui'];
    final posiciones = resumen is Map ? resumen['posiciones'] : null;
    if (posiciones is! List || posiciones.isEmpty) return null;

    final totales = <String, double>{};
    for (final fila in posiciones) {
      if (fila is! Map) continue;
      final categoria = (fila['category'] ?? fila['type'] ?? 'Sin categoría').toString().trim();
      final valor = _leerNumeroJson(fila['value']);
      if (categoria.isEmpty || valor == null || valor <= 0) continue;
      totales[categoria] = (totales[categoria] ?? 0) + valor;
    }
    if (totales.length < 2) return null;

    final ordenadas = totales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visibles = ordenadas.take(6).toList();
    if (ordenadas.length > 6) {
      final otros = ordenadas.skip(6).fold<double>(0, (s, e) => s + e.value);
      visibles.add(MapEntry('Otras categorías', otros));
    }
    final total = visibles.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return null;

    const colores = <Color>[
      Color(0xFF0F172A), Color(0xFFEA580C), Color(0xFF475569),
      Color(0xFF94A3B8), Color(0xFF0D9488), Color(0xFFF59E0B),
      Color(0xFF64748B),
    ];
    final valores = visibles.map((e) => e.value).toList();
    return Column(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: CustomPaint(
            painter: _DonutDistribucionPainter(valores, colores),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text('\$${_miles(total)}', style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A),
                  )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(visibles.length, (i) {
          final e = visibles[i];
          final pct = e.value / total * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: colores[i % colores.length], shape: BoxShape.circle,
                )),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A),
                )),
                const SizedBox(width: 10),
                Text('\$${_miles(e.value)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _construirContenidoRealSherpas() {
    final resumen = widget.clienteData['resumen_ui'] as Map;
    final narrativaFh = (resumen['narrativa_salud'] as Map?) ?? {};
    final narrativaIa = (resumen['narrativa_inversion'] as Map?) ?? {};
    final hogar = (resumen['hogar'] as List?) ?? [];
    final pilares = (resumen['pilares'] as List?) ?? [];

    final String textoNarrativa = widget.esModoAnalitico
        ? "${narrativaFh['summary_main'] ?? ''}\n\n${narrativaIa['summary_main'] ?? ''}"
            .trim()
        : "${narrativaFh['snapshot_main'] ?? ''}\n\n${narrativaIa['snapshot_main'] ?? ''}"
            .trim();

    // 1) Aplanar metricas y quedarnos con las de esta seccion
    final List<Map<String, dynamic>> todas = [];
    _extraerMetricas(resumen['metricas_salud'], '', '', todas);
    _extraerMetricas(resumen['metricas_inversion'], '', '', todas);

    List<Map<String, dynamic>> metricas = todas
        .where((m) => _coincideSeccion('${m['grupo']} ${m['clave']}'))
        .toList();
    if (metricas.isEmpty) {
      metricas = todas
          .where((m) => _coincideSeccion(m['label'].toString()))
          .toList();
    }
    // No mostramos métricas de otra sección como sustituto: sería fácil
    // atribuir a Deudas, por ejemplo, un indicador de Patrimonio.

    final List<Widget> w = [];

    // 2) Composicion del hogar
    if (widget.titulo == 'Hogar e Ingresos' && hogar.isNotEmpty) {
      w.add(_tarjetaSeccion(
        'Composicion del Hogar',
        Column(
          children: hogar.map<Widget>((m) {
            final miembro = m as Map;
            final nombreM = (miembro['first_name'] ?? '?').toString();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  nombreM.isNotEmpty ? nombreM.substring(0, 1) : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                "$nombreM (${miembro['role'] ?? ''})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Edad: ${miembro['age'] ?? '-'} • Perfil: ${miembro['risk_profile'] ?? 'N/A'}",
              ),
            );
          }).toList(),
        ),
      ));
    }

    // 3) Puntuacion de pilares: resumen visual, solo en Informe Visual.
    if (!widget.esModoAnalitico) {
      final pilaresSeccion = pilares
          .whereType<Map>()
          .where((p) => _coincideSeccion((p['pillar'] ?? '').toString()))
          .toList();
      if (pilaresSeccion.isNotEmpty) {
        w.add(_tarjetaSeccion(
          'Puntuacion del pilar',
          Column(
            children: pilaresSeccion.map<Widget>((p) {
              final nombre = (p['pillar'] ?? '').toString();
              final double score = _num(p['score']) ?? 0;
              final puntos = (p['points_shown_in_app'] ?? '').toString();
              final String etiqueta = puntos.isNotEmpty
                  ? '${score.round()}/100 ($puntos)'
                  : '${score.round()}/100';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Text(etiqueta, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _colorScore(score),
                        )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (score / 100.0).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: _colorScore(score),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ));
      }
    }

    // 3 bis) Gráficos especializados: usan rutas conocidas del JSON de cada área.
    // Se incluyen tanto en Informe Visual como en Informe Detallado.
    final graficosSeccion = _graficosDeLaSeccion(resumen);
    w.addAll(graficosSeccion);

    // 4) KPIs y gráficos se alimentan de las métricas numéricas del JSON.
    // Los gráficos se muestran en ambos modos; el detallado añade contexto y periodos.
    final numericas = metricas.where((m) => _esNumerico(m['value'])).toList();
    if (numericas.isNotEmpty) {
      if (!widget.esModoAnalitico) {
        final double ancho = (MediaQuery.of(context).size.width - 40 - 12) / 2;
        w.add(Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: numericas.take(4).map((m) => _kpi(m, ancho)).toList(),
          ),
        ));
      }

      // No se mezclan unidades distintas (por ejemplo USD con porcentajes).
      // Se excluyen negativos de estas barras simples para no representarlos
      // engañosamente como positivos; siguen apareciendo en la tabla detallada.
      final Map<String, List<Map<String, dynamic>>> porUnidad = {};
      for (final m in numericas) {
        final valor = _num(m['value']);
        if (valor == null || valor < 0) continue;
        porUnidad.putIfAbsent(_normUnidad(m['unit'].toString()), () => []).add(m);
      }
      final grupos = porUnidad.entries.where((e) => e.value.length >= 2).toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      for (final e in grupos.take(2)) {
        final items = [...e.value]
          ..sort((a, b) => (_num(b['value']) ?? 0).compareTo(_num(a['value']) ?? 0));
        w.add(_tarjetaSeccion(
          widget.esModoAnalitico
              ? 'Comparativa de indicadores · ${_tituloUnidad(e.key)}'
              : _tituloUnidad(e.key),
          _barrasHorizontales(items.take(6).toList(), e.key),
        ));
      }
    }

    // 6) Informacion adicional
    if (textoNarrativa.isNotEmpty) {
      w.add(_tarjetaSeccion(
        widget.esModoAnalitico ? 'Diagnostico completo' : 'Informacion adicional',
        Text(
          textoNarrativa.replaceAll('**', ''),
          style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF334155)),
        ),
      ));
    }

    if (metricas.isEmpty && graficosSeccion.isEmpty) {
      w.add(_tarjetaSeccion(
        'Indicadores de esta sección',
        const Text(
          'No se han identificado métricas asociadas a esta sección en el JSON recibido. '
          'Podemos ajustar la selección cuando revisemos un ejemplo de la respuesta de la API.',
          style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF64748B)),
        ),
      ));
    }

    if (metricas.isNotEmpty) {
      if (widget.esModoAnalitico) {
        w.add(_tarjetaSeccion(
          'Indicadores clave',
          _listaIndicadores(metricas, conPeriodo: true),
        ));
      } else {
        w.add(Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                'Ver todos los indicadores (${metricas.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              children: [_listaIndicadores(metricas, conPeriodo: false)],
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: w,
    );
  }

  Widget _construirContenidoVisual() {
    return _tarjetaSeccion(
      'Datos pendientes de Sherpas',
      const Text(
        'Este perfil no contiene todavía métricas estructuradas para construir gráficos. '
        'Cuando la API devuelva los indicadores en el JSON, se representarán automáticamente aquí.',
        style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _construirContenidoAnalitico() {
    return _tarjetaSeccion(
      'Informe detallado no disponible',
      const Text(
        'No se han recibido datos estructurados suficientes para generar este informe. '
        'No se mostrarán cifras de ejemplo para evitar confundirlas con datos reales del cliente.',
        style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
      ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Scrollbar(
            controller: _scrollHistograma,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollHistograma,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: datos.map((d) {
                    final Map data = d as Map;
                    final double valor = data['valor'] as double;
                    double altura = (valor / maxValor) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('\$${(valor / 1000).toInt()}k',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            width: 36,
                            height: altura,
                            decoration: BoxDecoration(
                              color: data['color'] as Color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(data['label'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
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
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        value: 1.0, strokeWidth: 24, color: (segmentos[0] as Map)['color'] as Color),
                    CircularProgressIndicator(
                        value: 0.56, strokeWidth: 24, color: (segmentos[1] as Map)['color'] as Color),
                    CircularProgressIndicator(
                        value: 0.29, strokeWidth: 24, color: (segmentos[2] as Map)['color'] as Color),
                    CircularProgressIndicator(
                        value: 0.10, strokeWidth: 24, color: (segmentos[3] as Map)['color'] as Color),
                    const Center(child: Icon(Icons.account_balance_wallet, color: Colors.grey, size: 28)),
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
                          decoration: BoxDecoration(color: sec['color'] as Color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(sec['label'] as String, style: const TextStyle(fontSize: 13)),
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

  Widget _graficoHaveVsNeed(String t1, double v1, String t2, double v2, Color colorActual) {
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
              Text(t1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('\$${(v1 / 1000).toInt()}k', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(width: double.infinity, height: 24, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t2, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('\$${(v2 / 1000).toInt()}k',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorActual)),
            ],
          ),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: (v2 / v1) > 1.0 ? 1.0 : (v2 / v1),
            child: Container(height: 24, color: colorActual),
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
            Text(titulo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _RangeIndicatorPainter extends CustomPainter {
  final double actual;
  final double minimo;
  final double maximo;
  final double escala;

  _RangeIndicatorPainter(this.actual, this.minimo, this.maximo, this.escala);

  @override
  void paint(Canvas canvas, Size size) {
    final inicio = 8.0;
    final fin = size.width - 8.0;
    final y = size.height / 2;
    final ancho = fin - inicio;
    double x(double v) => inicio + (v / escala).clamp(0.0, 1.0).toDouble() * ancho;

    final base = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(inicio, y), Offset(fin, y), base);

    final rango = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x(minimo), y), Offset(x(maximo), y), rango);

    final marcador = Paint()..color = const Color(0xFFEA580C);
    canvas.drawCircle(Offset(x(actual), y), 8, marcador);
    final borde = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(x(actual), y), 8, borde);
  }

  @override
  bool shouldRepaint(covariant _RangeIndicatorPainter oldDelegate) =>
      oldDelegate.actual != actual || oldDelegate.minimo != minimo ||
      oldDelegate.maximo != maximo || oldDelegate.escala != escala;
}

class _DonutDistribucionPainter extends CustomPainter {
  final List<double> valores;
  final List<Color> colores;

  _DonutDistribucionPainter(this.valores, this.colores);

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final total = valores.fold<double>(0, (s, v) => s + (v > 0 ? v : 0));
    if (total <= 0) return;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide * 0.39,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.16
      ..strokeCap = StrokeCap.butt;
    var inicio = -math.pi / 2;
    for (var i = 0; i < valores.length; i++) {
      final v = valores[i] > 0 ? valores[i] : 0;
      if (v == 0) continue;
      final barrido = 2 * math.pi * v / total;
      paint.color = colores[i % colores.length];
      canvas.drawArc(rect, inicio, barrido, false, paint);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutDistribucionPainter oldDelegate) =>
      oldDelegate.valores != valores || oldDelegate.colores != colores;
}

class GraficoJubilacionPainter extends CustomPainter {
  final double touchX;
  GraficoJubilacionPainter(this.touchX);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.1, size.width, size.height * 0.2);
    canvas.drawPath(path, paintLine);

    final paintTouch = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(touchX, 0), Offset(touchX, size.height), paintTouch);
    canvas.drawCircle(Offset(touchX, size.height * 0.4), 4.0, paintTouch);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TabObjetivosInteractivos extends StatefulWidget {
  final String userId;
  final String baseUrl;
  final Map clienteData;

  const TabObjetivosInteractivos({
    super.key,
    required this.userId,
    required this.baseUrl,
    required this.clienteData,
  });

  @override
  State<TabObjetivosInteractivos> createState() =>
      _TabObjetivosInteractivosState();
}

class _TabObjetivosInteractivosState extends State<TabObjetivosInteractivos> {
  late List listaObjetivos;

  @override
  void initState() {
    super.initState();
    final rawObjs = (widget.clienteData['objetivos'] as List?) ?? [];
    listaObjetivos = rawObjs.map((e) => Map.from(e as Map)).toList();
  }

  Future<void> _cambiarEstadoObjetivo(int index, bool nuevoCompletado) async {
    final obj = listaObjetivos[index] as Map;
    final int? objId = obj['id'] as int?;

    setState(() {
      obj['completado'] = nuevoCompletado;
    });

    if (objId == null) return;

    try {
      final resp = await http.patch(
        Uri.parse("${widget.baseUrl}/api/objetivos/$objId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"completado": nuevoCompletado}),
      );
      if (resp.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoCompletado
                  ? 'Tarea completada y guardada en BD'
                  : 'Tarea marcada como pendiente',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: nuevoCompletado ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final resumen = (widget.clienteData['resumen_ui'] as Map?) ?? {};
    final List topMoves = (resumen['top_moves'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Plan de Accion Prioritario (Checklist)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Marca con un check al completar cada paso. El progreso se guarda en tiempo real en SQLite.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (listaObjetivos.isEmpty)
          const Text('No hay tareas pendientes para esta familia.', style: TextStyle(color: Colors.grey))
        else
          ...List.generate(listaObjetivos.length, (index) {
            final obj = listaObjetivos[index] as Map;
            final bool completado = obj['completado'] == true || obj['completado'] == 1;
            final String titulo = (obj['titulo'] ?? 'Objetivo').toString();
            final String frecuencia = (obj['frecuencia'] ?? 'Prioritario').toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: completado ? Colors.green : Colors.grey.shade300,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              frecuencia.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: completado ? TextDecoration.lineThrough : null,
                              color: completado ? Colors.grey : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: completado ? Colors.green : Colors.grey.shade300,
                        size: 32,
                      ),
                      onPressed: () => _cambiarEstadoObjetivo(index, !completado),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (topMoves.isNotEmpty) ...[
          const Divider(height: 40),
          const Text(
            'Impacto Estimado en Puntuacion (Sherpas)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          ...topMoves.map((m) {
            final move = m as Map;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${move['title']} (${move['score_before']} → ${move['score_after']} pts)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text((move['action'] ?? '').toString(),
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class TabChatbot extends StatefulWidget {
  final String userId;
  final String nombreCliente;
  final String baseUrl;

  const TabChatbot({
    super.key,
    required this.userId,
    required this.nombreCliente,
    required this.baseUrl,
  });

  @override
  State<TabChatbot> createState() => _TabChatbotState();
}

class _TabChatbotState extends State<TabChatbot> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _cargando = false;
  late List mensajesChat;

  @override
  void initState() {
    super.initState();
    mensajesChat = [
      {
        "emisor": "bot",
        "texto":
            "¡Hola ${widget.nombreCliente}! Ya tengo cargado vuestro diagnostico financiero completo de Sherpas. ¿Que aspecto de vuestro plan quereis revisar hoy?",
      },
    ];
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final textoUsuario = _chatController.text.trim();
    if (textoUsuario.isEmpty || _cargando) return;

    setState(() {
      mensajesChat.add({"emisor": "usuario", "texto": textoUsuario});
      _cargando = true;
    });
    _chatController.clear();
    _scrollAlFinal();

    try {
      final response = await http
          .post(
            Uri.parse("${widget.baseUrl}/api/chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "user_id": widget.userId,
              "mensaje": textoUsuario,
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        final respuestaBot =
            (data["respuesta"] ?? "No se recibio respuesta del asesor.")
                .toString();
        setState(() {
          mensajesChat.add({"emisor": "bot", "texto": respuestaBot});
        });
      } else {
        setState(() {
          mensajesChat.add({
            "emisor": "bot",
            "texto":
                "Error del servidor (${response.statusCode}): ${response.body}",
          });
        });
      }
    } catch (e) {
      setState(() {
        mensajesChat.add({
          "emisor": "bot",
          "texto":
              "No pude conectar con el servidor en ${widget.baseUrl}. Asegurate de tener Uvicorn activo.",
        });
      });
    } finally {
      setState(() => _cargando = false);
      _scrollAlFinal();
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: mensajesChat.length + (_cargando ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == mensajesChat.length && _cargando) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analizando vuestro plan...',
                            style: TextStyle(color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                );
              }

              final msg = mensajesChat[index] as Map;
              final esBot = msg['emisor'] == 'bot';
              return Align(
                alignment: esBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: 12,
                    right: esBot ? 40 : 0,
                    left: esBot ? 0 : 40,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: esBot ? Colors.white : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: esBot ? Border.all(color: Colors.grey.shade300) : null,
                  ),
                  child: Text(
                    msg['texto'].toString(),
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
          child: TextField(
            controller: _chatController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _enviarMensaje(),
            decoration: InputDecoration(
              hintText: 'Escribe tu pregunta...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF0F172A)),
                onPressed: _cargando ? null : _enviarMensaje,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}