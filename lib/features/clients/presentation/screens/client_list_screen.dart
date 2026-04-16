import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/core/utils/dialog_utils.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/providers/client_providers.dart';
import 'package:genesis_util/features/vendors/domain/providers/vendor_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum ClientSortOption { newest, name, size }

enum FinancingFilter { all, loan, self }

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  ClientSortOption _sortOption = ClientSortOption.newest;
  String _selectedVendor = 'All';
  FinancingFilter _financingFilter = FinancingFilter.all;

  bool get _isFiltered =>
      _selectedVendor != 'All' || _financingFilter != FinancingFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);

    final filteredClients = clients.where((client) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          client.name.toLowerCase().contains(query) ||
          client.consumerNumber.toLowerCase().contains(query) ||
          client.phone.contains(query) ||
          (client.npApplicationNumber?.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;

      if (_selectedVendor != 'All' && client.vendorName != _selectedVendor) {
        return false;
      }

      if (_financingFilter == FinancingFilter.loan && !client.isLoan) {
        return false;
      }
      if (_financingFilter == FinancingFilter.self && client.isLoan) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOption) {
      case ClientSortOption.newest:
        filteredClients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ClientSortOption.name:
        filteredClients.sort((a, b) => a.name.compareTo(b.name));
      case ClientSortOption.size:
        filteredClients.sort(
          (a, b) => b.systemSizeKwp.compareTo(a.systemSizeKwp),
        );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Client Directory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showSortFilterBottomSheet,
              ),
              if (_isFiltered || _sortOption != ClientSortOption.newest)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search Name, ID, Phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
              ),
            ),
          ),

          if (_isFiltered)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (_selectedVendor != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(_selectedVendor),
                        onDeleted: () =>
                            setState(() => _selectedVendor = 'All'),
                      ),
                    ),
                  if (_financingFilter != FinancingFilter.all)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(
                          _financingFilter == FinancingFilter.loan
                              ? 'Bank Loan'
                              : 'Self-Funded',
                        ),
                        onDeleted: () => setState(
                          () => _financingFilter = FinancingFilter.all,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedVendor = 'All';
                      _financingFilter = FinancingFilter.all;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: filteredClients.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return _buildGrid(filteredClients);
                      }
                      return _buildList(filteredClients);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-client'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Client'),
      ),
    );
  }

  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort & Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ClientSortOption>(
                  segments: const [
                    ButtonSegment(
                      value: ClientSortOption.newest,
                      label: Text('Newest'),
                      icon: Icon(Icons.history_rounded),
                    ),
                    ButtonSegment(
                      value: ClientSortOption.name,
                      label: Text('A-Z'),
                      icon: Icon(Icons.sort_by_alpha_rounded),
                    ),
                    ButtonSegment(
                      value: ClientSortOption.size,
                      label: Text('Size'),
                      icon: Icon(Icons.bolt_rounded),
                    ),
                  ],
                  selected: {_sortOption},
                  onSelectionChanged: (set) => setState(() {
                    _sortOption = set.first;
                    setModalState(() {});
                  }),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Assigned Vendor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final vendors = ref.watch(vendorsProvider);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Vendors'),
                          selected: _selectedVendor == 'All',
                          onSelected: (s) {
                            if (s) {
                              setState(() {
                                _selectedVendor = 'All';
                                setModalState(() {});
                              });
                            }
                          },
                        ),
                        ...vendors.map(
                          (v) => ChoiceChip(
                            label: Text(
                              v.name.contains('Ronak')
                                  ? 'Ronak (Default)'
                                  : v.name,
                            ),
                            selected: _selectedVendor == v.name,
                            onSelected: (s) {
                              if (s) {
                                setState(() {
                                  _selectedVendor = v.name;
                                  setModalState(() {});
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Text(
                  'Financing Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: _financingFilter == FinancingFilter.all,
                      onSelected: (s) {
                        if (s) {
                          setState(() {
                            _financingFilter = FinancingFilter.all;
                            setModalState(() {});
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Bank Loan'),
                      selected: _financingFilter == FinancingFilter.loan,
                      onSelected: (s) {
                        if (s) {
                          setState(() {
                            _financingFilter = FinancingFilter.loan;
                            setModalState(() {});
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Self-Funded'),
                      selected: _financingFilter == FinancingFilter.self,
                      onSelected: (s) {
                        if (s) {
                          setState(() {
                            _financingFilter = FinancingFilter.self;
                            setModalState(() {});
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Apply Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No clients yet' : 'No matching results',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Client> clients) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ClientCard(client: clients[index]),
    );
  }

  Widget _buildGrid(List<Client> clients) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 185,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: clients.length,
      itemBuilder: (context, index) => ClientCard(client: clients[index]),
    );
  }
}

class ClientCard extends ConsumerWidget {
  const ClientCard({required this.client, super.key});
  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGenesis =
        client.vendorName == 'Genesis' || client.vendorName == 'All';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/client/${client.id}'),
        onLongPress: () async {
          final confirmed = await DialogUtils.showDeleteConfirmation(
            context,
            title: 'Delete Client',
            message:
                'Are you sure you want to permanently delete ${client.name}?',
          );
          if (confirmed == true) {
            ref.read(documentsProvider.notifier).removeAllForClient(client.id);
            ref.read(clientsProvider.notifier).deleteClient(client.id);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${client.consumerNumber}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildVendorBadge(theme, client, isGenesis),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${client.systemSizeKwp} kWp',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(client.createdAt),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorBadge(ThemeData theme, Client client, bool isGenesis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGenesis
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isGenesis ? 'Genesis' : client.vendorName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isGenesis
              ? theme.colorScheme.primary
              : theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}
