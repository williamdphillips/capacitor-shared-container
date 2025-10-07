import { WebPlugin } from '@capacitor/core';

import type { SharedContainerPlugin, SharedContainerFile } from './definitions';

export class SharedContainerWeb extends WebPlugin implements SharedContainerPlugin {
  async readSharedContainerDirectory(options: { path: string }): Promise<{ files: SharedContainerFile[] }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async readSharedContainerFile(options: { path: string }): Promise<{ data: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async writeSharedContainerFile(options: { path: string; data: string }): Promise<void> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async deleteSharedContainerFile(options: { path: string }): Promise<void> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async cleanupOldSharedContainerFiles(options: { path: string }): Promise<{ deletedCount: number; deletedSize: number; message: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }

  async wipeSharedContainerDirectory(options: { path: string }): Promise<{ deletedCount: number; deletedSize: number; message: string }> {
    throw new Error('SharedContainer plugin is not available on web platform');
  }
}

