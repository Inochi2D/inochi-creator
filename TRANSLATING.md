# Translating Inochi Creator
Inochi Creator uses gettext to handle translation, currently pluralization is not support but will be added soon(TM).  
You'll need a distribution of gettext to work on translation files.  
Currently the language support within Inochi Creator is limited, as such there may be rendering errors for some languages.  
We do not support languages that are right-to-left due to limitations within our UI library.  

## Creating a translation file for a new language
To create a new translation file, run
```sh
msginit --locale=<langcode> --input=tl/template.pot -o tl/<langcode>.po
```
replace `<langcode>` with your language's language code.

#### NOTE
 * Make sure to update the charset variable in your .po file to UTF-8. Inochi Creator only supports UTF-8.

## Merging information from latest template
```sh
msgmerge -o tl/<langcode>_merged.po tl/<langcode>.po tl/template.pot
```

Check if the merges make sense, if so replace `<langcode>.po` with `<langcode>_merged.po`.