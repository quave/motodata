ruby get_files.rb >> get_files.log &

for f in $(find ./ -name '*.pdf'); do pdftotext -layout $f; echo $f; done
zip -r 1.hi . -i \*.txt

scp -P 443 ror@roleplayground.ru:~/pdf/1.hi ./