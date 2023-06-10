mkdir -p out/
for f in tl/*.po; do
    msgmerge -o "$f" "$f" "tl/template.pot" 
done