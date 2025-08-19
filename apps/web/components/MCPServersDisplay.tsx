'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Server, Database, Search, FileText, Code2, Code } from 'lucide-react'
import { 
  SiGithub, 
  SiFigma, 
  SiPostgresql,
  SiGit,
  SiBrave,
  SiMongodb,
  SiSlack,
  SiNotion,
  SiLinear,
  SiDiscord
} from 'react-icons/si'
import { getAgentById } from '@/lib/agentLibrary'

interface MCPServer {
  id: string
  name: string
  description: string
  status: 'connected' | 'disconnected' | 'error'
  icon: React.ComponentType<{ className?: string }>
}

interface Agent {
  id: string
  name: string
  mcpServers: MCPServer[]
}

const availableServers: MCPServer[] = [
  {
    id: 'filesystem',
    name: 'Filesystem',
    description: 'File operations and directory access',
    status: 'connected',
    icon: FileText
  },
  {
    id: 'git',
    name: 'Git',
    description: 'Repository management and version control',
    status: 'connected',
    icon: SiGit as any
  },
  {
    id: 'github',
    name: 'GitHub',
    description: 'Issues, PRs, and repository operations',
    status: 'disconnected',
    icon: SiGithub as any
  },
  {
    id: 'vscode',
    name: 'VSCode',
    description: 'Code editing and workspace control',
    status: 'connected',
    icon: Code
  },
  {
    id: 'postgresql',
    name: 'PostgreSQL',
    description: 'Database queries and schema operations',
    status: 'connected',
    icon: SiPostgresql as any
  },
  {
    id: 'search',
    name: 'Brave Search',
    description: 'Real-time web search capabilities',
    status: 'connected',
    icon: SiBrave as any
  },
  {
    id: 'figma',
    name: 'Figma',
    description: 'Design files and component access',
    status: 'error',
    icon: SiFigma as any
  }
]

const mockAgents: Agent[] = [
  {
    id: 'research',
    name: 'Research Assistant',
    mcpServers: availableServers.filter(s => ['filesystem', 'search', 'postgresql'].includes(s.id))
  },
  {
    id: 'code',
    name: 'Code Assistant',
    mcpServers: availableServers.filter(s => ['filesystem', 'git', 'github', 'vscode'].includes(s.id))
  },
  {
    id: 'default',
    name: 'General Assistant',
    mcpServers: availableServers.filter(s => ['filesystem', 'search'].includes(s.id))
  }
]

interface MCPServersDisplayProps {
  selectedAgentId: string
}

export function MCPServersDisplay({ selectedAgentId }: MCPServersDisplayProps) {
  // First try to get from the agent library
  const libraryAgent = getAgentById(selectedAgentId)
  let selectedAgent = null
  
  if (libraryAgent) {
    selectedAgent = {
      id: libraryAgent.id,
      name: libraryAgent.name,
      mcpServers: libraryAgent.mcpServers
    }
  } else {
    // Fall back to mock agents
    selectedAgent = mockAgents.find(agent => agent.id === selectedAgentId)
  }
  
  if (!selectedAgent) {
    return null
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'connected':
        return 'bg-green-500/20 text-green-400 border-green-500/30'
      case 'disconnected':
        return 'bg-gray-500/20 text-gray-400 border-gray-500/30'
      case 'error':
        return 'bg-red-500/20 text-red-400 border-red-500/30'
      default:
        return 'bg-gray-500/20 text-gray-400 border-gray-500/30'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'connected':
        return '🟢'
      case 'disconnected':
        return '⚫'
      case 'error':
        return '🔴'
      default:
        return '⚫'
    }
  }

  return (
    <Card className="mb-4">
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Server className="h-4 w-4" />
          MCP Servers
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {selectedAgent.mcpServers.map((server) => {
          const Icon = server.icon
          return (
            <div key={server.id} className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-2 flex-1 min-w-0">
                <Icon className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium truncate">{server.name}</div>
                  <div className="text-xs text-muted-foreground truncate">{server.description}</div>
                </div>
              </div>
              <Badge className={`text-xs ${getStatusColor(server.status)}`}>
                <span className="mr-1">{getStatusIcon(server.status)}</span>
                {server.status}
              </Badge>
            </div>
          )
        })}
        
        {selectedAgent.mcpServers.length === 0 && (
          <div className="text-sm text-muted-foreground text-center py-4">
            No MCP servers configured for this agent
          </div>
        )}
        
        <div className="pt-2 border-t border-border/50">
          <div className="text-xs text-muted-foreground">
            {selectedAgent.mcpServers.filter(s => s.status === 'connected').length} of {selectedAgent.mcpServers.length} servers active
          </div>
        </div>
      </CardContent>
    </Card>
  )
}