mkdir -p out/
for f in tl/*.po; do
    msgfmt -o "out/$(basename -- "$f" .po).mo" -- "$f" 
done