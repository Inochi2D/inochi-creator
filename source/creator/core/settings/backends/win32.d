/**
    Windows registry settings store.

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 https://opensource.org/license/bsd-2-clause, BSD 2-clause)
    Authors:   Luna Nielsen
*/
module creator.core.settings.backends.win32;
import creator.core.settings;
import std.json;
version(Windows):

import core.sys.windows.winreg;
import core.sys.windows.windef;
import core.sys.windows.winbase : ExpandEnvironmentStringsW;

/**
    Creates a new settings store.
*/
SettingsStore __inc_get_settings_store(string storeId) {
    return new Win32SettingsStore(storeId);
}

class Win32SettingsStore : SettingsStore {
private:
    RegistryKey storeKey;

protected:

    override
    long getIntImpl(string name, long defaultValue = 0) {
        return storeKey.getValue!long(name, defaultValue);
    }
    
    override
    ulong getUIntImpl(string name, ulong defaultValue = 0) {
        return storeKey.getValue!ulong(name, defaultValue);
    }
    
    override
    double getDoubleImpl(string name, double defaultValue = 0) {
        return storeKey.getValue!double(name, defaultValue);
    }
    
    override
    string getStringImpl(string name, string defaultValue = null) {
        return storeKey.getValue!string(name, defaultValue);
    }
    
    override
    JSONValue getJSONImpl(string name) {
        return storeKey.getValue!JSONValue(name, JSONValue.init);
    }

    
    override
    void setIntImpl(string name, long value)  {
        storeKey.setValue!long(name, value);
    }
    
    override
    void setUIntImpl(string name, ulong value)  {
        storeKey.setValue!ulong(name, value);
    }
    
    override
    void setDoubleImpl(string name, double value)  {
        storeKey.setValue!double(name, value);
    }
    
    override
    void setStringImpl(string name, string value)  {
        storeKey.setValue!string(name, value);
    }
    
    override
    void setJSONImpl(string name, JSONValue value)  {
        storeKey.setValue!JSONValue(name, value);
    }


public:

    /**
        Constructor
    */
    this(string storeId) {
        super(storeId);
        this.storeKey = new RegistryKey(HKEY_CURRENT_USER, "\\SOFTWARE\\"~storeId);
    }

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    override
    void sync() {
        storeKey.flush();
    }

    /**
        Un-sets a value.
    */
    override
    bool unset(string name) {
        storeKey.deleteValue(name);
    }

    /**
        Gets whether the store has a given value.
    */
    override
    bool has(string name) {
        return storeKey.hasValue(name);
    }
}

/**
    Wrapper around a windows registry key.
*/
class RegistryKey {
private:
    HKEY key;
    const(wchar)* subkeyPath;

    ptrdiff_t getValueSize(const(wchar)* key, ref DWORD type) {
        DWORD size;
        
        if (RegGetValueW(key, null, key, RRF_RT_ANY, &type, null, &size) == ERROR_SUCCESS)
            return size;
        return -1;
    }

    string expandEnvString(const(wchar)* str) {
        uint size = ExpandEnvironmentStringsW(str, null, 0);

        if (size > 0) {
            wstring buffer = new wstring(size);
            ExpandEnvironmentStringsW(str, buffer.ptr, cast(uint)buffer.length);
            return buffer.ptr.fromWin32Str();
        }

        return "";
    }

public:

    /**
        Destructor
    */
    ~this() {
        RegCloseKey(key);
    }

    /**
        Constructor
    */
    this(HKEY rootKey, string subkey) {
        this.subkeyPath = subkey.toWin32Str();
        assert(RegOpenKeyExW(rootKey, subkeyPath, 0, KEY_READ | KEY_WRITE, &key) == ERROR_SUCCESS);
    }

    /**
        Gets whether the key has a given value.
    */
    bool hasValue(string key) {
        auto wkey = key.toWin32Str();
        return RegGetValueW(key, null, wkey, RRF_RT_ANY, null, null, null) != ERROR_FILE_NOT_FOUND;
    }

