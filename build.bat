@echo off

del bin\ls.exe

odin build ls -out:bin\ls.exe

cd test
ls
cd ..
