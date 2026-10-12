import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/models/daree_pensum_uc.dart';
import 'package:uptmdigital_app/theme.dart';

class PensumScreen extends StatefulWidget {
  final int pnfId;
  final String? pnfNombre;
  final String? pnfColorHex;

  const PensumScreen({
    super.key,
    required this.pnfId,
    this.pnfNombre,
    this.pnfColorHex,
  });

  @override
  State<PensumScreen> createState() => _PensumScreenState();
}

class _PensumScreenState extends State<PensumScreen> {
  bool _isLoading = true;
  String? _error;
  String _pnfNombre = '';
  String _pnfCodigo = '';
  Color _accentColor = AppTheme.primary;
  List<DareePensumUc> _unidades = [];
  Map<String, String> _prelacionesMap = {}; // ucCodigo → requiereCodigo
  int _totalCreditos = 0;

  @override
  void initState() {
    super.initState();
    _pnfNombre = widget.pnfNombre ?? 'Cargando...';
    if (widget.pnfColorHex != null) {
      _accentColor = _parseColor(widget.pnfColorHex!);
    }
    _loadData();
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();

    try {
      // Load pensum and prelaciones in parallel
      final results = await Future.wait([
        api.getDareePensum(widget.pnfId),
        api.getDareePrelaciones(widget.pnfId),
      ]);

      final pensumData = results[0] as Map<String, dynamic>?;
      final prelacionesData = results[1] as List<dynamic>;

      if (pensumData == null) {
        if (mounted) {
          setState(() {
            _error = 'No se pudo cargar el pensum.';
            _isLoading = false;
          });
        }
        return;
      }

      // Parse PNF info
      final pnfInfo = pensumData['pnf'] as Map<String, dynamic>?;
      final ucList = pensumData['data'] as List<dynamic>? ?? [];

      // Parse prelaciones into map
      final prelMap = <String, String>{};
      for (var p in prelacionesData) {
        final ucCode = p['ucCodigo']?.toString() ?? '';
        final reqCode = p['requiereCodigo']?.toString() ?? '';
        if (ucCode.isNotEmpty && reqCode.isNotEmpty) {
          prelMap[ucCode] = reqCode;
        }
      }

      // Parse UCs
      final unidades = ucList.map((j) => DareePensumUc.fromJson(j)).toList();
      final totalCred = unidades.fold<int>(0, (sum, uc) => sum + uc.unidadesCredito);

      if (mounted) {
        setState(() {
          _pnfNombre = pnfInfo?['nombre'] ?? widget.pnfNombre ?? 'PNF';
          _pnfCodigo = pnfInfo?['codigo'] ?? '';
          _unidades = unidades;
          _prelacionesMap = prelMap;
          _totalCreditos = totalCred;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Groups UCs by trayecto, preserving insertion order
  Map<String, List<DareePensumUc>> _groupByTrayecto() {
    final map = <String, List<DareePensumUc>>{};
    for (var uc in _unidades) {
      map.putIfAbsent(uc.trayecto, () => []).add(uc);
    }
    return map;
  }

  /// Groups UCs within a trayecto by trimestre
  Map<String, List<DareePensumUc>> _groupByTrimestre(List<DareePensumUc> ucs) {
    final map = <String, List<DareePensumUc>>{};
    for (var uc in ucs) {
      map.putIfAbsent(uc.trimestre, () => []).add(uc);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar with gradient ───
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _accentColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Malla Curricular',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accentColor,
                      _accentColor.withValues(alpha: 0.7),
                      AppTheme.primary.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 16, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pnfNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Content ───
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ─── Summary Card ───
            SliverToBoxAdapter(child: _buildSummaryCard()),

            // ─── Trayectos ───
            SliverList(
              delegate: SliverChildListDelegate(
                _buildTrayectoTiles(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor.withValues(alpha: 0.1),
            _accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: _accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pnfNombre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: $_pnfCodigo',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_unidades.length}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _accentColor),
              ),
              Text('UCs', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_totalCreditos UC',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTrayectoTiles() {
    final trayectos = _groupByTrayecto();
    final tiles = <Widget>[];

    int trayectoIndex = 0;
    for (final entry in trayectos.entries) {
      final trayectoName = entry.key;
      final ucsInTrayecto = entry.value;
      final creditsTrayecto = ucsInTrayecto.fold<int>(0, (s, uc) => s + uc.unidadesCredito);
      final trimestres = _groupByTrimestre(ucsInTrayecto);

      tiles.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: trayectoIndex == 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${trayectoIndex + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              title: Text(
                trayectoName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                '${ucsInTrayecto.length} materias · $creditsTrayecto créditos',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              children: [
                const Divider(height: 1),
                for (final trimEntry in trimestres.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          trimEntry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...trimEntry.value.map((uc) => _buildUcCard(uc)),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
      trayectoIndex++;
    }

    return tiles;
  }

  Widget _buildUcCard(DareePensumUc uc) {
    final hasPrereq = _prelacionesMap.containsKey(uc.codigoUc);
    final prereqCode = _prelacionesMap[uc.codigoUc];
    final isElectiva = uc.tipoUc.toUpperCase() != 'REGULAR';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Code badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              uc.codigoUc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uc.nombreUc,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(Icons.star_outline, '${uc.unidadesCredito} UC'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.access_time, '${uc.horasAcademicas}h'),
                    if (isElectiva) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ELECTIVA',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasPrereq) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.link, size: 12, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Requiere: $prereqCode',
                        style: TextStyle(fontSize: 10, color: Colors.red[400], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
