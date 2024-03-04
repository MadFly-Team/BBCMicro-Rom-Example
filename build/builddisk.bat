@echo off
@echo "Building disk image..."
@beebasm -i ..\src\SHelpROM.asm -do SHelpRom.ssd -opt 2 -v > build.log
@echo "All done!

