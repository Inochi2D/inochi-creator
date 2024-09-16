#/usr/bin/env python3
import os
import sys
import glob
import argparse

from babel.messages.pofile import read_po

"""
# polib is broken, use babel instead
# gettext not supported .po files

pip install babel
"""

tl_files = glob.glob("tl/*.po")

ignore = [
    "tl/template.pot",
]

fmt_str_keywords = ['%s', '%d', '%f', '%u', '%lu']
check_fuzzy = False
ignore_empty = False

def validate_string_formatting(msgid, msgstr) -> bool:
    """
    Check if the string formatting is correct
    Note: currently not checking the order of the formatting, and not check %2$s etc
    """
    fmt_str_count = {}
    fmt_target_count = {}
    for fmt_str in fmt_str_keywords:
        fmt_str_count[fmt_str] = msgid.count(fmt_str)
        fmt_target_count[fmt_str] = msgstr.count(fmt_str)

    for fmt_str in fmt_str_keywords:
        if fmt_str_count[fmt_str] == 0:
            continue
        if fmt_str_count[fmt_str] != fmt_target_count[fmt_str]:
            return False
        
    return True

def validate_non_ascii(msgstr, msgid) -> bool:
    """
    For example, English using non-ascii as icon (Google Material Icons)
    """
    non_ascii = [c for c in msgid if ord(c) > 127]
    non_ascii_target = [c for c in msgstr  if ord(c) > 127]
    
    for c in non_ascii:
        if c not in non_ascii_target:
            return False
    
    return True

class ValidationError(Exception):
    def __init__(self, message, entry):
        self.message = message
        self.entry = entry
        
    def __str__(self):
        return self.message

class Summary:
    def __init__(self):
        self.total = 0
        self.success = 0

    def print_summary(self):
        print(f"Total: {self.total}, translated rate: {self.success}/{self.total} ({self.success/self.total*100:.2f}%)")

def validate_string(entry, summary : Summary) -> bool:
    summary.total += 1
    if entry.string == "" and not ignore_empty:
        raise ValidationError("msgstr is empty", entry)
    
    if not validate_string_formatting(entry.id, entry.string):
        raise ValidationError("msgstr fmtstr is incorrect", entry)
    
    if not validate_non_ascii(entry.string, entry.id):
        raise ValidationError("msgstr may lost icon", entry)

    if entry.fuzzy and check_fuzzy:
        raise ValidationError("msgstr is fuzzy", entry)

    if not entry.fuzzy and entry.string != "":
        summary.success += 1

    return True

escape_chars = {
    "\n": "\\n", "\r": "\\r", "\t": "\\t",
    "\"": "\\\""
}
escape_table = str.maketrans(escape_chars)

def escape_string(s) -> str:
    return s.translate(escape_table)

def validate_file(file_path) -> int:
    ret_code = 0
    summary = Summary()
    print("Validating file: " + file_path)

    with open(file_path, 'r', encoding='utf-8') as file:
        catalog = read_po(file)

    for entry in catalog:
        try:
            validate_string(entry, summary)
        except ValidationError as e:
            msgid = escape_string(e.entry.id)
            msgstr = escape_string(e.entry.string)
            print("Validation Error: " + str(e) + f" ({file_path}:{e.entry.lineno})")
            print(f"\tmsgid: \"{msgid}\"")
            print(f"\tmsgstr: \"{msgstr}\"")
            ret_code = 1

    summary.print_summary()

    return ret_code

def validate_all() -> int:
    ret_code = 0
    for tl_file in tl_files:
        ret_code += validate_file(tl_file)
        
    return ret_code

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Validate translation files')
    parser.add_argument('-a', '--all', action='store_true', help='Validate all files')
    parser.add_argument('-f', '--file', type=str, help='Validate specific file')
    parser.add_argument('--fuzzy', action='store_true', help='Check fuzzy entries')
    parser.add_argument('--ignore-empty', action='store_true', help='Ignore empty msgstr')
    args = parser.parse_args()
    
    if args.fuzzy:
        check_fuzzy = True
        
    if args.ignore_empty:
        ignore_empty = True

    if args.all:
        sys.exit(validate_all())
    elif args.file:
        sys.exit(validate_file(args.file))
    else:
        print("No arguments given")
        parser.print_help()
        sys.exit(1)

    
