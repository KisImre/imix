#ifndef OS_TASK_H_
#define OS_TASK_H_

#include <stddef.h>

void os_task_add(void (*func)(void), void* stack, size_t stack_size);
void os_start(void);

#endif /* OS_TASK_H_ */
