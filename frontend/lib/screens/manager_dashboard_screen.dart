import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/manager_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<ManagerProvider>(context, listen: false).fetchTeamStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final mgrProvider = Provider.of<ManagerProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manager Portal'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'M',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user?.fullName ?? 'Manager'}',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.jobTitle ?? 'Manager'} • ${user?.companyName ?? ''}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active Cycle: ${mgrProvider.activeCycle?['name'] ?? 'July 2026 Evaluation'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Primary Action Bar Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/manager/team'),
                      icon: const Icon(Icons.people_outline_rounded, size: 18),
                      label: const Text('My Direct Team'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/manager/submitted'),
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text('Submitted Reviews'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Compliance & Metrics Summary Section Header
              Text(
                'Monthly Evaluation Progress (Click cards to view details)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (mgrProvider.isLoadingTeam)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: LoadingWidget(message: 'Loading team evaluation status...'),
                  ),
                )
              else if (mgrProvider.errorTeam != null)
                CustomErrorWidget(
                  message: mgrProvider.errorTeam!,
                  onRetry: () => mgrProvider.fetchTeamStatus(),
                )
              else ...[
                // 4 Interactive Clickable Metric Analytics Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Direct Reports',
                        value: '${mgrProvider.totalReports}',
                        icon: Icons.groups_outlined,
                        color: AppTheme.primaryColor,
                        onTap: () => context.go('/manager/team'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Completed',
                        value: '${mgrProvider.completedCount}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.successColor,
                        onTap: () => context.go('/manager/submitted'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Pending',
                        value: '${mgrProvider.pendingCount}',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppTheme.warningColor,
                        onTap: () => context.go('/manager/team?filter=PENDING'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Completion Rate',
                        value: '${mgrProvider.completionPercentage.toStringAsFixed(0)}%',
                        icon: Icons.pie_chart_outline_rounded,
                        color: AppTheme.secondaryColor,
                        onTap: () => context.go('/manager/team'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // fl_chart Progress Visualization
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completion Overview Chart',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 160,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: AppTheme.successColor,
                                  value: mgrProvider.completedCount.toDouble(),
                                  title: '${mgrProvider.completedCount}',
                                  radius: 35,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  color: AppTheme.warningColor,
                                  value: mgrProvider.pendingCount.toDouble(),
                                  title: '${mgrProvider.pendingCount}',
                                  radius: 35,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Completed', AppTheme.successColor),
                            const SizedBox(width: 24),
                            _buildLegendItem('Pending', AppTheme.warningColor),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                  Row(
                    children: [
                      Text(
                        'View',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
