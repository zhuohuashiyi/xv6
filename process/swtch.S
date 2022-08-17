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
# 从栈顶分别取出两个参数，分别是指向调度函数上下文和待运行进程上下文的指针
# 将两个指针值分别保存在eax和edx寄存器中
  movl 4(%esp), %eax
  movl 8(%esp), %edx

  # Save old callee-saved registers
  # 将调度函数的相关寄存器压入栈中保存起来
  pushl %ebp
  pushl %ebx
  pushl %esi
  pushl %edi

  # Switch stacks
  movl %esp, (%eax) # 将此时的栈指针保存给eax寄存器
  movl %edx, %esp # 切换栈顶指针

  # 从栈中取出新的进程的寄存器值
  popl %edi
  popl %esi
  popl %ebx
  popl %ebp
  ret
