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

def parse_po_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        catalog = read_po(file)
    
    entries = []
    for message in catalog:
        entries.append({
            "msgid": message.id,
            "msgstr": message.string,
            "comments": message.user_comments
        })

    return entries

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

def validate_string(entry) -> bool:
    if entry['msgstr'] == "":
        raise ValidationError("msgstr is empty", entry)
    
    if not validate_string_formatting(entry['msgid'], entry['msgstr']):
        raise ValidationError("msgstr fmtstr is incorrect", entry)
    
    if not validate_non_ascii(entry['msgstr'], entry['msgid']):
        raise ValidationError("msgstr may lost icon", entry)

    return True

def validate_file(file):
    print("Validating file: " + file)

    pofile = parse_po_file(file)
    for entry in pofile:
        try:
            validate_string(entry)
        except ValidationError as e:
            print("Validation Error: " + str(e))
            print(f"\tmsgid: {e.entry['msgid']}")
            print(f"\tmsgstr: {e.entry['msgstr']}")
            # sys.exit(1)

def validate_all():
    for tl_file in tl_files:
        validate_file(tl_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Validate translation files')
    parser.add_argument('-a', '--all', action='store_true', help='Validate all files')
    parser.add_argument('-f', '--file', type=str, help='Validate specific file')
    args = parser.parse_args()
    
    if args.all:
        validate_all()
    elif args.file:
        validate_file(args.file)
    else:
        print("No arguments given")
        parser.print_help()
        sys.exit(1)

    
