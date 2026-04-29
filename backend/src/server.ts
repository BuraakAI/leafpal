import { env } from './config/env';
import { createApp } from './app';

process.on('uncaughtException', (err) => {
  console.error('[crash] uncaughtException:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('[crash] unhandledRejection:', reason);
  process.exit(1);
});

console.log('[boot] modules loaded, port=' + env.port);

const app = createApp();

app.listen(env.port, () => {
  console.log('[boot] Plant App API running on port ' + env.port + ' [' + env.nodeEnv + ']');
  if (env.skipAuth) console.log('[boot] Auth skipped (SKIP_AUTH=true)');
});
