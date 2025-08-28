import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../settings/presentation/widgets/mcp_health_status_widget.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../providers/agent_provider.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/models/agent.dart';

/// Widget for real agent loading and preview in the chat sidebar
class AgentLoaderSection extends ConsumerStatefulWidget {
 const AgentLoaderSection({super.key});

 @override
 ConsumerState<AgentLoaderSection> createState() => _AgentLoaderSectionState();
}

class _AgentLoaderSectionState extends ConsumerState<AgentLoaderSection> {
 bool _isExpanded = true;
 String? _loadingAgentId;
 String? _previousConversationId;
 
 @override
 void didChangeDependencies() {
 super.didChangeDependencies();
 
 // Check if conversation selection changed
 final currentConversationId = ref.read(selectedConversationIdProvider);
 if (_previousConversationId != currentConversationId) {
 // Clear manual agent selection when switching conversations
 if (currentConversationId != null) {
 WidgetsBinding.instance.addPostFrameCallback((_) {
 if (mounted) {
 ref.read(selectedAgentPreviewProvider.notifier).state = null;
 }
 });
 }
 _previousConversationId = currentConversationId;
 }
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final selectedConversationId = ref.watch(selectedConversationIdProvider);
 final selectedAgentId = ref.watch(selectedAgentPreviewProvider);
 final loadedAgentIds = ref.watch(loadedAgentIdsProvider);
 
 // Get current conversation to determine active agent
 final currentConversation = selectedConversationId != null 
 ? ref.watch(conversationProvider(selectedConversationId)).when(
 data: (conversation) => conversation,
 loading: () => null,
 error: (_, __) => null,
 )
 : null;
 
 // Watch agents from the real provider
 final agentsAsync = ref.watch(agentsProvider);
 
 return agentsAsync.when(
   data: (agents) => _buildAgentSection(
     context, theme, agents, currentConversation, selectedConversationId, selectedAgentId, loadedAgentIds
   ),
   loading: () => _buildLoadingSection(theme),
   error: (error, stack) => _buildErrorSection(theme, error),
 );
 }

 Widget _buildAgentSection(
   BuildContext context,
   ThemeData theme, 
   List<Agent> agents,
   Conversation? currentConversation,
   String? selectedConversationId,
   String? selectedAgentId,
   Set<String> loadedAgentIds,
 ) {
   // Determine which agent should be shown based on current conversation
   String? effectiveAgentId;
   if (currentConversation?.metadata?['type'] == 'agent') {
     effectiveAgentId = currentConversation?.metadata?['agentId'] as String?;
   } else {
     effectiveAgentId = selectedAgentId;
   }
   
   final selectedAgent = effectiveAgentId != null 
     ? agents.firstWhere((agent) => agent.id == effectiveAgentId, 
       orElse: () => agents.isNotEmpty ? agents.first : _createEmptyAgent())
     : null;
 
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 20),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         // Section Header
         Row(
           children: [
             Icon(
               Icons.smart_toy,
               size: 16,
               color: theme.colorScheme.onSurfaceVariant,
             ),
             SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               currentConversation?.metadata?['type'] == 'agent' 
                 ? 'Active Agent'
                 : 'Agent Preview',
               style: TextStyle(
                 fontFamily: 'Space Grotesk',
                 fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: currentConversation?.metadata?['type'] == 'agent'
                   ? ThemeColors(context).primary
                   : theme.colorScheme.onSurfaceVariant,
               ),
             ),
             Spacer(),
             IconButton(
               onPressed: () => setState(() => _isExpanded = !_isExpanded),
               icon: Icon(
                 _isExpanded ? Icons.expand_less : Icons.expand_more,
                 size: 16,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
               style: IconButton.styleFrom(
                 foregroundColor: theme.colorScheme.onSurfaceVariant,
                 minimumSize: Size(24, 24),
                 padding: EdgeInsets.zero,
               ),
             ),
           ],
         ),
         
