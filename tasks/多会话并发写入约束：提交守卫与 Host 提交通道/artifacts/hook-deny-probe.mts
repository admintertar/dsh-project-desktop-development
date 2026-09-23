/** Throwaway probe: can a guard / pre-execute listener really deny a tool call? */
import {Context} from '@deepseek-ai/cordis';
import {defineTool} from '@deepseek-ai/dsh-tools';
import {mountAgentLoopTestDependencies} from '@deepseek-ai/dsh-agent-loop-testkit';
import {z} from 'zod';
import {jsonObject, OUTPUT_SCHEMA, parameters, renderValue} from './src/tool-schema.ts';

const ctx = new Context();
await mountAgentLoopTestDependencies(ctx);

let executed = 0;
ctx.tools.register(defineTool({
  name: 'probe_write',
  description: 'Probe-only write tool.',
  parameters: parameters(z.object({path: z.string()}).strict()),
  output: {schema: OUTPUT_SCHEMA, render: renderValue},
  async execute(args: {path: string}) {executed += 1; return jsonObject({wrote: args.path});},
}));

let calls = 0;
// `signal` is required by the runtime even though `ToolExecutionInput` omits it.
const call = () => ctx.tools.execute({
  callId: `probe-${++calls}`, name: 'probe_write', arguments: {path: 'a.ts'},
  signal: new AbortController().signal,
} as never);

console.log('baseline  :', JSON.stringify(await call()).slice(0, 220), '| body ran =', executed);

const release = ctx.tools.guard(exec => exec.name === 'probe_write' ? 'denied: create a worktree first' : undefined);
console.log('guarded   :', JSON.stringify(await call()).slice(0, 320), '| body ran =', executed);
release();
console.log('released  :', JSON.stringify(await call()).slice(0, 200), '| body ran =', executed);

// The waterfall form: `ask` must degrade to denial when no approval service exists.
ctx.on('tools/pre-execute', async (exec, next) => exec.name === 'probe_write' ? {kind: 'ask', reason: 'run in a worktree?'} : next());
console.log('ask       :', JSON.stringify(await call()).slice(0, 320), '| body ran =', executed);

await ctx.stop?.();
