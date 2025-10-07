export interface SharedContainerFile {
  name: string;
  size: number;
  creationDate?: string;
  modificationDate?: string;
}

export interface SharedContainerPlugin {
  /**
   * Read directory contents from the shared container
   */
  readSharedContainerDirectory(options: { path: string }): Promise<{ files: SharedContainerFile[] }>;

  /**
   * Read file contents from the shared container
   */
  readSharedContainerFile(options: { path: string }): Promise<{ data: string }>;

  /**
   * Write file to the shared container
   */
  writeSharedContainerFile(options: { path: string; data: string }): Promise<void>;

  /**
   * Delete file from the shared container
   */
  deleteSharedContainerFile(options: { path: string }): Promise<void>;

  /**
   * Clean up old files from the shared container (removes files older than 24 hours or larger than 500MB)
   */
  cleanupOldSharedContainerFiles(options: {
    path: string;
  }): Promise<{ deletedCount: number; deletedSize: number; message: string }>;

  /**
   * Completely wipe all files from a directory in the shared container
   */
  wipeSharedContainerDirectory(options: {
    path: string;
  }): Promise<{ deletedCount: number; deletedSize: number; message: string }>;
}
