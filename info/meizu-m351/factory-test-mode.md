Code for factory test mode will not be built for `RECOVERY_KERNEL`.

`arch/arm/mach-exynos/board-m6x-factory-test.c` provides 2 function pointers: `mx_is_factory_test_mode`, `mx_set_factory_test_led`

- There is not default implementation for them
- It will not cause memory access error because modules depending on them will also not be built for `RECOVERY_KERNEL`

There are 4 GPIO pins for factory test mode

- 1 for factory mode in general
- 1 for bt test mdoe
- 1 for gps test mode
- 1 for driving led of the mode