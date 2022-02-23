#!/bin/sh
find . -iname "*.d" | xargs xgettext --from-code=UTF-8 -o tl/template.pot -c --keyword=_ --keyword=__