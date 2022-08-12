# Context switch
#
#   void swtch(struct context **old, struct context *new);
# 
# Save the current registers on the stack, creating
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.
# 进程切换，主要是上下文切换
.globl swtch
swtch:
# 以下两步是对两个函数参数old、和new的处理
  movl 4(%esp), %eax
  movl 8(%esp), %edx

  # Save old callee-saved registers
  # 将当前进程（旧的）进程的相关寄存器压入栈中保存起来
  pushl %ebp
  pushl %ebx
  pushl %esi
  pushl %edi

  # Switch stacks
  movl %esp, (%eax)
  movl %edx, %esp

  # 从栈中取出新的进程的寄存器值
  popl %edi
  popl %esi
  popl %ebx
  popl %ebp
  ret
