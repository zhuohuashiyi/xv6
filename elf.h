// Format of an ELF executable file
// elf文件主要包括三个部分，包括ELF文件头、程序头表、节头表
#define ELF_MAGIC 0x464C457FU  // "\x7FELF" in little endian

// File header
struct elfhdr {
  uint magic;  // 魔数，用于文件鉴定
  uchar elf[12];
  ushort type;
  ushort machine;
  uint version;
  uint entry; // 程序入口地址
  uint phoff; // 程序头表的偏移地址
  uint shoff;  // 节头表的偏移地址
  uint flags;
  ushort ehsize;  // elf头的大小
  ushort phentsize; // 程序头表项的大小
  ushort phnum;  // 程序头表项的数量
  ushort shentsize; // 节头表项的大小
  ushort shnum; // 节头表项的数量
  ushort shstrndx;
};

// Program section header
struct proghdr {
  uint type;
  uint off; // off表示本section在文件中和第一个section的起始地址的偏移
  uint vaddr; // 在内存中的虚拟地址
  uint paddr; // 在内存中的物理地址
  uint filesz; // section的文件映像的大小
  uint memsz; // section的内存映像的大小
  uint flags;
  uint align;
};

// Values for Proghdr type
#define ELF_PROG_LOAD           1

// Flag bits for Proghdr flags
#define ELF_PROG_FLAG_EXEC      1
#define ELF_PROG_FLAG_WRITE     2
#define ELF_PROG_FLAG_READ      4
