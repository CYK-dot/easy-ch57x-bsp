# ch57x-bsp/CMakeLists.txt - CH57x BSP 基座（被应用工程 add_subdirectory 引用）
# 用法详见 README.md

cmake_minimum_required(VERSION 3.20)

get_filename_component(WCH_BSP_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
if(NOT DEFINED WCH_ARCH)
    message(FATAL_ERROR
        "ch57x-bsp: WCH_ARCH is not defined.\n"
        "  Must configure with BSP toolchain file, e.g.\n"
        "  cmake -DCMAKE_TOOLCHAIN_FILE=<bsp>/cmake/toolchain-riscv-wch.cmake ...")
endif()

include(${WCH_BSP_DIR}/cmake/ch57x-bsp.cmake)

# ---- 静态库 libwch_periph.a -------------------------------------------------
add_library(wch_periph STATIC
    ${WCH_BSP_DIR}/src/cpu/CH57x_sys.c
    ${WCH_BSP_DIR}/src/peri/CH57x_clk.c
    ${WCH_BSP_DIR}/src/peri/CH57x_cmp.c
    ${WCH_BSP_DIR}/src/peri/CH57x_flash.c
    ${WCH_BSP_DIR}/src/peri/CH57x_gpio.c
    ${WCH_BSP_DIR}/src/peri/CH57x_i2c.c
    ${WCH_BSP_DIR}/src/peri/CH57x_keyscan.c
    ${WCH_BSP_DIR}/src/peri/CH57x_pwm.c
    ${WCH_BSP_DIR}/src/peri/CH57x_pwr.c
    ${WCH_BSP_DIR}/src/peri/CH57x_spi.c
    ${WCH_BSP_DIR}/src/peri/CH57x_timer.c
    ${WCH_BSP_DIR}/src/peri/CH57x_uart.c
    ${WCH_BSP_DIR}/src/peri/CH57x_usbdev.c
    ${WCH_BSP_DIR}/src/peri/CH57x_usbhostBase.c
    ${WCH_BSP_DIR}/src/peri/CH57x_usbhostClass.c
)

target_include_directories(wch_periph PUBLIC ${WCH_BSP_DIR}/inc)

# 契约选项: 编译侧 PRIVATE+INTERFACE（库与使用者都要分节才能裁剪）
set(_contract_compile
    "-march=${WCH_ARCH}"
    "-mabi=${WCH_ABI}"
    -mcmodel=medany
    -msmall-data-limit=8
    -mno-save-restore
    -ffunction-sections
    -fdata-sections
    -fno-common)
target_compile_options(wch_periph PRIVATE ${_contract_compile})
target_compile_options(wch_periph INTERFACE ${_contract_compile})

# 契约选项: 链接侧（--gc-sections 与 function-sections 配套）
target_link_options(wch_periph INTERFACE
    "-march=${WCH_ARCH}"
    "-mabi=${WCH_ABI}"
    -mcmodel=medany
    -msmall-data-limit=8
    -mno-save-restore
    -Xlinker --gc-sections)

# ---- 闭源库（黑盒，无源码，随 wch_periph 一并链接）---------------------------
# 1) libISP572.a: CH57x_common.h 无条件包含 ISP572.h，CH57x_sys.c 的
#    SYS_ResetExecute / HardFault_Handler 直接调用 FLASH_EEPROM_CMD，
#    该符号仅由此库提供 —— 系统必需。
# 2) libCH572BLE_PERI.a: BLE 协议栈，操作蓝牙外设的唯一途径（无替代实现）
#    —— 功能必需。即使未用到 BLE，静态库只在符号被引用时拉入，无体积副作用。
target_link_libraries(wch_periph INTERFACE
    ${WCH_BSP_DIR}/lib/libISP572.a
    ${WCH_BSP_DIR}/lib/libCH572BLE_PERI.a)

# ---- 可选闭源库（BLE 协议栈等）: 按需用 wch_link_vendor_lib() 链接 ----------
