@echo off

del bin\ls.exe
odin build ls -out:bin\ls.exe -vet-shadowing

:: del bin\cpy.exe
:: odin build cpy -out:bin\cpy.exe

cd test
ls
:: cpy
cd ..
