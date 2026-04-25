// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.dark,
    systemNavigationBarColor: AppColors.surface,
  ));
  runApp(const HybridCropNetApp());
}

class HybridCropNetApp extends StatelessWidget {
  const HybridCropNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                  'HybridCropNet',
      debugShowCheckedModeBanner: false,
      theme:                  AppTheme.light,
      home:                   const SplashScreen(),
    );
  }
}

// ── Main shell with bottom navigation ──────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(Icons.home_rounded,        Icons.home_outlined,       'Home'),
    _NavItem(Icons.eco_rounded,         Icons.eco_outlined,        'My Plants'),
    _NavItem(Icons.document_scanner_rounded, Icons.document_scanner_outlined, 'Scan'),
    _NavItem(Icons.bar_chart_rounded,   Icons.bar_chart_outlined,  'Analytics'),
    _NavItem(Icons.person_rounded,      Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _placeholder('Home'),
          _placeholder('My Plants'),
          _placeholder('Scan'),
          _placeholder('Analytics'),
          _placeholder('Profile'),
        ],
      ),
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: _currentIndex,
        items:        _items,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _placeholder(String label) =>
      Center(child: Text(label));
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String   label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ── Premium floating nav bar ────────────────────────────────────
class _PremiumNavBar extends StatelessWidget {
  final int            currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset:    const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final idx     = e.key;
              final item    = e.value;
              final active  = idx == currentIndex;
              final isScan  = idx == 2;
              return GestureDetector(
                onTap: () => onTap(idx),
                child: isScan
                    ? _ScanButton(active: active)
                    : _NavBarItem(
                        icon:       active ? item.activeIcon : item.icon,
                        label:      item.label,
                        isActive:   active),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isActive;
  const _NavBarItem({
      required this.icon,
      required this.label,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding:  const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size:  22,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textHint),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize:   10,
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textHint,
              )),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool active;
  const _ScanButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    AppShadow.green,
      ),
      child: const Icon(
          Icons.document_scanner_rounded,
          color: Colors.white, size: 26),
    );
  }
}
