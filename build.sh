
CUSTOM_ATTRIBUTES=-custom-attribute:NOTE -custom-attribute:TODO -custom-attribute:TMP -custom-attribute:BUG -custom-attribute:UNKNOWN


odin build img -out:bin\img.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build search -out:bin\search.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build gitsync -out:bin\gitsync.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build cat -out:bin\cat.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build notizn -out:bin\notizn.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build ls -out:bin\ls.exe -vet-shadowing $CUSTOM_ATTRIBUTES

odin build cpy -out:bin\cpy.exe $CUSTOM_ATTRIBUTES

cd test
# img test\Oil-Barrel.png
search ui_display_struct_members
# gitsync
# cat mark.md
# notizn
ls
# cpy
cd ..
