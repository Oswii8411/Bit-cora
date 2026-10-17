import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/views/pantalla_bitacora.dart';
import 'package:bitacora_red/views/pantalla_edificios.dart';
import 'package:bitacora_red/views/pantalla_inicio.dart';
import 'package:bitacora_red/views/pantalla_mas.dart';
import 'package:bitacora_red/views/pantalla_red.dart';
import 'package:bitacora_red/views/pantalla_reportes.dart';
import 'package:bitacora_red/views/pantalla_usuarios.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:flutter/material.dart';

/// Opción del menú inferior.
class _MenuItem {
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _MenuItem(this.key, this.label, this.icon, this.selectedIcon);
}

/// Contenedor principal. Menú de 5 opciones para ambos roles:
///   Inicio · Edificios · Red (switches y VLAN) · Bitácora · Más
/// Usuarios y Reportes (solo administrador) están en "Más > Administración".
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  static const _items = [
    _MenuItem('inicio', 'Inicio', Icons.space_dashboard_outlined, Icons.space_dashboard),
    _MenuItem('edificios', 'Edificios', Icons.apartment_outlined, Icons.apartment),
    _MenuItem('red', 'Red', Icons.hub_outlined, Icons.hub),
    _MenuItem('bitacora', 'Bitácora', Icons.menu_book_outlined, Icons.menu_book),
    _MenuItem('mas', 'Más', Icons.more_horiz, Icons.more_horiz),
  ];

  int _currentIndex = 0;
  int _redTab = 0;

  /// Navegación desde cualquier pantalla (por ejemplo, desde el Inicio).
  void _goTo(String key) {
    switch (key) {
      case 'usuarios':
        if (AppSession.isAdmin) Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosScreen()));
      case 'reportes':
        if (AppSession.isAdmin) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen()));
      case 'switches':
      case 'vlan':
        setState(() {
          _currentIndex = _items.indexWhere((e) => e.key == 'red');
          _redTab = key == 'vlan' ? 1 : 0;
        });
      default:
        final i = _items.indexWhere((e) => e.key == key);
        if (i >= 0) setState(() => _currentIndex = i);
    }
  }

  Widget _screen(String key) => switch (key) {
        'inicio' => InicioScreen(onGoTo: _goTo),
        'edificios' => const BuildingsScreen(),
        'red' => RedScreen(initialTab: _redTab),
        'bitacora' => const BitacoraScreen(),
        _ => MasScreen(onGoTo: _goTo),
      };

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];
    // Se reconstruye al cambiar de pestaña para mostrar datos recientes.
    final screen = KeyedSubtree(key: ValueKey('${item.key}$_redTab'), child: _screen(item.key));

    if (isWide(context)) {
      // Navegador o tableta: menú lateral y contenido con ancho máximo.
      return Scaffold(
        body: Row(
          children: [
            _SideMenu(
              items: _items,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: screen),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: screen,
      bottomNavigationBar: _BottomMenu(
        items: _items,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Menú lateral (pantallas anchas).
class _SideMenu extends StatelessWidget {
  final List<_MenuItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _SideMenu({required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppSession.profile;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.palette5, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.router_outlined, color: AppColors.palette1, size: 21),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text('Bitácora de Red',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.15)),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < items.length; i++)
              _SideItem(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
            const Spacer(),
            if (p != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(p.fullName.substring(0, 1).toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(p.roleLabel, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SideItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(selected ? item.selectedIcon : item.icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 14.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.ink : AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menú inferior plano: la opción activa lleva una línea arriba y el color de énfasis.
class _BottomMenu extends StatelessWidget {
  final List<_MenuItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomMenu({required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _MenuButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _MenuButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selected ? 28 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? item.selectedIcon : item.icon, color: color, size: 23),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
