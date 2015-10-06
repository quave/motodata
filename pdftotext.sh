ruby get_files.rb >> get_files.log &

# old version for f in $(find ./ -name '*.pdf'); do pdftotext -layout $f; echo $f; done

for f in $(find ./pdf -name "*.pdf"); do pdftk "$f" output "$f".unc uncompress; done
for f in $(find ./pdf -name "*.pdf.unc"); do pdftotext -raw "$f" "$f".txt; echo "$f"; done

rename -f 's/(.*).pdf.unc.txt$/$1.txt/' **

zip -r 1.hi . -i \*.txt
scp -P 443 ror@roleplayground.ru:~/pdf/1.hi ./