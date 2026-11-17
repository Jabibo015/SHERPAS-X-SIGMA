import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  bool get _esCasoRealSherpas =>
      widget.clienteData['resumen_ui']?['pilares'] != null &&
      (widget.clienteData['resumen_ui']['pilares'] as List).isNotEmpty;

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
      children: List.generate(items.length, (i) {
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
    final int nSalud = todas.length;
    _extraerMetricas(resumen['metricas_inversion'], '', '', todas);

    List<Map<String, dynamic>> metricas = todas
        .where((m) => _coincideSeccion('${m['grupo']} ${m['clave']}'))
        .toList();
    if (metricas.isEmpty) {
      metricas = todas.where((m) => _coincideSeccion(m['label'].toString())).toList();
    }
    if (metricas.isEmpty) {
      final bool usaInversion = widget.titulo == 'Jubilacion' || widget.titulo == 'Patrimonio';
      metricas = (usaInversion && todas.length > nSalud)
          ? todas.sublist(nSalud)
          : todas.sublist(0, nSalud);
      if (metricas.isEmpty) metricas = todas;
    }

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

    if (!widget.esModoAnalitico) {
      // 3) Grafico de pilares de la seccion
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
              final String etiqueta =
                  puntos.isNotEmpty ? '${score.round()}/100 ($puntos)' : '${score.round()}/100';
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
                        Text(
                          etiqueta,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _colorScore(score),
                          ),
                        ),
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

      // 4) Tarjetas con los 4 indicadores principales
      final numericas = metricas.where((m) => _esNumerico(m['value'])).toList();
      if (numericas.isNotEmpty) {
        final double ancho = (MediaQuery.of(context).size.width - 40 - 12) / 2;
        w.add(Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: numericas.take(4).map((m) => _kpi(m, ancho)).toList(),
          ),
        ));

        // 5) Graficos de barras, uno por tipo de unidad
        final Map<String, List<Map<String, dynamic>>> porUnidad = {};
        for (final m in numericas) {
          porUnidad.putIfAbsent(_normUnidad(m['unit'].toString()), () => []).add(m);
        }
        final grupos = porUnidad.entries.where((e) => e.value.length >= 2).toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
        for (final e in grupos.take(2)) {
          w.add(_tarjetaSeccion(
            _tituloUnidad(e.key),
            _barrasHorizontales(e.value.take(6).toList(), e.key),
          ));
        }
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
            "Vuestra deuda es manejable en terminos generales: \$93,000 en total. El punto de maxima tension financiera es la tarjeta de credito Chase al 18%.",
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
            {"label": "Hipoteca (6%)", "valor": 50000.0, "color": const Color(0xFF0F172A)},
            {"label": "Tarjeta (18%)", "valor": 18000.0, "color": const Color(0xFFEA580C)},
            {"label": "Estudios (5%)", "valor": 15000.0, "color": const Color(0xFF64748B)},
            {"label": "Coche (4%)", "valor": 10000.0, "color": const Color(0xFF94A3B8)},
          ], 50000.0),
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
            "Ambos quereis jubilaros en 2048. Vuestros ingresos cubriran el 93% de las necesidades de gasto, y el dinero no se agotara antes de los 91 anos.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),
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
                  _touchX = details.localPosition.dx.clamp(0.0, 320.0);
                });
              },
              child: CustomPaint(
                painter: GraficoJubilacionPainter(_touchX),
                child: Container(),
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
          const SizedBox(height: 24),
          _graficoHaveVsNeed('Recomendado', 85000, 'Actual', 150801, Colors.green),
          const SizedBox(height: 24),
          _graficoHaveVsNeed('Recomendado Minimo', 750000, 'Cobertura Actual', 140000, Colors.red),
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
          "Patrimonio total de \$788,500 distribuido entre vivienda, inversiones y efectivo.",
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        "Reporte detallado de ${widget.titulo} para Timothy y Melanie: liquidez de \$150,801, deuda total de \$93,000 (tarjeta Chase de \$18,000 al 18%) y patrimonio neto de \$695,500.",
        style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155)),
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