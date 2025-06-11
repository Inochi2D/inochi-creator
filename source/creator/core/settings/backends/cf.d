/**
    CoreFoundation Settings Store

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 https://opensource.org/license/bsd-2-clause, BSD 2-clause)
    Authors:   Luna Nielsen
*/
module creator.core.settings.backends.cf;
import creator.core.settings;
import std.json;
version(OSX):

/**
    Creates a new settings store.
*/
SettingsStore __inc_get_settings_store(string storeId) {
    return new CFSettingsStore(storeId);
}

class CFSettingsStore : SettingsStore {
private:
    CFString* appId;

protected:

    override
    long getIntImpl(string name, long defaultValue = 0) {
        CFString* key = name.toCFString();
        long rv = defaultValue;

        auto v = CFPreferencesCopyAppValue(key, appId);
        if (v && CFGetTypeID(v) == CFNumberGetTypeID()) {

            CFNumber* number = cast(CFNumber*)v;
            CFNumberGetValue(number, CFNumberType.kCFNumberSInt64Type, &rv);
            CFRelease(number);
        }
        
        CFRelease(key);
        return rv;
    }
    
    override
    ulong getUIntImpl(string name, ulong defaultValue = 0) {
        CFString* key = name.toCFString();
        ulong rv = defaultValue;

        auto v = CFPreferencesCopyAppValue(key, appId);
        if (v && CFGetTypeID(v) == CFNumberGetTypeID()) {

            CFNumber* number = cast(CFNumber*)v;
            CFNumberGetValue(number, CFNumberType.kCFNumberSInt64Type, &rv);
            CFRelease(number);
        }
        
        CFRelease(key);
        return rv;
    }
    
    override
    double getDoubleImpl(string name, double defaultValue = 0) {
        CFString* key = name.toCFString();
        double rv = defaultValue;

        auto v = CFPreferencesCopyAppValue(key, appId);
        if (v && CFGetTypeID(v) == CFNumberGetTypeID()) {

            CFNumber* number = cast(CFNumber*)v;
            CFNumberGetValue(number, CFNumberType.kCFNumberFloat64Type, &rv);
            CFRelease(number);
        }
        
        CFRelease(key);
        return rv;
    }
    
    override
    string getStringImpl(string name, string defaultValue = null) {
        CFString* key = name.toCFString();
        string rv = defaultValue;

        auto v = CFPreferencesCopyAppValue(key, appId);
        if (v && CFGetTypeID(v) == CFStringGetTypeID()) {
            CFRelease(key);

            CFString* str = cast(CFString*)v;
            return str.toStringReleased();
        }
        
        CFRelease(key);
        return rv;
    }
    
    override
    JSONValue getJSONImpl(string name) {
        string v = this.getStringImpl(name);
        return parseJSON(v);
    }

    
    override
    void setIntImpl(string name, long value) {
        CFString* key = name.toCFString();
        CFNumber* num = CFNumberCreate(null, CFNumberType.kCFNumberSInt64Type, cast(void*)&value);
        CFPreferencesSetAppValue(key, cast(CFPropertyList*)num, appId);
        cast(void)CFRelease(num);
        cast(void)CFRelease(key);
    }
    
    override
    void setUIntImpl(string name, ulong value)  {
        CFString* key = name.toCFString();
        CFNumber* num = CFNumberCreate(null, CFNumberType.kCFNumberSInt64Type, cast(void*)&value);
        CFPreferencesSetAppValue(key, cast(CFPropertyList*)num, appId);
        cast(void)CFRelease(num);
        cast(void)CFRelease(key);
    }
    
    override
    void setDoubleImpl(string name, double value) {
        CFString* key = name.toCFString();
        CFNumber* num = CFNumberCreate(null, CFNumberType.kCFNumberFloat64Type, cast(void*)&value);
        CFPreferencesSetAppValue(key, cast(CFPropertyList*)num, appId);
        cast(void)CFRelease(num);
        cast(void)CFRelease(key);
    }
    
    override
    void setStringImpl(string name, string value)  {
        CFString* key = name.toCFString();
        CFString* str = value.toCFString();
        CFPreferencesSetAppValue(key, cast(CFPropertyList*)str, appId);
        cast(void)CFRelease(str);
        cast(void)CFRelease(key);
    }
    
    override
    void setJSONImpl(string name, JSONValue value)  {
        this.setStringImpl(name, value.toString());
    }

public:

    ~this() {
        this.sync();
        cast(void)CFRelease(appId);
    }

    /**
        Constructor
    */
    this(string storeId) {
        super(storeId);
        this.appId = storeId.toCFString();
    }

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    override
    void sync() {
        cast(void)CFPreferencesAppSynchronize(appId);
    }

