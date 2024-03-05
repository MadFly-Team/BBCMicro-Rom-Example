\*---------------------------------------------------------------------------
\  file:           SHelpROM.asm
\  Description:    A simple ROM image containining example commands
\  Date:           2024-02-20 10:20:00
\  Copywrite:      (C) 2024 Neil Beresford
\
\  Notes:
\  Assember    - BeebASM
\  Emulator    - BeebEm tested, works.
\  BBC Master  - Acorn MOS 3.5/MOS 3.2 (TESTED)
\  Language    - 6502 Assembly
\
\  Instruction:
\  Use *SRLOAD or similar to load the ROM image into the BBC Micro
\  Type *HELP to display the interactive yes/no for more help text
\  The following commands are available:
\     *HELP          - Display the help text
\     *HELP COMMANDS - More detailed help text
\     *CMDA          - CMDA processed message
\     *CMDB          - CMDB processed message
\     *CMDC          - CMDC processed message
\
\ Installation: (Example for the BBC Master)
\     *SRLOAD HELPROM 8000 n    (where n is the ROM bank)
\     Ctrl-Break to initialise the ROM
\     *HELP to display the help text
\
\---------------------------------------------------------------------------

\---------------------------------------------------------------------------
\ Directives
\---------------------------------------------------------------------------

CPU 0 \ 6502 CPU ( to run on all flavours of the BBC Micro )

\---------------------------------------------------------------------------
\ Define the system calls
\---------------------------------------------------------------------------

\ system calls
osnewl = &FFE7  \ OSNEWL - New line
oswrch = &FFEE  \ OSWRCH - Write character to screen
osasci = &FFE3  \ OSASCI - Write ASCII string to screen
osrdch = &FFE0  \ OSRDCH - Read character from keyboard

\ Service call IDs
SERVICE_HELP = 9  \ HELP service call
SERVICE_CMD  = 4  \ Command service call

\ ZERO PAGE usage
TEMPPTRL = &A8   \ Temporary pointer low byte
TEMPPTRH = &A9   \ Temporary pointer high byte
TEMPSTORE= &AA   \ Temporary storage
COMLINE  = &F2   \ Command line buffer lowbyte

\---------------------------------------------------------------------------
\ MACROS
\---------------------------------------------------------------------------

\ PUSHALL - Push all registers onto the stack
MACRO PUSHALL
    STA TEMPSTORE
    PHA
    TXA
    PHA
    TYA
    PHA
    LDA TEMPSTORE
ENDMACRO

\ POPALL - Pop all registers from the stack
MACRO POPALL
    PLA
    TAY
    PLA
    TAX
    PLA
ENDMACRO

\SETPTR - Sets low and high to be the low and high bytes of ptr
MACRO SETPTR ptr, low, high
    LDA #ptr MOD 256
    STA low
    LDA #ptr DIV 256
    STA high
ENDMACRO

\---------------------------------------------------------------------------
\ Variables
\---------------------------------------------------------------------------

\---------------------------------------------------------------------------
\ Start of code
\---------------------------------------------------------------------------

    ORG     &8000                 \ Start of ROM address image, when paaged in

\---------------------------------------------------------------------------

.start                            \ Start of the ROM image

\---------------------------------------------------------------------------
\ HEADER for the ROM
\---------------------------------------------------------------------------
    EQUB 0                      \ ROM type\ Not a language ROm
    EQUW 0                      \ 0 as no JMP laanguage needed
    JMP service                 \ Jump to the service routine
    EQUB &82                    \ ROM type Service entry, 6502 code
    EQUB offset MOD 256         \ Offset to the Copywrite message
    EQUB 1                      \ Binary version number
.title                          \ Title of the ROM
    EQUS "HELPROM (Neil Beresford)"
    EQUB 0
.version                        \ Version number 
    EQUS " 1.0.1"
    EQUB 0 
.offset                         \ Copywrite message
    EQUB 0
    EQUS "(C) 2024 Neil Beresford" \ Format of this message is important
    EQUB 0                         \ termination of the message  

\---------------------------------------------------------------------------
\ Service - Handle the service request
\---------------------------------------------------------------------------
.service                        \ Service routine
    PUSHALL
    CMP #SERVICE_HELP           \ HELP servvice request 
    BEQ help
    CMP #SERVICE_CMD            \ Unknow command, passed to ROM is see if it haandles it.
    BEQ checkCommands
    POPALL
    RTS

\---------------------------------------------------------------------------
\ Service routines - Help
\ Y is setup and used to index the command line buffer
\---------------------------------------------------------------------------
.help
    LDA (COMLINE),Y             \ Get the first character
    CMP #13                     \ Is it a carriage return
    BNE check                   \ No, check for command
    JSR osnewl                  \ Yes, new line
    SETPTR helpMessage, TEMPPTRL, TEMPPTRH \ Display the help message
    JSR printMessage

\---------------------------------------------------------------------------
\ Finished, return
.done
    POPALL
    RTS

\ ---------------------------------------------------------------------------
\ Check for command
\ Y is used as the index into the command line buffer
\---------------------------------------------------------------------------
.check
    LDX #&FF                \ Set X to &FF  Check for *HELP COMMANDS
    DEY 
