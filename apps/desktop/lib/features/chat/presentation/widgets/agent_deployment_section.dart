import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../providers/agent_provider.dart';
import '../../../../core/services/model_config_service.dart';
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
             const SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               currentConversation?.metadata?['type'] == 'agent' 
                 ? 'Active Agent'
                 : 'Agent Preview',
               style: GoogleFonts.fustat(
                                  fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: currentConversation?.metadata?['type'] == 'agent'
                   ? ThemeColors(context).primary
                   : theme.colorScheme.onSurfaceVariant,
               ),
             ),
             const Spacer(),
             IconButton(
               onPressed: () => setState(() => _isExpanded = !_isExpanded),
               icon: Icon(
                 _isExpanded ? Icons.expand_less : Icons.expand_more,
                 size: 16,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
               style: IconButton.styleFrom(
                 foregroundColor: theme.colorScheme.onSurfaceVariant,
                 minimumSize: const Size(24, 24),
                 padding: EdgeInsets.zero,
               ),
             ),
           ],
         ),
         
         if (_isExpanded) ...[
           const SizedBox(height: SpacingTokens.componentSpacing),
           
           // Agent Selection Dropdown
           if (agents.isNotEmpty) _buildAgentDropdown(context, theme, agents, effectiveAgentId, currentConversation),
           
           // Show current conversation context if applicable
           if (currentConversation?.metadata?['type'] == 'agent') ...[
             const SizedBox(height: SpacingTokens.componentSpacing),
             _buildCurrentAgentInfo(theme),
           ],
           
           if (selectedAgent != null) ...[
             const SizedBox(height: SpacingTokens.componentSpacing),
             
             // Agent Details
             _buildAgentDetails(selectedAgent, theme, currentConversation, loadedAgentIds),
             
             const SizedBox(height: SpacingTokens.componentSpacing),
             
             // Quick Actions
             _buildQuickActions(context, theme, currentConversation),
           ] else if (agents.isEmpty) ...[
             const SizedBox(height: SpacingTokens.componentSpacing),
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
       color: theme.colorScheme.surface.withOpacity(0.8),
     ),
     child: DropdownButtonHideUnderline(
       child: DropdownButton<String>(
         value: effectiveAgentId,
         hint: Text(
           currentConversation?.metadata?['type'] == 'agent' 
             ? 'Current conversation agent'
             : 'Select agent to load',
           style: GoogleFonts.fustat(
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
                 const SizedBox(width: 8),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         agent.name,
                         style: GoogleFonts.fustat(
                                                      fontSize: 12,
                           fontWeight: FontWeight.w500,
                           color: theme.colorScheme.onSurface,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                       Text(
                         agent.description,
                         style: GoogleFonts.fustat(
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
       color: ThemeColors(context).primary.withOpacity(0.1),
       borderRadius: BorderRadius.circular(6),
       border: Border.all(color: ThemeColors(context).primary.withOpacity(0.3)),
     ),
     child: Row(
       children: [
         Icon(
           Icons.info_outline,
           size: 14,
           color: ThemeColors(context).primary,
         ),
         const SizedBox(width: 8),
         Expanded(
           child: Text(
             'Viewing agent from current conversation',
             style: GoogleFonts.fustat(
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
           color: theme.colorScheme.surface.withOpacity(0.8),
           borderRadius: BorderRadius.circular(6),
           border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               agent.name,
               style: GoogleFonts.fustat(
                                  fontSize: 14,
                 fontWeight: FontWeight.w600,
                 color: theme.colorScheme.onSurface,
               ),
             ),
             const SizedBox(height: 4),
             Text(
               agent.description,
               style: GoogleFonts.fustat(
                                  fontSize: 12,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
             const SizedBox(height: 8),
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
       
       const SizedBox(height: SpacingTokens.componentSpacing),
       
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
         color: ThemeColors(context).success.withOpacity(0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: ThemeColors(context).success.withOpacity(0.3)),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.check_circle, size: 18, color: ThemeColors(context).success),
           const SizedBox(width: 8),
           Text(
             'Agent Loaded',
             style: GoogleFonts.fustat(
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
         color: ThemeColors(context).primary.withOpacity(0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: ThemeColors(context).primary.withOpacity(0.3)),
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
           const SizedBox(width: 12),
           Text(
             'Loading Agent...',
             style: GoogleFonts.fustat(
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
       color: ThemeColors(context).primary.withOpacity(0.1),
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: ThemeColors(context).primary.withOpacity(0.3)),
     ),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         Icon(Icons.chat, size: 18, color: ThemeColors(context).primary),
         const SizedBox(width: 8),
         Text(
           'Currently Active',
           style: GoogleFonts.fustat(
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
     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
     decoration: BoxDecoration(
       color: color.withOpacity(0.1),
       borderRadius: BorderRadius.circular(12),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(icon, size: 12, color: color),
         const SizedBox(width: 4),
         Text(
           text,
           style: GoogleFonts.fustat(
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
                 color: ThemeColors(context).primary.withOpacity(0.1),
               ),
               child: Center(
                 child: Text(
                   'Switch Agent',
                   style: GoogleFonts.fustat(
                                          fontSize: 11,
                     color: ThemeColors(context).primary,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ),
           ),
         ),
         const SizedBox(width: 8),
         Expanded(
           child: GestureDetector(
             onTap: () => context.go(AppRoutes.agents),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: theme.colorScheme.outline),
                 borderRadius: BorderRadius.circular(6),
                 color: theme.colorScheme.surface.withOpacity(0.8),
               ),
               child: Center(
                 child: Text(
                   'My Agents',
                   style: GoogleFonts.fustat(
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
                 color: theme.colorScheme.surface.withOpacity(0.8),
               ),
               child: Center(
                 child: Text(
                   'My Agents',
                   style: GoogleFonts.fustat(
                                          fontSize: 11,
                     color: theme.colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
             ),
           ),
         ),
         const SizedBox(width: 8),
         Expanded(
           child: GestureDetector(
             onTap: () => context.go(AppRoutes.wizard),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: theme.colorScheme.outline),
                 borderRadius: BorderRadius.circular(6),
                 color: theme.colorScheme.surface.withOpacity(0.8),
               ),
               child: Center(
                 child: Text(
                   'Create New',
                   style: GoogleFonts.fustat(
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
       color: theme.colorScheme.surface.withOpacity(0.5),
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
     ),
     child: Column(
       children: [
         Icon(
           Icons.smart_toy_outlined,
           size: 32,
           color: theme.colorScheme.onSurfaceVariant,
         ),
         const SizedBox(height: 8),
         Text(
           'No agents available',
           style: GoogleFonts.fustat(
                          fontSize: 14,
             fontWeight: FontWeight.w600,
             color: theme.colorScheme.onSurface,
           ),
         ),
         const SizedBox(width: 4),
         Text(
           'Create your first agent to get started',
           style: GoogleFonts.fustat(
                          fontSize: 12,
             color: theme.colorScheme.onSurfaceVariant,
           ),
           textAlign: TextAlign.center,
         ),
         const SizedBox(height: SpacingTokens.componentSpacing),
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
             const SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               'Loading Agents...',
               style: GoogleFonts.fustat(
                                  fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
           ],
         ),
         const SizedBox(height: SpacingTokens.componentSpacing),
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
             const SizedBox(width: SpacingTokens.iconSpacing),
             Text(
               'Error Loading Agents',
               style: GoogleFonts.fustat(
                                  fontSize: 13,
                 fontWeight: FontWeight.w500,
                 color: ThemeColors(context).error,
               ),
             ),
           ],
         ),
         const SizedBox(height: 8),
         Text(
           error.toString(),
           style: GoogleFonts.fustat(
                          fontSize: 11,
             color: theme.colorScheme.onSurfaceVariant,
           ),
         ),
       ],
     ),
   );
 }

 Agent _createEmptyAgent() {
   return const Agent(
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
     await Future.delayed(const Duration(milliseconds: 1000));
     
     // Debug: Print agent configuration type
     print('Agent configuration type: ${agent.configuration.runtimeType}');
     print('Agent configuration: ${agent.configuration}');
     
     // Create new conversation with agent configuration
     final createAgentConversation = ref.read(createAgentConversationProvider);
     
     // Convert agent configuration to expected format
     final mcpServersRaw = agent.configuration['mcpServers'];
     final mcpServers = <String>[];
     if (mcpServersRaw is List) {
       for (final server in mcpServersRaw) {
         mcpServers.add(server.toString());
       }
     }
     
     // Get the current selected model or default model for the agent conversation
     final defaultModel = ref.read(defaultModelConfigProvider);
     final modelProvider = defaultModel?.name ?? 'Local Model';
     
     final conversation = await createAgentConversation(
       agentId: agent.id,
       agentName: agent.name,
       systemPrompt: agent.configuration['systemPrompt']?.toString() ?? 
         'You are a helpful AI assistant named ${agent.name}. ${agent.description}',
       apiProvider: modelProvider,
       mcpServers: mcpServers,
       mcpServerConfigs: <String, dynamic>{}, // Will be populated from settings
       contextDocuments: <String>[], // Can be added later
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
               const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
               const SizedBox(width: 8),
               Text(
                 '${agent.name} is now active!',
                 style: GoogleFonts.fustat(),
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
             style: GoogleFonts.fustat(),
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