## CALC.ASM
A decimal integer calculator that supports basic arithmetic
written in 16 bit x86 assembly  
Uses MASM/TASM syntax, runs in DOSBox  
To compile:  
```
C:\CALC> MASM CALC.ASM 
C:\CALC> LINK CALC.OBJ
```  
Example usage:  
```
C:\CALC> CALC.EXE
ASSEMBLY CALCULATOR (VER 0.01)
> 1 + 1
2

> Q
C:\CALC>
```  
Supports `+`,`-`,`*`, and `/`  
