import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/client_provider.dart';
import '../domain/models.dart';
import 'package:intl/intl.dart';
import '../../vendors/domain/vendor_provider.dart';

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

  bool get _isFiltered => _selectedVendor != 'All' || _financingFilter != FinancingFilter.all;

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
      final matchesSearch = client.name.toLowerCase().contains(query) ||
                            client.consumerNumber.toLowerCase().contains(query) ||
                            client.phone.contains(query) ||
                            (client.npApplicationNumber?.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;

      if (_selectedVendor != 'All' && client.vendorName != _selectedVendor) return false;

      if (_financingFilter == FinancingFilter.loan && !client.isLoan) return false;
      if (_financingFilter == FinancingFilter.self && client.isLoan) return false;

      return true;
    }).toList();

    switch (_sortOption) {
      case ClientSortOption.newest:
        filteredClients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ClientSortOption.name:
        filteredClients.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ClientSortOption.size:
        filteredClients.sort((a, b) => b.systemSizeKwp.compareTo(a.systemSizeKwp));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Client Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                onPressed: _showSortFilterBottomSheet,
              ),
              if (_isFiltered || _sortOption != ClientSortOption.newest)
                Positioned(
                  right: 8, top: 8,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search Name, ID, Phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }, icon: const Icon(Icons.clear_rounded))
                  : null,
              ),
            ),
          ),

          if (_isFiltered)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_selectedVendor != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(_selectedVendor.contains('Ronak') ? 'Ronak' : _selectedVendor),
                        onDeleted: () => setState(() => _selectedVendor = 'All'),
                      ),
                    ),
                  if (_financingFilter != FinancingFilter.all)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(_financingFilter == FinancingFilter.loan ? 'Bank Loan' : 'Self-Funded'),
                        onDeleted: () => setState(() => _financingFilter = FinancingFilter.all),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() { _selectedVendor = 'All'; _financingFilter = FinancingFilter.all; }),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sort & Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                SegmentedButton<ClientSortOption>(
                  segments: const [
                    ButtonSegment(value: ClientSortOption.newest, label: Text('Newest'), icon: Icon(Icons.history_rounded)),
                    ButtonSegment(value: ClientSortOption.name, label: Text('A-Z'), icon: Icon(Icons.sort_by_alpha_rounded)),
                    ButtonSegment(value: ClientSortOption.size, label: Text('Size'), icon: Icon(Icons.solar_power_rounded)),
                  ],
                  selected: {_sortOption},
                  onSelectionChanged: (set) => setState(() {
                    _sortOption = set.first;
                    setModalState(() {});
                  }),
                ),

                const SizedBox(height: 32),
                const Text('Vendor Partner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final vendors = ref.watch(vendorPartnerProvider);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('All'), 
                          selected: _selectedVendor == 'All',
                          onSelected: (s) { if (s) setState(() { _selectedVendor = 'All'; setModalState((){}); }); },
                        ),
                        ...vendors.map((v) => ChoiceChip(
                          label: Text(v.name.contains('Ronak') ? 'Ronak' : v.name), 
                          selected: _selectedVendor == v.name,
                          onSelected: (s) { if (s) setState(() { _selectedVendor = v.name; setModalState((){}); }); },
                        )),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text('Financing Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'), 
                      selected: _financingFilter == FinancingFilter.all,
                      onSelected: (s) { if (s) setState(() { _financingFilter = FinancingFilter.all; setModalState((){}); }); },
                    ),
                    ChoiceChip(
                      label: const Text('Bank Loan'), 
                      selected: _financingFilter == FinancingFilter.loan,
                      onSelected: (s) { if (s) setState(() { _financingFilter = FinancingFilter.loan; setModalState((){}); }); },
                    ),
                    ChoiceChip(
                      label: const Text('Self-Funded'), 
                      selected: _financingFilter == FinancingFilter.self,
                      onSelected: (s) { if (s) setState(() { _financingFilter = FinancingFilter.self; setModalState((){}); }); },
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: const Text('APPLY FILTERS'),
                ),
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
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No clients yet" : "No matching clients",
            style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Client> clients) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ClientCard(client: clients[index]),
    );
  }

  Widget _buildGrid(List<Client> clients) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 180,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: clients.length,
      itemBuilder: (context, index) => ClientCard(client: clients[index]),
    );
  }
}

class ClientCard extends ConsumerWidget {
  final Client client;
  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGenesis = client.vendorName == 'Genesis';

    return Card(
      child: InkWell(
        onTap: () => context.push('/client/${client.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${client.consumerNumber}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildVendorBadge(client, isGenesis),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.solar_power_rounded, '${client.systemSizeKwp} kW'),
                  Text(
                    DateFormat('MMM dd, yyyy').format(client.createdAt),
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorBadge(Client client, bool isGenesis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGenesis ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isGenesis ? 'Genesis' : client.vendorName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isGenesis ? Colors.blue.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade400),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
