#import <Capacitor/Capacitor.h>
#import <Foundation/Foundation.h>

CAP_PLUGIN(
    SharedContainerPlugin, "SharedContainer",
    CAP_PLUGIN_METHOD(readSharedContainerDirectory, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(readSharedContainerFile, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(writeSharedContainerFile, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(deleteSharedContainerFile, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(cleanupOldSharedContainerFiles, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(wipeSharedContainerDirectory, CAPPluginReturnPromise);)