.checkloop
    INX
    INY
    LDA (COMLINE),Y         \ Get the next character from the command line buffer
    AND #&DF                \ Convert to upper case
    CMP command,X           \ Compare with the command
    BEQ checkloop           \ If the same, check next character
    LDA command,X           \ Get the next character from the command
    CMP #&FE                \ Is it the end of the command
    BEQ foundCommand
    POPALL                  \ Not found, return
    RTS
\ ---------------------------------------------------------------------------
\ Found Command
\ This is called if '*HELP COMMANDS' is passed to the ROM
\---------------------------------------------------------------------------
.foundCommand
    SETPTR message, TEMPPTRL, TEMPPTRH
    JSR printMessage
    POPALL
    LDA #0
    RTS

\---------------------------------------------------------------------------
\ Check through the list of commands
\---------------------------------------------------------------------------
.checkCommands
    LDX #&FF            \ Set X to &FF  used to index our commaads list
    DEY                 \ decrement Y to point to the first character of the command
    TYA                 \ push Y onto the stack
    PHA
.checkCommandsLoop
    INX    
    INY
    LDA (COMLINE),Y     \ get the next character from the command line buffer
    AND #&DF            \ convert to upper case
    CMP commands,X      \
    BEQ checkCommandsLoop
    LDA commands,X      \ check the next byte to see of a good address
    BMI  address
.moveon
    INX                 \ move to the next command
    LDA commands,X
    BPL moveon          \ if not the end of the commands keep incrementing
    BNE notEnd          \ if not zero reloops to the next command
    PLA                 \ if zero, end of list, pop Y and return
    TAY
    JMP done
.notEnd
    INX                 \ put commmand list index to correct position
    PLA                 \ pop Y
    TAY                 \ .. and reloop
    PHA
    JMP checkCommandsLoop

.address
    CMP #&FF            \ Is it the end of the commands list
    BNE doCall          \ if not, execute the command function
    PLA                 \ if it is, pop Y and return    
    TAY
    JMP done
.doCall
    STA TEMPPTRH        \ A points to the high byte of the command function
    INX                 \ store at ZPAGE TEMPPTRH
    LDA commands,X      \ A now points to the low byte of the command function
    STA TEMPPTRL        \ store at ZPAGE TEMPPTRL
    JMP (TEMPPTRL)      \ Jump to the command function

\---------------------------------------------------------------------------
\ Misc functionality
\ print Message TEMPPTRL.TEMPPTRH ptr String, zero terminated
\---------------------------------------------------------------------------
.printMessage                     \ Display message on screen
{
    LDY #&FF
.loop
    INY
    LDA (TEMPPTRL),Y
    BEQ end
    JSR osasci
    JMP loop
.end
    RTS
}

\---------------------------------------------------------------------------
\ Commands
\---------------------------------------------------------------------------

\---------------------------------------------------------------------------
\ CMDA function
\ Called when the command '*CMDA' is passed to the ROM
.cmdAprocess
    SETPTR cm1, TEMPPTRL, TEMPPTRH \ Just display message and return
    JSR printMessage
    PLA                            \ sort out the stack
    TAY
    POPALL
    LDA #0
    RTS
\---------------------------------------------------------------------------
\ CMDB function
\ Called when the command '*CMDB' is passed to the ROM
.cmdBprocess
    SETPTR cm2, TEMPPTRL, TEMPPTRH \ Just display message and return
    JSR printMessage
    PLA                            \ sort out the stack
    TAY
    POPALL
    LDA #0
    RTS
\---------------------------------------------------------------------------
\ CMDC function
\ Called when the command '*CMDC' is passed to the ROM
.cmdCprocess
    SETPTR cm3, TEMPPTRL, TEMPPTRH \ Just display message and return
    JSR printMessage
    PLA                            \ sort out the stack
    TAY
    POPALL
    LDA #0
    RTS

\---------------------------------------------------------------------------
\ Data
\---------------------------------------------------------------------------

.command
    EQUS   "COMMANDS"
    EQUB   &FE

.message
    EQUB   13
    EQUS   "HELPROM 1.0 (C) Neil Beresford", 13,13
    EQUS   "This ROM contains the following commands -", 13, 13
    EQUS   "  CMDA - description for CMDA", 13
    EQUS   "  CMDB - description for CMDB", 13
    EQUS   "  CMDC - description for CMDC", 13
    EQUB   13, 0

.helpMessage
    EQUS   "HELPROM 1.0 (C) Neil Beresford", 13
    EQUS   "  COMMANDS", 13
    EQUB   0

.commands
    EQUS "CMDA"
    EQUB cmdAprocess DIV 256
    EQUB cmdAprocess MOD 256
    EQUS "CMDB"
    EQUB cmdBprocess DIV 256
    EQUB cmdBprocess MOD 256
    EQUS "CMDC"
    EQUB cmdCprocess DIV 256
    EQUB cmdCprocess MOD 256
    EQUB &FF

.cm1
    EQUS "CMDA - Processed", 13, 0
.cm2
    EQUS "CMDB - Processed", 13, 0
.cm3
    EQUS "CMDC - Processed", 13, 0

\---------------------------------------------------------------------------

.end

\---------------------------------------------------------------------------

SAVE "HELPROM", start, end

\---------------------------------------------------------------------------
\  End of file: SHelpROM.asm
\-------------------------------------------------------------------------- 
