  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb

.extern task_old_stack
/*
SVC_Handler:
	stm sp!, {r0-r12, lr}
	bl os_switch_tasks
	ldr r12, _task_old_stack
	/*89str r1, [r12, #0]
	ldr r0, task_new_stack
	ldr sp, [r12]
	ldm sp!, {r0-r12, lr}*/

