#include "stm32f4xx_rcc.h"
#include "stm32f4xx_gpio.h"

#include "os/task.h"

#include <stdint.h>

#define LED_PORT    GPIOD
#define LED_PIN     GPIO_Pin_12

uint8_t stack_led_on[256] __attribute__((aligned(8)));
uint8_t stack_led_off[256] __attribute__((aligned(8)));

void task_led_on(void) {
    while (1) {
        LED_PORT->BSRRL |= LED_PIN;
    }
}

void task_led_off(void) {
    while (1) {
        LED_PORT->BSRRH |= LED_PIN;
    }
}

int main(void) {
    RCC->AHB1ENR |= RCC_AHB1Periph_GPIOD;
    LED_PORT->MODER |= 0x01000000;

    os_task_add(task_led_on, stack_led_on, sizeof(stack_led_on));
    os_task_add(task_led_off, stack_led_off, sizeof(stack_led_off));
    os_start();
}