         if (_isExpanded) ...[
           SizedBox(height: 12),
           
           // Agent Selection Dropdown
           if (agents.isNotEmpty) _buildAgentDropdown(context, theme, agents, effectiveAgentId, currentConversation),
           
           // Show current conversation context if applicable
           if (currentConversation?.metadata?['type'] == 'agent') ...[
             SizedBox(height: 12),
             _buildCurrentAgentInfo(theme),
           ],
           
           if (selectedAgent != null) ...[
             SizedBox(height: 16),
             
             // Agent Details
             _buildAgentDetails(selectedAgent, theme, currentConversation, loadedAgentIds),
             
             SizedBox(height: 12),
             
             // Quick Actions
             _buildQuickActions(context, theme, currentConversation),
           ] else if (agents.isEmpty) ...[
             SizedBox(height: 16),
             _buildNoAgentsState(context, theme),
           ],
         ],
       ],
     ),
   );
 }

 Widget _buildAgentDropdown(BuildContext context, ThemeData theme, List<Agent> agents, String? effectiveAgentId, Conversation? currentConversation) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
     decoration: BoxDecoration(
       border: Border.all(color: theme.colorScheme.outline),
       borderRadius: BorderRadius.circular(6),
       color: theme.colorScheme.surface.withValues(alpha: 0.8),
     ),
     child: DropdownButtonHideUnderline(
       child: DropdownButton<String>(
         value: effectiveAgentId,
         hint: Text(
           currentConversation?.metadata?['type'] == 'agent' 
             ? 'Current conversation agent'
             : 'Select agent to load',
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 12,
             color: theme.colorScheme.onSurfaceVariant,
           ),
         ),
         isExpanded: true,
         icon: Icon(
           Icons.keyboard_arrow_down,
           size: 16,
           color: theme.colorScheme.onSurfaceVariant,
         ),
         items: agents.map((agent) {
           return DropdownMenuItem<String>(
             value: agent.id,
             child: Row(
               children: [
                 Container(
                   width: 6,
                   height: 6,
                   decoration: BoxDecoration(
                     color: agent.status == AgentStatus.idle 
                       ? ThemeColors(context).success 
                       : theme.colorScheme.onSurfaceVariant,
                     shape: BoxShape.circle,
                   ),
                 ),
                 SizedBox(width: 8),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         agent.name,
                         style: TextStyle(
                           fontFamily: 'Space Grotesk',
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                           color: theme.colorScheme.onSurface,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                       Text(
                         agent.description,
                         style: TextStyle(
                           fontFamily: 'Space Grotesk',
                           fontSize: 10,
                           color: theme.colorScheme.onSurfaceVariant,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           );
         }).toList(),
         onChanged: (value) {
           // Only allow changing if not viewing an agent conversation
           if (currentConversation?.metadata?['type'] != 'agent') {
             ref.read(selectedAgentPreviewProvider.notifier).state = value;
           }
         },
       ),
     ),
   );
 }

 Widget _buildCurrentAgentInfo(ThemeData theme) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.all(10),
     decoration: BoxDecoration(
       color: ThemeColors(context).primary.withValues(alpha: 0.1),
       borderRadius: BorderRadius.circular(6),
       border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
     ),
     child: Row(
       children: [
         Icon(
           Icons.info_outline,
           size: 14,
           color: ThemeColors(context).primary,
         ),
         SizedBox(width: 8),
         Expanded(
           child: Text(
             'Viewing agent from current conversation',
             style: TextStyle(
               fontFamily: 'Space Grotesk',
               fontSize: 11,
               color: ThemeColors(context).primary,
               fontWeight: FontWeight.w500,
             ),
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildAgentDetails(Agent agent, ThemeData theme, Conversation? currentConversation, Set<String> loadedAgentIds) {
   final isLoading = _loadingAgentId == agent.id;
   final isLoaded = loadedAgentIds.contains(agent.id) || 
     (currentConversation?.metadata?['agentId'] == agent.id);

   return Column(
     children: [
       // Agent Info Card
       Container(
         width: double.infinity,
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: theme.colorScheme.surface.withValues(alpha: 0.8),
           borderRadius: BorderRadius.circular(6),
           border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               agent.name,
               style: TextStyle(
                 fontFamily: 'Space Grotesk',
                 fontSize: 14,
                 fontWeight: FontWeight.w600,
                 color: theme.colorScheme.onSurface,
               ),
             ),
             SizedBox(height: 4),
             Text(
               agent.description,
               style: TextStyle(
                 fontFamily: 'Space Grotesk',
                 fontSize: 12,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
             SizedBox(height: 8),
             Wrap(
               spacing: 4,
               children: [
                 _buildCapabilityChip('${agent.capabilities.length} Tools', Icons.extension, Colors.green, theme),
                 _buildCapabilityChip('Ready', Icons.circle, 
                   agent.status == AgentStatus.idle ? Colors.green : Colors.orange, theme),
               ],
             ),
           ],
         ),
       ),
       
       SizedBox(height: 12),
       
       // Load Button
       if (currentConversation?.metadata?['type'] != 'agent') 
         _buildLoadAgentButton(agent, theme, isLoading, isLoaded)
       else
         _buildCurrentlyActiveButton(theme),
     ],
   );
 }

 Widget _buildLoadAgentButton(Agent agent, ThemeData theme, bool isLoading, bool isLoaded) {
   if (isLoaded) {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: ThemeColors(context).success.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: ThemeColors(context).success.withValues(alpha: 0.3)),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.check_circle, size: 18, color: ThemeColors(context).success),
           SizedBox(width: 8),
           Text(
             'Agent Loaded',
             style: TextStyle(
               fontFamily: 'Space Grotesk',
               fontSize: 13,
               fontWeight: FontWeight.w600,
               color: ThemeColors(context).success,
             ),
           ),
         ],
       ),
     );
   }
   
   if (isLoading) {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: ThemeColors(context).primary.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           SizedBox(
             width: 18,
             height: 18,
             child: CircularProgressIndicator(
               strokeWidth: 2,
               valueColor: AlwaysStoppedAnimation<Color>(ThemeColors(context).primary),
             ),
           ),
           SizedBox(width: 12),
           Text(
             'Loading Agent...',
             style: TextStyle(
               fontFamily: 'Space Grotesk',
               fontSize: 13,
               fontWeight: FontWeight.w600,
               color: ThemeColors(context).primary,
             ),
           ),
         ],
       ),
     );
   }
   
   return AsmblButton.primary(
     text: 'Load Agent',
     onPressed: () => _loadAgent(agent),
     icon: Icons.psychology,
   );
 }

 Widget _buildCurrentlyActiveButton(ThemeData theme) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
     decoration: BoxDecoration(
       color: ThemeColors(context).primary.withValues(alpha: 0.1),
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
     ),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         Icon(Icons.chat, size: 18, color: ThemeColors(context).primary),
         SizedBox(width: 8),
         Text(
           'Currently Active',
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 13,
             fontWeight: FontWeight.w600,
             color: ThemeColors(context).primary,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildCapabilityChip(String text, IconData icon, Color color, ThemeData theme) {
   return Container(
     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
     decoration: BoxDecoration(
       color: color.withValues(alpha: 0.1),
       borderRadius: BorderRadius.circular(12),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(icon, size: 12, color: color),
         SizedBox(width: 4),
         Text(
           text,
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 10,
             fontWeight: FontWeight.w500,
             color: color,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildQuickActions(BuildContext context, ThemeData theme, Conversation? currentConversation) {
   if (currentConversation?.metadata?['type'] == 'agent') {
     return Row(
       children: [
         Expanded(
           child: GestureDetector(
             onTap: () {
               ref.read(selectedAgentPreviewProvider.notifier).state = null;
               ref.read(selectedConversationIdProvider.notifier).state = null;
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: ThemeColors(context).primary),
                 borderRadius: BorderRadius.circular(6),
                 color: ThemeColors(context).primary.withValues(alpha: 0.1),
               ),
               child: Center(
                 child: Text(
                   'Switch Agent',
                   style: TextStyle(
                     fontFamily: 'Space Grotesk',
                     fontSize: 11,
                     color: ThemeColors(context).primary,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ),
           ),
         ),
         SizedBox(width: 8),
         Expanded(
           child: GestureDetector(
             onTap: () => context.go(AppRoutes.agents),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: theme.colorScheme.outline),
                 borderRadius: BorderRadius.circular(6),
                 color: theme.colorScheme.surface.withValues(alpha: 0.8),
               ),
               child: Center(
                 child: Text(
                   'My Agents',
                   style: TextStyle(
                     fontFamily: 'Space Grotesk',
                     fontSize: 11,
                     color: theme.colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
             ),
           ),
         ),
       ],
     );
   } else {
     return Row(
       children: [
         Expanded(
           child: GestureDetector(
             onTap: () => context.go(AppRoutes.agents),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: theme.colorScheme.outline),
                 borderRadius: BorderRadius.circular(6),
                 color: theme.colorScheme.surface.withValues(alpha: 0.8),
               ),
               child: Center(
                 child: Text(
                   'My Agents',
                   style: TextStyle(
                     fontFamily: 'Space Grotesk',
                     fontSize: 11,
                     color: theme.colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
             ),
           ),
         ),
         SizedBox(width: 8),
         Expanded(
           child: GestureDetector(
             onTap: () => context.go(AppRoutes.wizard),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: theme.colorScheme.outline),
                 borderRadius: BorderRadius.circular(6),
                 color: theme.colorScheme.surface.withValues(alpha: 0.8),
               ),
               child: Center(
                 child: Text(
                   'Create New',
                   style: TextStyle(
                     fontFamily: 'Space Grotesk',
                     fontSize: 11,
                     color: theme.colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
             ),
           ),
         ),
       ],
     );
   }
 }

 Widget _buildNoAgentsState(BuildContext context, ThemeData theme) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: theme.colorScheme.surface.withValues(alpha: 0.5),
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
     ),
     child: Column(
       children: [
         Icon(
           Icons.smart_toy_outlined,
           size: 32,
           color: theme.colorScheme.onSurfaceVariant,
         ),
         SizedBox(height: 8),
         Text(
           'No agents available',
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 14,
             fontWeight: FontWeight.w600,
             color: theme.colorScheme.onSurface,
           ),
         ),
         SizedBox(width: 4),
         Text(
           'Create your first agent to get started',
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 12,
             color: theme.colorScheme.onSurfaceVariant,
           ),
           textAlign: TextAlign.center,
         ),
         SizedBox(height: 12),
         AsmblButton.primary(
           text: 'Create Agent',
           onPressed: () => context.go(AppRoutes.wizard),
         ),
       ],
     ),
   );
 }

 Widget _buildLoadingSection(ThemeData theme) {
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 20),
     child: Column(
       children: [
         Row(
           children: [
             Icon(Icons.smart_toy, size: 16, color: theme.colorScheme.onSurfaceVariant),
             SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               'Loading Agents...',
               style: TextStyle(
                 fontFamily: 'Space Grotesk',
                 fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
           ],
         ),
         SizedBox(height: 12),
         Center(
           child: CircularProgressIndicator(
             color: ThemeColors(context).primary,
             strokeWidth: 2,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildErrorSection(ThemeData theme, Object error) {
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 20),
     child: Column(
       children: [
         Row(
           children: [
             Icon(Icons.error_outline, size: 16, color: ThemeColors(context).error),
             SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               'Error Loading Agents',
               style: TextStyle(
                 fontFamily: 'Space Grotesk',
                 fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: ThemeColors(context).error,
               ),
             ),
           ],
         ),
         SizedBox(height: 8),
         Text(
           error.toString(),
           style: TextStyle(
             fontFamily: 'Space Grotesk',
             fontSize: 11,
             color: theme.colorScheme.onSurfaceVariant,
           ),
         ),
       ],
     ),
   );
 }

 Agent _createEmptyAgent() {
   return Agent(
     id: 'empty',
     name: 'No Agent Selected',
     description: 'Select an agent from the dropdown above',
     capabilities: [],
     configuration: {},
     status: AgentStatus.idle,
   );
 }

 void _loadAgent(Agent agent) async {
   setState(() {
     _loadingAgentId = agent.id;
   });
   
   try {
     // Add some loading delay for UX
     await Future.delayed(Duration(milliseconds: 1000));
     
     // Create new conversation with agent configuration
     final createAgentConversation = ref.read(createAgentConversationProvider);
     
     // Convert agent configuration to expected format
     final mcpServers = (agent.configuration['mcpServers'] as List<dynamic>?)
         ?.map((server) => server.toString())
         .toList() ?? [];
     
     final conversation = await createAgentConversation(
       agentId: agent.id,
       agentName: agent.name,
       systemPrompt: agent.configuration['systemPrompt']?.toString() ?? 
         'You are a helpful AI assistant named ${agent.name}. ${agent.description}',
       apiProvider: agent.configuration['model']?.toString() ?? 'Claude 3.5 Sonnet',
       mcpServers: mcpServers,
       mcpServerConfigs: {}, // Will be populated from settings
       contextDocuments: [], // Can be added later
     );
     
     // Switch to the new agent conversation
     ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
     
     // Refresh conversations list
     ref.invalidate(conversationsProvider);
     
     // Update global loaded agents state
     ref.read(loadedAgentIdsProvider.notifier).update((state) => {...state, agent.id});
     
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               Icon(Icons.auto_awesome, color: Colors.white, size: 16),
               SizedBox(width: 8),
               Text(
                 '${agent.name} is now active!',
                 style: TextStyle(fontFamily: 'Space Grotesk'),
               ),
             ],
           ),
           backgroundColor: ThemeColors(context).success,
           behavior: SnackBarBehavior.floating,
         ),
       );
     }
     
   } catch (e) {
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(
             'Failed to load agent: $e',
             style: TextStyle(fontFamily: 'Space Grotesk'),
           ),
           backgroundColor: ThemeColors(context).error,
           behavior: SnackBarBehavior.floating,
         ),
       );
     }
   } finally {
     if (mounted) {
       setState(() {
         _loadingAgentId = null;
       });
     }
   }
 }
}