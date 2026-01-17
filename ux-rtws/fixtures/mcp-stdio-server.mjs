import { McpServer } from '../../dominds/node_modules/@modelcontextprotocol/sdk/dist/esm/server/mcp.js';
import { StdioServerTransport } from '../../dominds/node_modules/@modelcontextprotocol/sdk/dist/esm/server/stdio.js';
import * as z from '../../dominds/node_modules/zod/v4/index.js';

const server = new McpServer({
  name: 'dominds-ux-stdio-server',
  version: '1.0.0',
});

server.registerTool(
  'greet',
  {
    description: 'A simple greeting tool (stdio test server)',
    inputSchema: {
      name: z.string().describe('Name to greet'),
    },
  },
  async ({ name }) => {
    return { content: [{ type: 'text', text: `Hello, ${name}!` }] };
  },
);

server.registerTool(
  'echo',
  {
    description: 'Echo text back (stdio test server)',
    inputSchema: {
      text: z.string().describe('Text to echo'),
    },
  },
  async ({ text }) => {
    return { content: [{ type: 'text', text }] };
  },
);

server.registerTool(
  'env_report',
  {
    description:
      'Report selected environment variables from the stdio MCP server process (testing only).',
    inputSchema: z.object({}),
  },
  async () => {
    const payload = {
      MCP_DIRECT: process.env.MCP_DIRECT ?? '',
      MCP_RENAMED: process.env.MCP_RENAMED ?? '',
      MCP_HOST_SECRET: process.env.MCP_HOST_SECRET ?? '',
    };
    return { content: [{ type: 'text', text: JSON.stringify(payload, null, 2) }] };
  },
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);

  // IMPORTANT: stdio transport uses stdout for protocol. Never print to stdout.
  const lines = [
    'dominds-ux-stdio-server: ready',
    `dominds-ux-stdio-server: env MCP_DIRECT=${process.env.MCP_DIRECT ?? ''}`,
    `dominds-ux-stdio-server: env MCP_RENAMED=${process.env.MCP_RENAMED ?? ''}`,
    `dominds-ux-stdio-server: env MCP_HOST_SECRET=${process.env.MCP_HOST_SECRET ?? ''}`,
  ];
  process.stderr.write(`${lines.join('\n')}\n`);
}

main().catch((err) => {
  process.stderr.write(`dominds-ux-stdio-server: fatal: ${String(err)}\n`);
  process.exit(1);
});
