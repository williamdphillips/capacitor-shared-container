package com.soundsstudios.sharedcontainer;

import android.util.Base64;
import android.util.Log;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Android equivalent of the iOS App Group shared container.
 * Uses app-private filesDir/shared_container so share-intent imports and the
 * web layer can exchange files via the same SharedContainer plugin API.
 */
@CapacitorPlugin(name = "SharedContainer")
public class SharedContainerPlugin extends Plugin {
    private static final String TAG = "SharedContainer";
    public static final String CONTAINER_DIR_NAME = "shared_container";
    private static final long MAX_LIST_FILE_SIZE = 500L * 1024L * 1024L; // 500MB
    private static final long MAX_READ_FILE_SIZE = 100L * 1024L * 1024L; // 100MB
    private static final long MAX_AGE_MS = 24L * 60L * 60L * 1000L; // 24 hours

    private File getSharedContainerRoot() {
        File root = new File(getContext().getFilesDir(), CONTAINER_DIR_NAME);
        if (!root.exists() && !root.mkdirs()) {
            Log.w(TAG, "Failed to create shared container root: " + root.getAbsolutePath());
        }
        return root;
    }

    private File resolvePath(String path) {
        return new File(getSharedContainerRoot(), path);
    }

    private String toIso8601(long millis) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US);
        sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
        return sdf.format(new Date(millis));
    }

    @PluginMethod
    public void readSharedContainerDirectory(PluginCall call) {
        String path = call.getString("path");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }

        File dir = resolvePath(path);
        if (!dir.exists()) {
            // Match iOS behavior for empty/missing import folders: return empty list
            JSObject result = new JSObject();
            result.put("files", new JSArray());
            call.resolve(result);
            return;
        }
        if (!dir.isDirectory()) {
            call.reject("Path is not a directory: " + path);
            return;
        }

        File[] contents = dir.listFiles();
        JSArray files = new JSArray();
        long cutoff = System.currentTimeMillis() - MAX_AGE_MS;

        if (contents != null) {
            for (File file : contents) {
                if (!file.isFile()) {
                    continue;
                }
                long fileSize = file.length();
                long mostRecent = Math.max(file.lastModified(), file.lastModified());
                if (fileSize > MAX_LIST_FILE_SIZE) {
                    Log.w(TAG, "Skipping large file: " + file.getName());
                    continue;
                }
                if (mostRecent < cutoff) {
                    Log.w(TAG, "Skipping old file: " + file.getName());
                    continue;
                }

                JSObject entry = new JSObject();
                entry.put("name", file.getName());
                entry.put("size", fileSize);
                entry.put("creationDate", toIso8601(file.lastModified()));
                entry.put("modificationDate", toIso8601(file.lastModified()));
                files.put(entry);
            }
        }

        JSObject result = new JSObject();
        result.put("files", files);
        call.resolve(result);
    }

    @PluginMethod
    public void readSharedContainerFile(PluginCall call) {
        String path = call.getString("path");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }

        File file = resolvePath(path);
        if (!file.exists() || !file.isFile()) {
            call.reject("File not found: " + path);
            return;
        }

        long fileSize = file.length();
        if (fileSize > MAX_READ_FILE_SIZE) {
            call.reject("File too large: " + fileSize + " bytes. Maximum allowed: " + MAX_READ_FILE_SIZE + " bytes");
            return;
        }

        try (FileInputStream fis = new FileInputStream(file)) {
            byte[] data = new byte[(int) fileSize];
            int read = fis.read(data);
            if (read < 0) {
                data = new byte[0];
            }
            JSObject result = new JSObject();
            result.put("data", Base64.encodeToString(data, Base64.NO_WRAP));
            call.resolve(result);
        } catch (IOException e) {
            call.reject("Failed to read file: " + e.getMessage());
        }
    }

    @PluginMethod
    public void writeSharedContainerFile(PluginCall call) {
        String path = call.getString("path");
        String data = call.getString("data");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }
        if (data == null) {
            call.reject("Data parameter is required");
            return;
        }

        File file = resolvePath(path);
        File parent = file.getParentFile();
        if (parent != null && !parent.exists() && !parent.mkdirs()) {
            call.reject("Failed to create parent directory for: " + path);
            return;
        }

        try {
            byte[] bytes = Base64.decode(data, Base64.DEFAULT);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                fos.write(bytes);
            }
            call.resolve();
        } catch (IllegalArgumentException e) {
            call.reject("Invalid base64 data");
        } catch (IOException e) {
            call.reject("Failed to write file: " + e.getMessage());
        }
    }

    @PluginMethod
    public void deleteSharedContainerFile(PluginCall call) {
        String path = call.getString("path");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }

        File file = resolvePath(path);
        if (!file.exists()) {
            call.resolve();
            return;
        }
        if (!file.delete()) {
            call.reject("Unable to delete file " + path + " from shared container");
            return;
        }
        call.resolve();
    }

    @PluginMethod
    public void cleanupOldSharedContainerFiles(PluginCall call) {
        String path = call.getString("path");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }

        File dir = resolvePath(path);
        int deletedCount = 0;
        long deletedSize = 0;
        long cutoff = System.currentTimeMillis() - MAX_AGE_MS;

        if (dir.exists() && dir.isDirectory()) {
            File[] contents = dir.listFiles();
            if (contents != null) {
                for (File file : contents) {
                    if (!file.isFile()) {
                        continue;
                    }
                    long fileSize = file.length();
                    long mostRecent = file.lastModified();
                    if (fileSize > MAX_LIST_FILE_SIZE || mostRecent < cutoff) {
                        if (file.delete()) {
                            deletedCount++;
                            deletedSize += fileSize;
                        }
                    }
                }
            }
        }

        JSObject result = new JSObject();
        result.put("deletedCount", deletedCount);
        result.put("deletedSize", deletedSize);
        result.put("message", "Cleaned up " + deletedCount + " files (" + deletedSize + " bytes)");
        call.resolve(result);
    }

    @PluginMethod
    public void wipeSharedContainerDirectory(PluginCall call) {
        String path = call.getString("path");
        if (path == null) {
            call.reject("Path parameter is required");
            return;
        }

        File dir = resolvePath(path);
        int deletedCount = 0;
        long deletedSize = 0;

        if (dir.exists() && dir.isDirectory()) {
            File[] contents = dir.listFiles();
            if (contents != null) {
                for (File file : contents) {
                    if (!file.isFile()) {
                        continue;
                    }
                    long fileSize = file.length();
                    if (file.delete()) {
                        deletedCount++;
                        deletedSize += fileSize;
                    }
                }
            }
        }

        JSObject result = new JSObject();
        result.put("deletedCount", deletedCount);
        result.put("deletedSize", deletedSize);
        result.put("message", "Wiped " + deletedCount + " files (" + deletedSize + " bytes)");
        call.resolve(result);
    }

    /**
     * Absolute path to the shared container root for native intent handlers.
     */
    public static File getSharedContainerRoot(android.content.Context context) {
        File root = new File(context.getFilesDir(), CONTAINER_DIR_NAME);
        if (!root.exists()) {
            //noinspection ResultOfMethodCallIgnored
            root.mkdirs();
        }
        return root;
    }
}
