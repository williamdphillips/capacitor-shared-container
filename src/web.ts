import { WebPlugin } from '@capacitor/core';

import type { SharedContainerPlugin, SharedContainerFile } from './definitions';

export class SharedContainerWeb extends WebPlugin implements SharedContainerPlugin {
  async readSharedContainerDirectory(_options: { path: string }): Promise<{ files: SharedContainerFile[] }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async readSharedContainerFile(_options: { path: string }): Promise<{ data: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async writeSharedContainerFile(_options: { path: string; data: string }): Promise<void> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async deleteSharedContainerFile(_options: { path: string }): Promise<void> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async cleanupOldSharedContainerFiles(_options: {
    path: string;
  }): Promise<{ deletedCount: number; deletedSize: number; message: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async wipeSharedContainerDirectory(_options: {
    path: string;
  }): Promise<{ deletedCount: number; deletedSize: number; message: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }
}
