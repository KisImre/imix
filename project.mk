TARGET += -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16

DEFINES += STM32F40_41xxx
DEFINES += USE_STDPERIPH_DRIVER ARM_MATH_CM4
DEFINES += __FPU_PRESENT=1
DEFINES += HSE_VALUE=8000000

CFLAGS += -O2 -Wall -Werror -fno-strict-aliasing
CXXFLAGS += -O2 -Wall -Werror -fno-strict-aliasing -fno-exceptions -fno-rtti

INCLUDE_DIRS += .
INCLUDE_DIRS += config

LIB_DIRS += /usr/arm-none-eabi/lib/thumb/v7e-m+fp/hard/

LIBS += m
LIBS += c

LDFLAGS += -u _printf_float
#LDFLAGS += -specs=/usr/arm-none-eabi/lib/thumb/v7e-m+fp/hard/nano.specs
#LDFLAGS += -specs=/usr/arm-none-eabi/lib/thumb/v7e-m+fp/hard/nosys.specs

STM32_USB_OTG_OPTIONS += STM32_USB_BSP_STM32F4XX

SOURCES += main.cpp
