import { registerPlugin } from '@capacitor/core';

import type { SharedContainerPlugin } from './definitions';

const SharedContainer = registerPlugin<SharedContainerPlugin>('SharedContainer', {
  web: () => import('./web').then(m => new m.SharedContainerWeb()),
});

export * from './definitions';
export default SharedContainer;

