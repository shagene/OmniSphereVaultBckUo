import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/password_entry.dart';
import 'bottom_nav.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';
import 'categories_screen.dart';
import 'widgets/search_bar_widget.dart';
import 'utils/keyboard_shortcuts.dart';
import 'utils/clipboard_manager.dart';
import 'dialogs/edit_password_dialog.dart';

class PasswordVaultScreen extends StatefulWidget {
  const PasswordVaultScreen({super.key});

  @override
  State<PasswordVaultScreen> createState() => _PasswordVaultScreenState();
}

class _PasswordVaultScreenState extends State<PasswordVaultScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CategoryItem? _selectedCategory;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, bool> _passwordVisibility = {}; // Track visibility per entry
  final _clipboardManager = ClipboardManager();

  // Temporary data - will be replaced with actual database data
  final List<PasswordEntry> _passwords = [
    PasswordEntry(
      title: 'Google Account',
      username: 'johndoe',
      email: 'john.doe@gmail.com',
      password: 'encrypted_password_1',
      url: 'https://accounts.google.com',
      notes: 'Personal Gmail account and Google services',
      lastModified: DateTime.now(),
      category: 'Email',
      tags: ['personal', 'important'],
      lastUsed: DateTime.now(),
      passwordLastChanged: DateTime.now().subtract(const Duration(days: 30)),
      isFavorite: true,
    ),
    PasswordEntry(
      title: 'GitHub',
      username: 'johndoe',
      email: 'john.doe@gmail.com',
      password: 'encrypted_password_2',
      url: 'https://github.com',
      notes: 'Professional GitHub account for work projects',
      lastModified: DateTime.now().subtract(const Duration(days: 7)),
      category: 'Development',
      tags: ['work', 'development'],
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
      passwordLastChanged: DateTime.now().subtract(const Duration(days: 90)),
      isFavorite: true,
    ),
    PasswordEntry(
      title: 'Netflix',
      email: 'john.doe@gmail.com',
      password: 'encrypted_password_3',
      url: 'https://netflix.com',
      notes: 'Family Netflix subscription',
      lastModified: DateTime.now().subtract(const Duration(days: 14)),
      category: 'Entertainment',
      tags: ['streaming', 'personal'],
      lastUsed: DateTime.now().subtract(const Duration(days: 2)),
      passwordLastChanged: DateTime.now().subtract(const Duration(days: 45)),
      isFavorite: false,
    ),
    PasswordEntry(
      title: 'Bank Account',
      username: '12345678',
      password: 'encrypted_password_4',
      url: 'https://mybank.com',
      notes: 'Personal checking account',
      lastModified: DateTime.now().subtract(const Duration(days: 21)),
      category: 'Banking',
      tags: ['finance', 'important'],
      lastUsed: DateTime.now().subtract(const Duration(days: 3)),
      passwordLastChanged: DateTime.now().subtract(const Duration(days: 15)),
      isFavorite: true,
    ),
    PasswordEntry(
      title: 'Twitter',
      username: '@johndoe',
      password: 'encrypted_password_5',
      url: 'https://twitter.com',
      lastModified: DateTime.now().subtract(const Duration(days: 30)),
      category: 'Social Media',
      tags: ['social', 'personal'],
      lastUsed: DateTime.now().subtract(const Duration(days: 5)),
      passwordLastChanged: DateTime.now().subtract(const Duration(days: 60)),
      isFavorite: false,
    ),
  ];

  List<PasswordEntry> get filteredPasswords {
    return _passwords.where((password) {
      final matchesSearch = password.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (password.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (password.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (password.url?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (password.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategory == null || password.category == _selectedCategory!.name;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _focusSearchBar();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          // TODO: Add new password
        },
        const SingleActivator(LogicalKeyboardKey.keyG, control: true): () {
          setState(() => _currentIndex = 2);
        },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
          setState(() => _currentIndex = 1);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _clearFilters();
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('OmniSphereVault'),
          ),
          drawer: _buildDrawer(context),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    final PasswordEntry? newEntry = await Navigator.push<PasswordEntry>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordGeneratorScreen(),
                      ),
                    );
                    
                    if (newEntry != null && mounted) {
                      setState(() {
                        _passwords.add(newEntry);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password entry saved successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return Column(
          children: [
            _buildSearchBar(),
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Chip(
                  label: Text(_selectedCategory!.name),
                  onDeleted: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
              ),
            Expanded(
              child: _buildPasswordList(context),
            ),
          ],
        );
      case 1:
        return CategoriesScreen(
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _currentIndex = 0; // Switch back to password list
            });
          },
        );
      case 2:
        return const PasswordGeneratorScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildPasswordList(context);
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OmniSphereVault',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Secure Password Manager',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.primary),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.primary),
            title: const Text('About'),
            onTap: () {
              // Show about dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordList(BuildContext context) {
    if (filteredPasswords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No passwords found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 88, // Added extra padding at bottom to account for FAB
      ),
      itemCount: filteredPasswords.length,
      itemBuilder: (context, index) {
        final password = filteredPasswords[index];
        return _buildPasswordCard(
          context,
          password,
        );
      },
    );
  }

  Widget _buildPasswordCard(BuildContext context, PasswordEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Initialize visibility state for this entry if not exists
    _passwordVisibility.putIfAbsent(entry.title, () => false);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: textTheme.titleMedium,
                  ),
                ),
                if (entry.isFavorite)
                  Icon(
                    Icons.star,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.category,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.url != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _copyToClipboard(entry.url!, 'URL'),
                    child: Row(
                      children: [
                        Icon(Icons.link,
                            size: 16,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.url!,
                            style: textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy,
                              size: 20,
                              color: colorScheme.primary),
                          onPressed: () => _copyToClipboard(entry.url!, 'URL'),
                          tooltip: 'Copy URL',
                        ),
                        IconButton(
                          icon: Icon(Icons.open_in_new,
                              size: 20,
                              color: colorScheme.primary),
                          onPressed: () {
                            // TODO: Implement URL launch
                          },
                          tooltip: 'Open URL',
                        ),
                      ],
                    ),
                  ),
                ],
                if (entry.username != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(entry.username!, 'Username'),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.username!,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy,
                              size: 20,
                              color: colorScheme.primary),
                          onPressed: () =>
                              _copyToClipboard(entry.username!, 'Username'),
                          tooltip: 'Copy username',
                        ),
                      ],
                    ),
                  ),
                ],
                if (entry.email != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(entry.email!, 'Email'),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 16,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.email!,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy,
                              size: 20,
                              color: colorScheme.primary),
                          onPressed: () =>
                              _copyToClipboard(entry.email!, 'Email'),
                          tooltip: 'Copy email',
                        ),
                      ],
                    ),
                  ),
                ],
                // Password section with visibility toggle and copy button
                InkWell(
                  onTap: () => _copyToClipboard(entry.password, 'Password'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.password, 
                             size: 16, 
                             color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedCrossFade(
                                firstChild: Text(
                                  '••••••••',
                                  style: textTheme.bodyMedium,
                                ),
                                secondChild: Text(
                                  entry.password,
                                  style: textTheme.bodyMedium,
                                ),
                                crossFadeState: _passwordVisibility[entry.title] ?? false
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            (_passwordVisibility[entry.title] ?? false)
                                ? Icons.visibility_off 
                                : Icons.visibility,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisibility[entry.title] = !(_passwordVisibility[entry.title] ?? false);
                            });
                            // Auto-hide password after 30 seconds
                            if (_passwordVisibility[entry.title] ?? false) {
                              Future.delayed(const Duration(seconds: 30), () {
                                if (mounted) {
                                  setState(() {
                                    _passwordVisibility[entry.title] = false;
                                  });
                                }
                              });
                            }
                          },
                          tooltip: 'Show/hide password',
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, 
                                   size: 20, 
                                   color: colorScheme.primary),
                          onPressed: () => _copyToClipboard(entry.password, 'Password'),
                          tooltip: 'Copy password',
                        ),
                      ],
                    ),
                  ),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.note_outlined, 
                           size: 16, 
                           color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.notes!,
                          style: textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, 
                         size: 16, 
                         color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Modified: ${entry.lastModified.day}/${entry.lastModified.month}/${entry.lastModified.year}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: entry.tags.map((tag) => Chip(
                      label: Text(
                        tag,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: colorScheme.primary),
                onPressed: () async {
                  final updatedEntry = await Navigator.push<PasswordEntry>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordGeneratorScreen(
                        entryToEdit: entry,
                      ),
                    ),
                  );
                  
                  if (updatedEntry != null && mounted) {
                    setState(() {
                      final index = _passwords.indexWhere(
                        (e) => e.title == entry.title,
                      );
                      if (index != -1) {
                        _passwords[index] = updatedEntry;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password entry updated successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Edit entry',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchBarWidget(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
        },
        hintText: 'Search passwords...',
      ),
    );
  }

  void _focusSearchBar() {
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _copyToClipboard(String data, String type) async {
    final success = await _clipboardManager.copyToClipboard(
      data,
      type,
      timeout: const Duration(seconds: 30),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type copied to clipboard'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Clear',
              onPressed: () {
                _clipboardManager.clearClipboard();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clipboard cleared'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy $type'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _clipboardManager.dispose();
    _searchFocusNode.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
}