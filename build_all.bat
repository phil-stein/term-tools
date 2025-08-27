@echo off


SET CUSTOM_ATTRIBUTES=-custom-attribute:NOTE -custom-attribute:TODO -custom-attribute:TMP -custom-attribute:BUG -custom-attribute:UNKNOWN

del bin\search.exe
odin build search -out:bin\search.exe -vet-shadowing %CUSTOM_ATTRIBUTES%

del bin\gitsync.exe
odin build gitsync -out:bin\gitsync.exe -vet-shadowing %CUSTOM_ATTRIBUTES%

del bin\cat.exe
odin build cat -out:bin\cat.exe -vet-shadowing %CUSTOM_ATTRIBUTES%

del bin\notizn.exe
odin build notizn -out:bin\notizn.exe -vet-shadowing %CUSTOM_ATTRIBUTES%

del bin\ls.exe
odin build ls -out:bin\ls.exe -vet-shadowing %CUSTOM_ATTRIBUTES%

:: del bin\cpy.exe
:: odin build cpy -out:bin\cpy.exe %CUSTOM_ATTRIBUTES%

cd test
search ui_display_struct_members
gitsync
cat name.txt
notizn
ls
:: cpy
cd ..
