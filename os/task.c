#include "task.h"
#include "stm32f4xx.h"
#include "core_cm4.h"
#include <string.h>

#define PERIOD      (100)

#define SYST_CSR    (*((volatile uint32_t*)0xE000E010))
#define SYST_RVR    (*((volatile uint32_t*)0xE000E014))
#define SYST_CVR    (*((volatile uint32_t*)0xE000E018))
#define ICSR (* ((volatile uint32_t*)0xe000ed04))
#define PENDSVSET (1 << 28)

struct task {
    uint8_t* sp;
};

struct task tasks[2];
volatile unsigned int task_index = 0;
volatile unsigned int task_count = 0;
volatile void* task_sp = NULL;
volatile int os_ticks = 0;

void os_task_add(void (*func)(void), void* stack, size_t stack_size) {
    struct task* t = &tasks[task_count++];
    t->sp = stack;
    t->sp += stack_size;
    t->sp -= 16 * sizeof(void*);

    for (int i = 0; i < 14; i++) {
        ((void**) t->sp)[i] = NULL;
    }
    ((void**) t->sp)[14] = func; // PC
    ((uint32_t*) t->sp)[15] = 0x01000000; // xPSR
}

void os_start(void) {
    __disable_irq();

    SYST_CSR = 0;
    SYST_CVR = 0;

    SYST_RVR = SystemCoreClock / PERIOD;
    SYST_CSR = 0x7;

    task_sp = &tasks[0].sp;

    __enable_irq();
    __enable_fault_irq();

    asm volatile("svc 0");
}

void os_switch_tasks(void) {
    task_index = (task_index + 1) % task_count;
    task_sp = &tasks[task_index].sp;
}

__attribute__((naked)) void SVC_Handler(void) {
    asm volatile (
            "ldr r1, task_sp_addr2\n"
            "ldr r1, [r1]\n"
            "ldr r0, [r1]\n"
            "ldmia r0!, {r4-r11}\n"
            "msr psp, r0\n"
            "isb\n"
            "orr lr, #0xd\n"
            "bx lr\n"
            ".align 4\n"
            "task_sp_addr2: .word task_sp");
}

__attribute__((naked)) void PendSV_Handler(void) {
    asm volatile (
            "mrs r0, psp\n"
            "isb\n"
            "stmdb r0!, {r4-r11}\n"
            "ldr r1, task_sp_addr\n"
            "ldr r1, [r1]\n"
            "str r0, [r1]\n"
            "stmdb sp!, {lr}\n"
            "bl os_switch_tasks\n"
            "ldmia sp!, {lr}\n"
            "ldr r1, task_sp_addr\n"
            "ldr r1, [r1]\n"
            "ldr r0, [r1]\n"
            "ldmia r0!, {r4-r11}\n"
            "msr psp, r0\n"
            "isb\n"
            "bx lr\n"
            ".align 4\n"
            "task_sp_addr: .word task_sp");
}

void SysTick_Handler(void) {
    __disable_irq();

    os_ticks++;
    if ((os_ticks % (PERIOD / 2)) == 0) {
        ICSR = PENDSVSET;
    }

    __enable_irq();
}
