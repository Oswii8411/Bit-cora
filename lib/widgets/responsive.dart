import 'package:flutter/material.dart';

/// A partir de este ancho la app usa menú lateral y varias columnas
/// (navegador o tableta); por debajo, el diseño de celular.
const double kWideBreakpoint = 900;

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// Centra el contenido con un ancho máximo cómodo (formularios, ajustes).
class Centered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Centered({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// Reparte [children] en columnas según el ancho disponible (1 en celular,
/// 2 o 3 en pantallas anchas). No hace scroll por sí solo.
class ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final double minColumnWidth;
  final double spacing;
  const ResponsiveColumns({
    super.key,
    required this.children,
    this.minColumnWidth = 440,
    this.spacing = 14,
  });

  static int columnsFor(double width, double minColumnWidth, double spacing) {
    return ((width + spacing) / (minColumnWidth + spacing)).floor().clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = columnsFor(c.maxWidth, minColumnWidth, spacing);
        if (n == 1) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < n; col++) ...[
              if (col > 0) SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = col; i < children.length; i += n) children[i]],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Reemplazo directo de `ListView.builder`: en celular es la misma lista
/// (perezosa); en pantallas anchas reparte los elementos en columnas.
class ResponsiveList extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minColumnWidth;
  final double spacing;

  const ResponsiveList({
    super.key,
    this.padding = EdgeInsets.zero,
    required this.itemCount,
    required this.itemBuilder,
    this.minColumnWidth = 440,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final resolved = padding.resolve(Directionality.of(context));
        final available = c.maxWidth - resolved.horizontal;
        final n = ResponsiveColumns.columnsFor(available, minColumnWidth, spacing);
        if (n == 1) {
          return ListView.builder(padding: padding, itemCount: itemCount, itemBuilder: itemBuilder);
        }
        return ListView(
          padding: padding,
          children: [
            ResponsiveColumns(
              minColumnWidth: minColumnWidth,
              spacing: spacing,
              children: [for (var i = 0; i < itemCount; i++) itemBuilder(context, i)],
            ),
          ],
        );
      },
    );
  }
}
