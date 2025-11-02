import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/home/home_screen.dart';
import '../screens/catalog/products_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/account/profile_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    const NavigationItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Products',
      route: '/products',
    ),
    const NavigationItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'Cart',
      route: '/cart',
    ),
    const NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Account',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ProductsScreen(),
          CartScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Consumer2<AuthProvider, CartProvider>(
        builder: (context, authProvider, cartProvider, child) {
          return _buildBottomNavigationBar(authProvider, cartProvider);
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(AuthProvider authProvider, CartProvider cartProvider) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppConfig.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      elevation: 8,
      items: _navigationItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // Add badge to cart item
        Widget icon = Icon(
          _currentIndex == index ? item.activeIcon : item.icon,
          size: 24,
        );

        if (item.route == '/cart' && cartProvider.itemCount > 0) {
          icon = Stack(
            children: [
              icon,
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartProvider.itemCount > 99 ? '99+' : cartProvider.itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }

        return BottomNavigationBarItem(
          icon: icon,
          label: item.label,
        );
      }).toList(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Handle navigation to specific screens if needed
    final item = _navigationItems[index];
    if (item.route != '/home') {
      context.push(item.route);
    }
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}