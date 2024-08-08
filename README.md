# term-tools

tools / commands for the terminal, written in odin <br>

__! only tested/works on windows__ <br>
__! requires utf-8 terminal, not the pre-installed command prompt on windows__ <br>
__! requires NerdFont for icons__

## ls
replacement for `dir` command <br>
lists all files in directory / subdirectories <br>
´´´
  -w:XX -> set max line width, min is 24
  -d:XX -> set sub dir depth, min is 0
  -f:XX -> set max files shown in subdirs, <=0 means no cap
  -dir  -> only show dirs
  
  example:
    ls
    ls path/to/dir
    ls -w:30 
    ls -w:30 -d:2 -f:0
    ls path/to/dir -w:30 -d:2 -f:0
    ls path\to\dir -w:30 -d:2 -f:0
    ls -dir -d:100
´´´
<br>
<img src="https://github.com/phil-stein/term-tools/blob/main/files/ls_04.PNG" alt="logo" width="300">