    /**
        Gets the requested value.
    */
    T getValue(T)(string key, T defaultValue = T.init) {
        auto wkey = key.toWin32Str();
        DWORD type;

        // Try getting the value.
        ptrdiff_t valueSize = this.getValueSize(wkey, type);
        if (valueSize == -1)
            return defaultValue;

        static if (is(T : string)) {
            if (!(type & (REG_SZ | REG_MULTI_SZ | REG_EXPAND_SZ)))
                return defaultValue;
            
            wstring buffer = new string(valueStoreSize);
            DWORD valueStoreSize = cast(DWORD)valueSize;
            if (RegGetValueW(key, null, wkey, RRF_RT_ANY, null, cast(void*)buffer.ptr, &valueStoreSize) != ERROR_SUCCESS)
                return defaultValue;

            if (type == REG_EXPAND_SZ)
                return expandEnvString(valueStore.ptr);
            
            return valueStore.ptr.fromWin32Str();
        } else static if (__traits(isIntegral, T)) {
            if (!(type & (REG_DWORD | REG_QWORD)))
                return defaultValue;

            QWORD buffer;
            DWORD valueStoreSize = cast(DWORD)valueSize;
            if (RegGetValueW(key, null, wkey, RRF_RT_ANY, null, cast(void*)buffer.ptr, &valueStoreSize) != ERROR_SUCCESS)
                return defaultValue;

            // Reinterpret cast if needed.
            static if (__traits(isUnsigned, T)) 
                return cast(T)(*cast(ulong*)cast(QWORD*)&buffer);
            else 
                return cast(T) buffer;
        } else static if (__traits(isFloating, T)) {
            if (!(type & (REG_DWORD | REG_QWORD)))
                return defaultValue;

            QWORD buffer;
            DWORD valueStoreSize = cast(DWORD)valueSize;
            if (RegGetValueW(key, null, wkey, RRF_RT_ANY, null, cast(void*)buffer.ptr, &valueStoreSize) != ERROR_SUCCESS)
                return defaultValue;
            
            // Reinterpret int to float.
            return cast(T)(*cast(double*)cast(QWORD*)&buffer);
        } else static if (is(T : JSONValue)) {
            if (!(type & (REG_SZ)))
                return defaultValue;

            wstring buffer = new string(valueStoreSize);
            DWORD valueStoreSize = cast(DWORD)valueSize;
            if (RegGetValueW(key, null, wkey, RRF_RT_ANY, null, cast(void*)buffer.ptr, &valueStoreSize) != ERROR_SUCCESS)
                return defaultValue;
            
            return parseJSON(buffer);
        } else static assert(0, "Unsupported type "~T.stringof);
    }

    /**
        Sets the requested value.
    */
    void setValue(T)(string key, T value) {
        auto wkey = key.toWin32Str();

        static if (is(T : string)) {
            auto wval = value.toWin32Str();
            assert(RegSetValueExW(key, wkey, 0, REG_SZ, cast(const(BYTE)*)wval, cast(DWORD)value.length) == ERROR_SUCCESS);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T)) {
                ulong ulValue = value;
                assert(RegSetValueExW(key, wkey, 0, REG_QWORD, cast(const(BYTE)*)&ulValue, cast(DWORD)ulong.sizeof) == ERROR_SUCCESS);
            } else {
                long lValue = value;
                assert(RegSetValueExW(key, wkey, 0, REG_QWORD, cast(const(BYTE)*)&lValue, cast(DWORD)long.sizeof) == ERROR_SUCCESS);
            }
        } else static if (__traits(isFLoating, T)) {
            double dValue = cast(double)value;
            assert(RegSetValueExW(key, wkey, 0, REG_QWORD, cast(const(BYTE)*)&dValue, cast(DWORD)double.sizeof) == ERROR_SUCCESS);
        } else static if (is(T : JSONValue)) {
            auto wval = value.toString().toWin32Str();
            assert(RegSetValueExW(key, wkey, 0, REG_SZ, cast(const(BYTE)*)wval, cast(DWORD)value.length) == ERROR_SUCCESS);
        } else static assert(0, "Unsupported type "~T.stringof);
    }

    /**
        Deletes the requested value.
    */
    bool deleteValue(string key) {
        auto wkey = key.toWin32Str();
        return RegDeleteValueW(key, wkey) == ERROR_SUCCESS;
    }

    /**
        Flushes the key.
    */
    void flush() {
        RegFlushKey(key);
    }

}


//
//          HELPERS
//

private
string fromWin32Str(const(wchar)* str) {
    import std.conv : text;
    return str.text;
}

private
const(wchar)* toWin32Str(string str) {
    import core.internal.utf : toUTF16z;
    return str.toUTF16z;
}