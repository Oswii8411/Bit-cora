import 'dart:typed_data';

import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Genera los reportes en PDF. Solo usa caracteres Latin-1 (la tipografía
/// estándar de PDF no incluye símbolos como "–" o "·").
class ReportService {
  final DatabaseHelper db = DatabaseHelper();

  static const _teal = PdfColor.fromInt(0xFF1E3A8A);
  static const _dark = PdfColor.fromInt(0xFF0F1F4D);
  static const _soft = PdfColor.fromInt(0xFFDCE8FF);

  // ---------------------------------------------------------------- API
  Future<void> infraestructura(NetworkGroup net) async {
    final switches = await db.getSwitchesByNetwork(net.id);
    final vlans = await db.getSubnetsByNetwork(net.id);
    final allPorts = await db.getAllPorts();
    final devices = await db.getDevices();
    final vlanIds = vlans.map((v) => v.id).toSet();
    final nDevices = devices.where((d) => vlanIds.contains(d.subnetId)).length;

    final rows = <List<String>>[];
    var totalPorts = 0, okPorts = 0;
    for (final sw in switches) {
      final p = allPorts.where((x) => x.switchId == sw.id).toList();
      final ok = p.where((x) => x.operativo).length;
      totalPorts += p.length;
      okPorts += ok;
      rows.add([sw.name, sw.model, sw.ip, sw.location, sw.estado, '${p.length}', '$ok']);
    }

    final doc = _newDoc();
    doc.addPage(_page('Reporte de infraestructura - ${net.name}', [
      _kv({
        'Edificio': net.name,
        'IP base': net.baseIp,
        'Ubicacion': net.ubicacion.isEmpty ? '-' : net.ubicacion,
        'Estado': net.estado,
        'Switches': '${switches.length}',
        'Puertos totales / operativos': '$totalPorts / $okPorts',
        'VLAN registradas': '${vlans.length}',
        'Equipos registrados': '$nDevices',
      }),
      pw.SizedBox(height: 16),
      _subtitle('Switches'),
      _table(['Nombre', 'Modelo', 'IP', 'Ubicacion', 'Estado', 'Puertos', 'Operativos'], rows),
      pw.SizedBox(height: 16),
      _subtitle('VLAN'),
      _table(
        ['VLAN', 'Nombre', 'Red', 'Rango', 'Estado'],
        vlans
            .map((v) => ['${v.vlanNumber ?? '-'}', v.name, '${v.baseIp}/${v.mask}', '${v.ipStart} - ${v.ipEnd}', v.estado])
            .toList(),
      ),
    ]));
    await _share(doc, 'Infraestructura ${net.name}', 'Reporte de infraestructura de "${net.name}"');
  }

  Future<void> bitacora({DateTimeRange? range}) async {
    var logs = await db.getHistoryLogs(limit: 2000);
    if (range != null) {
      final end = range.end.add(const Duration(days: 1));
      logs = logs.where((l) => l.createdAt != null && !l.createdAt!.isBefore(range.start) && l.createdAt!.isBefore(end)).toList();
    }
    final f = DateFormat('dd/MM/yyyy HH:mm');
    final doc = _newDoc();
    doc.addPage(_page(
      'Reporte de bitacora',
      [
        if (range != null)
          pw.Text('Periodo: ${DateFormat('dd/MM/yyyy').format(range.start)} al ${DateFormat('dd/MM/yyyy').format(range.end)}'),
        pw.Text('Movimientos: ${logs.length}'),
        pw.SizedBox(height: 10),
        _table(
          ['Fecha', 'Usuario', 'Modulo', 'Accion', 'Descripcion'],
          logs
              .map((l) => [
                    l.createdAt != null ? f.format(l.createdAt!) : '',
                    l.userLabel,
                    kModulosBitacora[l.entityType] ?? l.entityType,
                    l.actionType,
                    l.description,
                  ])
              .toList(),
          widths: {0: 80, 1: 100, 2: 60, 3: 50},
        ),
      ],
    ));
    await _share(doc, 'Bitacora', 'Reporte de bitácora');
  }

  Future<void> incidencias() async {
    final list = await db.getIncidencias();
    final f = DateFormat('dd/MM/yyyy');
    final doc = _newDoc();
    doc.addPage(_page('Reporte de incidencias', [
      pw.Text('Total: ${list.length}   Pendientes: ${list.where((i) => i.estado == 'Pendiente').length}   '
          'Resueltas: ${list.where((i) => i.estado == 'Resuelto').length}'),
      pw.SizedBox(height: 10),
      _table(
        ['Fecha', 'Equipo', 'Prioridad', 'Estado', 'Falla', 'Solucion / accion', 'Reporto', 'Resolvio'],
        list
            .map((i) => [
                  i.createdAt != null ? f.format(i.createdAt!) : '',
                  i.dispositivoNombre,
                  i.prioridad,
                  i.estado,
                  i.descripcion,
                  i.solucion.isNotEmpty ? i.solucion : i.accionRealizada,
                  i.responsable,
                  i.resuelta
                      ? '${i.resueltoPor ?? '-'}${i.resueltoEn != null ? ' (${f.format(i.resueltoEn!)})' : ''}'
                      : '-',
                ])
            .toList(),
      ),
    ]));
    await _share(doc, 'Incidencias', 'Reporte de incidencias');
  }

  Future<void> usuarios() async {
    final users = await db.getProfiles();
    final doc = _newDoc();
    doc.addPage(_page('Reporte de usuarios', [
      pw.Text('Total: ${users.length}   Activos: ${users.where((u) => u.isActive).length}   '
          'Pendientes: ${users.where((u) => u.isPending).length}'),
      pw.SizedBox(height: 10),
      _table(
        ['Nombre', 'Correo', 'Rol', 'Estado', 'Departamento', 'Cargo'],
        users.map((u) => [u.fullName, u.email, u.roleLabel, u.estado, u.departamento, u.cargo]).toList(),
      ),
    ]));
    await _share(doc, 'Usuarios', 'Reporte de usuarios');
  }

  /// Segmentación de red: todas las VLAN, o solo las de [net].
  Future<void> segmentacion({NetworkGroup? net}) async {
    final networks = await db.getNetworks();
    final vlans = net == null ? await db.getSubnets() : await db.getSubnetsByNetwork(net.id);
    String nameOf(String id) => networks.where((n) => n.id == id).map((n) => n.name).firstOrNull ?? '-';

    final doc = _newDoc();
    doc.addPage(_page(
      net == null ? 'Reporte de segmentacion de red' : 'Segmentacion de red - ${net.name}',
      [
        pw.Text('VLAN registradas: ${vlans.length}'),
        pw.SizedBox(height: 10),
        _table(
          ['Edificio', 'VLAN', 'Nombre', 'Red', 'Mascara', 'Ruteador', 'Rango', 'Broadcast', 'Hosts', 'Estado'],
          vlans
              .map((v) => [
                    nameOf(v.networkId),
                    '${v.vlanNumber ?? '-'}',
                    v.name,
                    v.baseIp,
                    v.mask,
                    v.gateway,
                    '${v.ipStart} - ${v.ipEnd}${v.excluded.isNotEmpty ? ' (excl. ${v.excluded})' : ''}',
                    v.broadcast,
                    '${v.hosts ?? '-'}',
                    v.estado,
                  ])
              .toList(),
          fontSize: 7.5,
        ),
      ],
      landscape: true,
    ));
    await _share(doc, 'Segmentacion', 'Reporte de segmentación de red');
  }

  // ---------------------------------------------------------------- helpers
  pw.Document _newDoc() => pw.Document(title: 'Bitacora de Red', author: AppSession.profile?.fullName ?? 'Bitacora de Red');

  pw.Page _page(String title, List<pw.Widget> body, {bool landscape = false}) {
    final generado = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final por = AppSession.profile?.fullName ?? '';
    return pw.MultiPage(
      pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _teal, width: 1.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Bitacora de Red', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _teal, fontSize: 11)),
            pw.Text('Generado: $generado   Por: $por', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ),
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
        pw.SizedBox(height: 12),
        ...body,
      ],
    ) as pw.Page;
  }

  pw.Widget _subtitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _teal)),
      );

  pw.Widget _kv(Map<String, String> data) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(
          children: [
            for (final e in data.entries)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 170, child: pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              ),
          ],
        ),
      );

  pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Map<int, double>? widths,
    double fontSize = 8.5,
  }) {
    if (rows.isEmpty) {
      return pw.Text('Sin registros.', style: const pw.TextStyle(color: PdfColors.grey700));
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: fontSize),
      headerDecoration: const pw.BoxDecoration(color: _teal),
      cellStyle: pw.TextStyle(fontSize: fontSize),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F7FC)),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: widths == null ? null : {for (final e in widths.entries) e.key: pw.FixedColumnWidth(e.value)},
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  Future<void> _share(pw.Document doc, String filename, String logText) async {
    final Uint8List bytes = await doc.save();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await db.logEvent('GENERAR', 'REPORTE', 'Generó el $logText');
    await Printing.sharePdf(bytes: bytes, filename: '${filename.replaceAll(' ', '_')}_$stamp.pdf');
  }
}
