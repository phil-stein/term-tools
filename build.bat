@echo off


SET DEBUG=-debug

SET CUSTOM_ATTRIBUTES=-custom-attribute:NOTE -custom-attribute:TODO -custom-attribute:TMP -custom-attribute:BUG -custom-attribute:UNKNOWN

:: del bin\math.exe
:: odin build math -out:bin\math.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\todo.exe
:: odin build todo -out:bin\todo.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\img.exe
:: odin build img -out:bin\img.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

del bin\search.exe
odin build search -out:bin\search.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\gitsync.exe
:: odin build gitsync -out:bin\gitsync.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: @TODO: .md syntax html tags
:: del bin\cat.exe
:: odin build cat -out:bin\cat.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\notizn.exe
:: odin build notizn -out:bin\notizn.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\ls.exe
:: odin build ls -out:bin\ls.exe -vet-shadowing %DEBUG% %CUSTOM_ATTRIBUTES%

:: del bin\cpy.exe
:: odin build cpy -out:bin\cpy.exe %DEBUG% %CUSTOM_ATTRIBUTES%

cd test
:: math 1 + 2 * 3 - 4 / 2.5 + 12345 - 67.89
:: todo
:: img test\Oil-Barrel.png
search ui_display_struct_members
search import
:: gitsync
:: cat mark.md
:: notizn
:: ls
:: cpy
cd ..
