// 这也是bootloader的一部分，在bootasm.S程序将系统设置为32位保护模式后
// 调用bootmain函数，负责将硬盘中ELF格式的内核镜像加载到内存中
#include "types.h"
#include "elf.h"
#include "x86.h"
#include "memlayout.h"

#define SECTSIZE  512

void readseg(uchar*, uint, uint);

// 从bootmain.s跳转到该函数执行
void
bootmain(void)
{
  struct elfhdr *elf;
  struct proghdr *ph, *eph;
  void (*entry)(void);  // 声明一个无参数无返回值的函数指针
  uchar* pa;
 // elf文件的header(对应结构体elfhdr)加载在内存地址0x10000（在Makefile文件中定义）处
  elf = (struct elfhdr*)0x10000;  

//以下函数读取elf文件的第一页
  readseg((uchar*)elf, 4096, 0);

  // 判断该文件是否是elf文件
  if(elf->magic != ELF_MAGIC)
    return;  // 如果不是，返回bootasm.S，由其处理错误

  // Load each program segment (ignores ph flags).
  // 加载内核中的每一个程序段
  // ph表示每一个程序头表的起始地址
  ph = (struct proghdr*)((uchar*)elf + elf->phoff);
  eph = ph + elf->phnum; // eph表示程序头表的末尾地址
  for(; ph < eph; ph++){ // ph遍历程序头表的每一项
    pa = (uchar*)ph->paddr;   // pa则表示该段在内存中的物理地址
    readseg(pa, ph->filesz, ph->off);
    if(ph->memsz > ph->filesz)
    // stosb在这里将0填充到该section在内存中多余的地址
      stosb(pa + ph->filesz, 0, ph->memsz - ph->filesz);
  }

  // 通过elf文件读取内核入口
  // 将控制权交由内核
  // elf->entry的值为0x10000c,即entry.S中的_start标签地址
  // 所以这里跳转到entry.S中开始执行内核代码
  entry = (void(*)(void))(elf->entry);
  entry();
}

// 等待disk可用，一直阻塞到硬盘可用再返回
void
waitdisk(void)
{
  // Wait for disk ready.
 // inb是一个汇编嵌入函数，其嵌入了in指令
 // 这里即从0x1F7端口读取一个值
 // 如果硬盘内部在操作，读取的值从低到高第8位为1
 // 如果硬盘就绪，则该位为0，且同时置第4位为1，即0*1*****的形式
 // 而0xC0为10100000，两者按位与运算得到0x40
  while((inb(0x1F7) & 0xC0) != 0x40)
    ;
}

// 读取等offset个扇区到内存地址起始为dst位置处
void
readsect(void *dst, uint offset)
{
  // Issue command.
  waitdisk();
  // 同inb,outb表示往某个端口输出数据
  // 0x1F2到0x1F7都是命令端口，用来控制读取参数
  // 设置读取扇区数为1，硬盘读写只能整个扇区读写
  outb(0x1F2, 1);  
  // 以下四行设置读取的扇区序号，因为扇区读写是连续的，给出起始扇区号即可
  // 而扇区号是28位的，需要分成四段，分别写入以下四个端口号 
  outb(0x1F3, offset);
  outb(0x1F4, offset >> 8);
  outb(0x1F5, offset >> 16);
  outb(0x1F6, (offset >> 24) | 0xE0);
  // 0x1F7也是命令端口，设置为读扇区命令
  outb(0x1F7, 0x20);  // cmd 0x20 - read sectors

  // Read data.
  waitdisk();
  // 0x1F0是数据端口
  
  insl(0x1F0, dst, SECTSIZE/4);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
// 从内核的offset位置开始读取count个byte到物理地址pa开始的一段内存中
void
readseg(uchar* pa, uint count, uint offset)
{
  uchar* epa;
 
  // epa是我们读取的内存地址终点
  epa = pa + count;

  // Round down to sector boundary.
  // 因为我们只能整个扇区读写，所以我们读取的有效数据在读取的第一个扇区的offset % SECTSIZE处
  pa -= offset % SECTSIZE;

  // Translate from bytes to sectors; kernel starts at sector 1.
  // 将以字节为单位的offset装换成以sector为单位
  // 即计算offset在第几个扇区（从1开始计数）
  offset = (offset / SECTSIZE) + 1;

  // If this is too slow, we could read lots of sectors at a time.
  // We'd write more to memory than asked, but it doesn't matter --
  // we load in increasing order.
  for(; pa < epa; pa += SECTSIZE, offset++)
    readsect(pa, offset);
}
