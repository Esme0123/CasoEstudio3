import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/gradient_background.dart';
import 'analyze_screen.dart';
import 'history_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

/// Contenedor principal con navegación inferior personalizada.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _pages = const [
    AnalyzeScreen(),
    HistoryScreen(),
    InfoScreen(),
    SettingsScreen(),
  ];

  final _items = const [
    (_NavItem(Icons.radar_rounded, 'Analizar')),
    (_NavItem(Icons.history_rounded, 'Historial')),
    (_NavItem(Icons.science_rounded, 'Modelos')),
    (_NavItem(Icons.tune_rounded, 'Ajustes')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _BottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.items,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _BarButton(
                item: items[i],
                selected: i == index,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 23,
              color: selected ? AppColors.primary : AppColors.textLow,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textLow,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
