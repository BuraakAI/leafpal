import { env } from './config/env';
import { createApp } from './app';

const app = createApp();

app.listen(env.port, () => {
  console.log(`Plant App API running on port ${env.port} [${env.nodeEnv}]`);
  if (env.skipAuth) console.log('⚠️  Auth skipped (SKIP_AUTH=true)');
});
