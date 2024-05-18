# L3d engine
A little 3d graphics engine in x86-64 ASM\
Updating this desc finally!!! 🎉🎉🎉\
For now, it will just have some instructions on how to assemble this urself if u want to / if the given executable doesnt work\
**Step 1:** Make sure u have NASM cli tool installed, this is usually under the package name 'nasm' on linux distros\
**Step 2:** Make sure u have ld installed also, this is probably installed by default\
**Step 3:** In the terminal, type ``ld --verbose > linker.ld``
**Step 4:** Open linker.ld in your favorite text editor, then before the line ``SECTIONS {``, insert the lines 
```ld
PHDRS
{
    text PT_LOAD FILEHDR PHDRS FLAGS(07); /* 07 -> Read, Write, and Execute */
    data PT_LOAD FLAGS(06);               /* 06 -> Read and Write */
    rodata PT_LOAD FLAGS(04);             /* 04 -> Read-Only */
    bss PT_LOAD FLAGS(06);                /* 06 -> Read and Write */
}
```
**Step 5:** Save this file, and then cd to the location of the source .asm scripts\
**Step 6:** type the command ``nasm -f elf64 -o L3d.out && ld -T linker.ld -o L3d L3d.out`` (make sure the path to linker.ld is correct)\
After this, L3d should be executable to run in your terminal!
