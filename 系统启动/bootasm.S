#include "asm.h"
#include "memlayout.h"
#include "mmu.h"

# 该汇编程序的作用是：开启第一个CPU，切换到32位保护模式。
# 该代码保存在硬盘第一个扇区，开机后由BIOS加载到物理地址0x7c00开始的
# 一段内存，设置寄存器cs的值为0，ip寄存器的值为7c00，然后以16位的实
# 模式运行该代码

.code16                       # 表示以下代码应在16位下运行
.globl start
start:
  cli                         # 关中断，保证下面的程序段不间断地运行

  # 将三个数据段寄存器ds, es, ss的值置零
  xorw    %ax,%ax             # 异或运算，置ax=0
  movw    %ax,%ds             # 数据段寄存器
  movw    %ax,%es             # 扩展段寄存器
  movw    %ax,%ss             # 栈段寄存器

  # 设置A20地址线，因为刚开始只能使用20条地址线，通过写端口数据可以设置成所有的地址线

seta20.1:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60

  # 从实模式切换到保护模式。使用一个GDT全局描述符表来将虚拟地址
  # 直接映射到物理地址，保证在切换过程中有效的内存映射不变
  lgdt    gdtdesc
  movl    %cr0, %eax
  orl     $CR0_PE, %eax
  movl    %eax, %cr0

//PAGEBREAK!
  # Complete the transition to 32-bit protected mode by using a long jmp
  # to reload %cs and %eip.  The segment descriptors are set up with no
  # translation, so that the mapping is still the identity mapping.

  # 使用ljmp指令重载cs和eip寄存器的值完成到32保护模式的切换
  # 在保护模式下，cs等段寄存器的值作为索引从gdt表中取出对应段
  # 的起始地址，从gdt的定义可以知道，该程序中只定义了数据段和代码段，
  # 两端的起始地址都是0，所以这里物理地址相等映射到虚拟地址

  ljmp    $(SEG_KCODE<<3), $start32

.code32  # 告诉汇编器以下是32位的代码
start32:
  # 以下设置保护模式下各个数据段寄存器的值
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
  movw    $0, %ax                 # Zero segments not ready for use
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS

  # 设置栈指针，调用C函数
  movl    $start, %esp
  call    bootmain

  # If bootmain returns (it shouldn't), trigger a Bochs
  # breakpoint if running under Bochs, then loop.
  movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
  movw    %ax, %dx
  outw    %ax, %dx
  movw    $0x8ae0, %ax            # 0x8ae0 -> port 0x8a00
  outw    %ax, %dx
spin:
  jmp     spin

# GDT全局描述符表的定义
.p2align 2                                # 强制按照四字节对齐
gdt:
  SEG_NULLASM                             # null seg
  SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)   # code seg
  SEG_ASM(STA_W, 0x0, 0xffffffff)         # data seg

gdtdesc:
  .word   (gdtdesc - gdt - 1)             # sizeof(gdt) - 1
  .long   gdt                             # address gdt