    /**
        Un-sets a value.
    */
    override
    bool unset(string name) {
        CFString* key = name.toCFString();
        CFPreferencesSetAppValue(key, kCFNull, appId, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        return true;
    }

    /**
        Gets whether the store has a given value.
    */
    override
    bool has(string name) {
        bool has = false;
        CFString* key = name.toCFString();

        if (auto v = CFPreferencesCopyAppValue(key, appId)) {
            cast(void)CFRelease(v);
            has = true;
        }

        cast(void)CFRelease(key);
        return has;
    }
}

//
//          Minimal CoreFoundation
//

extern(C) @nogc nothrow:

// Base CoreFoundation things.
extern const(void)* kCFNull;
alias CFIndex = int;
alias CFTypeID = ulong;
extern void* CFRetain(void*);
extern void* CFRelease(void*);
extern CFTypeID CFGetTypeID(void*);

//
//      CFARRAY
//

struct CFArray;
extern CFTypeID CFArrayGetTypeID();
extern CFArray* CFArrayCreate(void*, const(void)**, CFIndex, const(void)*);
extern CFIndex CFArrayGetCount(CFArray*);
extern void* CFArrayGetValueAtIndex(CFArray*, CFIndex);

//
//      CFDICTIONARY
//

struct CFDictionary;
extern CFTypeID CFDictionaryGetTypeID();
extern CFDictionary* CFDictionaryCreate(void*, const(void)**, const(void)**, CFIndex, const(void)*, const(void)*);
extern CFIndex CFDictionaryGetCount(CFDictionary*);
extern const(void)* CFDictionaryGetValue(CFDictionary*, const(void)*);

//
//      CFSTRING
//
enum CFStringEncoding kCFStringEncodingUTF8 = 134217984;
alias CFStringEncoding = uint;

struct CFString;
extern CFTypeID CFStringGetTypeID();
extern CFString* CFStringCreateWithCString(void*, const(char)*, CFStringEncoding);
extern const(char)* CFStringGetCStringPtr(CFString*, CFStringEncoding);
extern bool CFStringGetCString(CFString*, char*, CFIndex, CFStringEncoding);
extern CFIndex CFStringGetLength(CFString*);

CFString* toCFString(string str) {
    import std.string : toStringz;
    return CFStringCreateWithCString(null, str.toStringz, kCFStringEncodingUTF8);
}

extern(D)
string toString(CFString* str) {
    CFIndex len = CFStringGetLength(str);
    if (len > 0) {

        // First try the fast route.   
        if (const(char)* name = CFStringGetCStringPtr(str, kCFStringEncodingUTF8)) {
            return cast(string)name[0..len].nu_dup();
        }

        // Slow route, we have to convert ourselves.
        char[] ret = ha_allocarr!(char)(len);
        if (CFStringGetCString(str, ret.ptr, len, kCFStringEncodingUTF8))
            return cast(string)ret;
    }
    return null;
}

extern(D)
string toStringReleased(CFString* str) {
    string ret = str.toString();
    cast(void)CFRelease(str);
    return ret;
}

//
//      CFBOOLEAN
//
struct CFBoolean;
extern CFTypeID CFBooleanGetTypeID();
extern bool CFBooleanGetValue(CFBoolean*);

//
//      CFNUMBER
//

struct CFNumber;
extern CFTypeID CFNumberGetTypeID();
enum CFNumberType : CFIndex {
    /* Fixed-width types */
    kCFNumberSInt8Type = 1,
    kCFNumberSInt16Type = 2,
    kCFNumberSInt32Type = 3,
    kCFNumberSInt64Type = 4,
    kCFNumberFloat32Type = 5,
    kCFNumberFloat64Type = 6,	/* 64-bit IEEE 754 */
}

extern CFNumber* CFNumberCreate(void*, CFNumberType, const(void)*);
extern CFNumberType CFNumberGetType(CFNumber*);
extern bool CFNumberGetValue(CFNumber*, CFNumberType, void*);
extern bool CFNumberIsFloatType(CFNumber*);

CFNumber* from(T)(T value) if (__traits(isScalar, T)) {
    static if (__traits(isIntegral, T)) {
        static if (__traits(isUnsigned, T)) 
            ulong v = cast(ulong)value;
        else
            long v = cast(long)value;
        
        return CFNumberCreate(null, CFNumberType.kCFNumberSInt64Type, cast(const(void)*)&v);
    } else static if (__traits(isFloating, T)) {
        double v = cast(double)value;
        return CFNumberCreate(null, CFNumberType.kCFNumberFloat64Type, cast(const(void)*)&v);
    }
}

//
//      CFPROPERTYLIST
//

alias CFPropertyList = void;
extern bool CFPropertyListIsValid(CFPropertyList*, CFIndex);

//
//      CFPREFERENCES
//
extern __gshared const(CFString)* kCFPreferencesCurrentUser;
extern __gshared const(CFString)* kCFPreferencesCurrentHost;
extern __gshared const(CFString)* kCFPreferencesCurrentApplication;
extern __gshared const(CFString)* kCFPreferencesAnyUser;
extern __gshared const(CFString)* kCFPreferencesAnyHost;
extern __gshared const(CFString)* kCFPreferencesAnyApplication;

extern bool CFPreferencesAppSynchronize(CFString*);
extern CFPropertyList* CFPreferencesCopyAppValue(CFString*, CFString*);
extern void CFPreferencesSetAppValue(CFString*, CFPropertyList*, CFString*);
extern CFArray* CFPreferencesCopyKeyList(CFString*, CFString*, CFString*);
