#!/usr/bin/env node

// Minimal MCP stdio server for Dominds UX stories.
// Purpose: provide a tiny, reliable tool surface for MCP support testing (no heavy browsers).
// Protocol: MCP over JSON-RPC 2.0 line-delimited over stdin/stdout.

function write(obj) {
  process.stdout.write(`${JSON.stringify(obj)}\n`);
}

function isRecord(v) {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function jsonRpcError(id, code, message, data) {
  const err = { code, message };
  if (data !== undefined) err.data = data;
  write({ jsonrpc: '2.0', id, error: err });
}

function jsonRpcResult(id, result) {
  write({ jsonrpc: '2.0', id, result });
}

function toolListResult() {
  return {
    tools: [
      {
        name: 'env_echo',
        description: 'Echo selected env vars and input back as JSON text.',
        inputSchema: {
          type: 'object',
          properties: {
            keys: { type: 'array', items: { type: 'string' } },
            payload: { type: 'string' },
          },
          required: ['keys'],
        },
      },
    ],
  };
}

function toolCallResult(name, args) {
  if (name !== 'env_echo') {
    return {
      content: [
        {
          type: 'text',
          text: `Unknown tool: ${name}`,
        },
      ],
    };
  }

  const keys = Array.isArray(args?.keys) ? args.keys : [];
  const env = {};
  for (const k of keys) {
    if (typeof k === 'string') env[k] = process.env[k] ?? null;
  }

  const payload = typeof args?.payload === 'string' ? args.payload : '';

  const out = {
    ok: true,
    keys,
    env,
    payload,
    pid: process.pid,
  };

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify(out, null, 2),
      },
    ],
  };
}

let initialized = false;

process.stdin.setEncoding('utf8');
let buf = '';

process.stdin.on('data', (chunk) => {
  buf += chunk;
  while (true) {
    const idx = buf.indexOf('\n');
    if (idx < 0) break;
    const line = buf.slice(0, idx).trim();
    buf = buf.slice(idx + 1);
    if (!line) continue;

    let msg;
    try {
      msg = JSON.parse(line);
    } catch (e) {
      continue;
    }

    if (!isRecord(msg) || msg.jsonrpc !== '2.0') continue;

    const id = msg.id;
    const hasId = typeof id === 'number';
    const method = msg.method;

    // Notifications: ignore.
    if (!hasId) continue;

    if (typeof method !== 'string') {
      jsonRpcError(id, -32600, 'Invalid Request', { line });
      continue;
    }

    if (method === 'initialize') {
      initialized = true;
      jsonRpcResult(id, {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'env-var-echo', version: '0.1.0' },
      });
      continue;
    }

    if (!initialized) {
      jsonRpcError(id, -32002, 'Server not initialized');
      continue;
    }

    if (method === 'tools/list') {
      jsonRpcResult(id, toolListResult());
      continue;
    }

    if (method === 'tools/call') {
      const params = msg.params;
      if (!isRecord(params)) {
        jsonRpcError(id, -32602, 'Invalid params', { expected: 'object' });
        continue;
      }
      const name = params.name;
      const args = params.arguments;
      if (typeof name !== 'string') {
        jsonRpcError(id, -32602, 'Invalid params: missing name');
        continue;
      }
      jsonRpcResult(id, toolCallResult(name, isRecord(args) ? args : {}));
      continue;
    }

    jsonRpcError(id, -32601, `Method not found: ${method}`);
  }
});

process.stdin.on('end', () => {
  // Exit cleanly when stdin closes.
  process.exit(0);
});
