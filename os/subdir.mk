OS_SOURCES := task.c task_hal.S
SOURCES += $(addprefix os/,$(OS_SOURCES))
