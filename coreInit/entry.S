# The xv6 kernel starts executing in this file. This file is linked with
# the kernel C code, so it can refer to kernel symbols such as main().
# The boot block (bootasm.S and bootmain.c) jumps to entry below.
# xv6内核从这里开始执行，该文件会被链接到内核c程序，所以这里也可以调用c函数比如main.
# 执行bootasm.S和bootmain.c后，开始执行该程序    
# Multiboot header, for multiboot boot loaders like GNU Grub.
# http://www.gnu.org/software/grub/manual/multiboot/multiboot.html
#
# Using GRUB 2, you can boot xv6 from a file stored in a
# Linux file system by copying kernel or kernelmemfs to /boot
# and then adding this menu entry:
#
# menuentry "xv6" {
# 	insmod ext2
# 	set root='(hd0,msdos1)'
# 	set kernel='/boot/kernel'
# 	echo "Loading ${kernel}..."
# 	multiboot ${kernel} ${kernel}
# 	boot
# }

#include "asm.h"
#include "memlayout.h"
#include "mmu.h"
#include "param.h"

# Multiboot header.  Data to direct multiboot loader.
.p2align 2
.text
.globl multiboot_header
multiboot_header:
  #define magic 0x1badb002
  #define flags 0
  .long magic
  .long flags
  .long (-magic-flags)

# By convention, the _start symbol specifies the ELF entry point.
# Since we haven't set up virtual memory yet, our entry point is
# the physical address of 'entry'.
.globl _start  // 按照约定，_start标签是elf文件的入口地址
_start = V2P_WO(entry)  //V2P_WO将虚拟地址转换成对应的物理地址

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  # CR4_PSE为0x00000010,而cr4寄存器低第二为PSE，允许页容量大小扩展位
  # 该值为1时，允许页容量为4MB,为0，只允许页容量为4kb
  # cr4寄存器中的值通过和CR4_PSE做按位或，其PSE位一定变成1
  # 所以这里实现了分页机制的页容量扩展到4Mb
  movl    %cr4, %eax
  orl     $(CR4_PSE), %eax 
  movl    %eax, %cr4
  # Set page directory
  # cr3寄存器保存页目录表的地址
  movl    $(V2P_WO(entrypgdir)), %eax
  movl    %eax, %cr3
  # Turn on paging.
  # cr0寄存器的最高位为PG，控制分页，为1是开启分页，否则关闭分页
  # cr寄存器的16位为WP，写保护，为1是会禁止超级用户程序修改普通用户程序
  # CR0_PG 和CR0_WP分别为0x10000000和0x00010000
  # 两者做按位或在和cro寄存器做按位或，即设置PG和WP位为1

  movl    %cr0, %eax
  orl     $(CR0_PG|CR0_WP), %eax
  movl    %eax, %cr0

  # 设置堆栈指针，堆栈往下生长
  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  # 通过jmp命令跳转到main.c中的main函数执行
  mov $main, %eax
  jmp *%eax

.comm stack, KSTACKSIZE
