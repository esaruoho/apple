// usb-reenumerate — software "replug" for a USB device, no reboot, no cable pull.
//
// Uses IOUSBLib's USBDeviceReEnumerate(), which asks the host controller to drop
// and re-enumerate the device exactly as if it had been physically unplugged and
// plugged back in. Re-enumerating a HUB cascades to everything downstream of it,
// so resetting the dock's hub is a software replug of the whole dock.
//
// FEATURE-CARD >> features/usb-dock-refresh.feature
//
// Build:  clang -O2 -o usb-reenumerate usb-reenumerate.c -framework CoreFoundation -framework IOKit
// Usage:  usb-reenumerate --list
//         usb-reenumerate --reset 0x02200000        (locationID, needs root)

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t num_prop(io_service_t s, CFStringRef key) {
    uint32_t v = 0;
    CFTypeRef r = IORegistryEntryCreateCFProperty(s, key, kCFAllocatorDefault, 0);
    if (r) {
        if (CFGetTypeID(r) == CFNumberGetTypeID())
            CFNumberGetValue((CFNumberRef)r, kCFNumberSInt32Type, &v);
        CFRelease(r);
    }
    return v;
}

// VIA/ASIX hubs pad their product strings with trailing spaces; trim them.
static void trim(char *s) {
    size_t n = strlen(s);
    while (n && (s[n - 1] == ' ' || s[n - 1] == '\t')) s[--n] = 0;
}

static void name_of(io_service_t s, char *buf, size_t n) {
    buf[0] = 0;
    CFTypeRef r = IORegistryEntryCreateCFProperty(s, CFSTR("USB Product Name"),
                                                  kCFAllocatorDefault, 0);
    if (r) {
        if (CFGetTypeID(r) == CFStringGetTypeID())
            CFStringGetCString((CFStringRef)r, buf, (CFIndex)n, kCFStringEncodingUTF8);
        CFRelease(r);
    }
    if (!buf[0]) {
        io_name_t nm;
        if (IORegistryEntryGetName(s, nm) == KERN_SUCCESS) snprintf(buf, n, "%s", nm);
    }
    trim(buf);
}

static io_iterator_t all_usb_devices(void) {
    io_iterator_t it = 0;
    CFMutableDictionaryRef m = IOServiceMatching(kIOUSBDeviceClassName);
    if (!m) return 0;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, m, &it) != KERN_SUCCESS) return 0;
    return it;
}

static int cmd_list(void) {
    io_iterator_t it = all_usb_devices();
    if (!it) { fprintf(stderr, "usb-reenumerate: cannot enumerate USB devices\n"); return 1; }
    io_service_t dev;
    while ((dev = IOIteratorNext(it))) {
        char name[256];
        name_of(dev, name, sizeof name);
        printf("0x%08x\t%04x:%04x\t%s\n",
               num_prop(dev, CFSTR("locationID")),
               num_prop(dev, CFSTR("idVendor")),
               num_prop(dev, CFSTR("idProduct")),
               name);
        IOObjectRelease(dev);
    }
    IOObjectRelease(it);
    return 0;
}

static int cmd_reset(uint32_t want_loc) {
    io_iterator_t it = all_usb_devices();
    if (!it) { fprintf(stderr, "usb-reenumerate: cannot enumerate USB devices\n"); return 1; }

    io_service_t dev, target = 0;
    char name[256] = "";
    while ((dev = IOIteratorNext(it))) {
        if (!target && num_prop(dev, CFSTR("locationID")) == want_loc) {
            target = dev;                 // keep the ref; do not release
            name_of(target, name, sizeof name);
            continue;
        }
        IOObjectRelease(dev);
    }
    IOObjectRelease(it);

    if (!target) {
        fprintf(stderr, "usb-reenumerate: no USB device at locationID 0x%08x\n", want_loc);
        return 2;
    }

    IOCFPlugInInterface **plug = NULL;
    // USBDeviceReEnumerate first appears in IOUSBDeviceInterface187. Every later
    // revision is a strict superset with the same field order, so a newer
    // interface is safe to use through the 187 struct.
    IOUSBDeviceInterface187 **usb = NULL;
    SInt32 score = 0;
    kern_return_t kr = IOCreatePlugInInterfaceForService(
        target, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plug, &score);
    IOObjectRelease(target);
    if (kr != KERN_SUCCESS || !plug) {
        fprintf(stderr, "usb-reenumerate: no plugin interface (0x%x)\n", kr);
        return 3;
    }
    CFUUIDRef versions[] = {
        kIOUSBDeviceInterfaceID942, kIOUSBDeviceInterfaceID650,
        kIOUSBDeviceInterfaceID500, kIOUSBDeviceInterfaceID320,
        kIOUSBDeviceInterfaceID300, kIOUSBDeviceInterfaceID245,
        kIOUSBDeviceInterfaceID197, kIOUSBDeviceInterfaceID187,
    };
    for (size_t i = 0; i < sizeof versions / sizeof *versions && !usb; i++)
        (*plug)->QueryInterface(plug, CFUUIDGetUUIDBytes(versions[i]), (LPVOID *)&usb);
    (*plug)->Release(plug);
    if (!usb) {
        fprintf(stderr, "usb-reenumerate: no interface revision with ReEnumerate\n");
        return 4;
    }

    // Seize: the device usually already has a kernel driver attached (ethernet,
    // mass storage, HID). Plain Open would return kIOReturnExclusiveAccess.
    kr = (*usb)->USBDeviceOpenSeize(usb);
    if (kr != KERN_SUCCESS) kr = (*usb)->USBDeviceOpen(usb);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "usb-reenumerate: cannot open %s (0x%x) — run as root\n", name, kr);
        (*usb)->Release(usb);
        return 5;
    }

    kr = (*usb)->USBDeviceReEnumerate(usb, 0);
    // After a successful re-enumerate the device object is already gone, so a
    // failing Close here is expected and not an error.
    (*usb)->USBDeviceClose(usb);
    (*usb)->Release(usb);

    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "usb-reenumerate: ReEnumerate failed on %s (0x%x)\n", name, kr);
        return 6;
    }
    printf("re-enumerated 0x%08x  %s\n", want_loc, name);
    return 0;
}

int main(int argc, char **argv) {
    if (argc >= 2 && strcmp(argv[1], "--list") == 0) return cmd_list();
    if (argc == 3 && strcmp(argv[1], "--reset") == 0)
        return cmd_reset((uint32_t)strtoul(argv[2], NULL, 0));
    fprintf(stderr, "usage: usb-reenumerate --list | --reset <locationID>\n");
    return 64;
}
