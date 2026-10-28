import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/database/app_database.dart';
import '../../core/database/gamification_queries.dart';
import '../../core/money.dart';
import '../dashboard/month_summary.dart';

/// La fuente estándar del PDF (Helvetica) solo cubre Latin-1: se reemplazan
/// los símbolos que no tiene (signo menos tipográfico, flechas, emojis).
String _pdfSafe(String s) => s
    .replaceAll('−', '-')
    .replaceAll('→', '->')
    .replaceAll('₡', 'CRC ')
    .replaceAll(RegExp(r'[^\u0000-ÿ]'), '');

const _brand = PdfColor.fromInt(0xFF6C4CF1);
const _income = PdfColor.fromInt(0xFF12B886);
const _expense = PdfColor.fromInt(0xFFFA5252);
const _muted = PdfColor.fromInt(0xFF868E96);

/// Genera el PDF del mes con resumen, categorías, presupuestos y movimientos.
Future<Uint8List> buildMonthReport({
  required AppDatabase db,
  required DateTime month,
  required String currency,
  required String userName,
}) async {
  final list = await db.watchMovements(MovementFilter.month(month)).first;
  final summary = MonthSummary.from(list, month);
  final budgets = await db.watchBudgets(month).first;
  String money(int c) => _pdfSafe(formatMoney(c, currency));
  final monthName = DateFormat('MMMM yyyy', 'es').format(month);
  final title = monthName[0].toUpperCase() + monthName.substring(1);

  pw.Widget stat(String label, int cents, PdfColor color) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.08),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: _muted, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            money(cents),
            style: pw.TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  final doc = pw.Document(title: 'PlataPets - $title', author: userName);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Row(
        children: [
          pw.Text(
            'PlataPets',
            style: pw.TextStyle(
              color: _brand,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Spacer(),
          pw.Text(_pdfSafe('Reporte de $title')),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          _pdfSafe(
            '${userName.isEmpty ? '' : '$userName · '}'
            'Página ${context.pageNumber} de ${context.pagesCount}',
          ),
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
      ),
      build: (context) => [
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            stat('Ingresos', summary.income, _income),
            stat('Gastos', summary.expense, _expense),
            stat('Neto', summary.net, summary.net >= 0 ? _income : _expense),
          ],
        ),
        pw.SizedBox(height: 20),
        if (summary.byCategory.isNotEmpty) ...[
          pw.Text(
            _pdfSafe('Gastos por categoría'),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          for (final c in summary.byCategory)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      _pdfSafe(c.category?.name ?? 'Sin categoría'),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.LayoutBuilder(
                          builder: (context, box) => pw.Container(
                            height: 8,
                            width:
                                (box?.maxWidth ?? 200) *
                                c.total /
                                (summary.expense == 0 ? 1 : summary.expense),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(
                                c.category?.colorValue ?? 0xFF868E96,
                              ),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text(
                      money(c.total),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 20),
        ],
        if (budgets.isNotEmpty) ...[
          pw.Text(
            'Presupuestos',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Presupuesto', 'Límite', 'Gastado', 'Estado'],
            data: [
              for (final b in budgets)
                [
                  _pdfSafe(b.categoryName ?? 'General'),
                  money(b.limit),
                  money(b.spent),
                  b.spent > b.limit
                      ? 'Excedido'
                      : '${(b.ratio * 100).round()}%',
                ],
            ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: _brand),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'Movimientos (${list.length})',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (list.isEmpty)
          pw.Text('Sin movimientos este mes.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Concepto', 'Cuenta', 'Monto'],
            data: [
              for (final d in list.reversed)
                [
                  DateFormat('dd/MM').format(d.movement.date),
                  _pdfSafe(
                    [
                      d.isTransfer ? 'Transferencia' : (d.category?.name ?? ''),
                      if (d.movement.note != null) d.movement.note!,
                    ].join(' - '),
                  ),
                  _pdfSafe(
                    d.isTransfer
                        ? '${d.account.name} -> ${d.toAccount?.name ?? ''}'
                        : d.account.name,
                  ),
                  d.isTransfer
                      ? money(d.movement.amount)
                      : _pdfSafe(formatSigned(d.signedAmount, currency)),
                ],
            ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: _brand),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {3: pw.Alignment.centerRight},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
      ],
    ),
  );
  return doc.save();
}
