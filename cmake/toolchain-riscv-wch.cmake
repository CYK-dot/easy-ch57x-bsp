# toolchain-riscv-wch.cmake - WCH RISC-V 交叉工具链（BSP 完整方案）
# 用法与定制详见 README.md

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)

# 工具链根目录: 环境变量 > -D(cache) > BSP 默认值
if(DEFINED ENV{WCH_TOOLCHAIN_ROOT} AND NOT "$ENV{WCH_TOOLCHAIN_ROOT}" STREQUAL "")
    set(WCH_TOOLCHAIN_ROOT "$ENV{WCH_TOOLCHAIN_ROOT}"
        CACHE PATH "WCH RISC-V toolchain root directory (contains bin/)" FORCE)
elseif(NOT DEFINED WCH_TOOLCHAIN_ROOT)
    set(WCH_TOOLCHAIN_ROOT
        "C:/01_Tools/MounRiverStudio/MounRiver_Studio2/resources/app/resources/win32/components/WCH/Toolchain/RISC-V Embedded GCC12"
        CACHE PATH "WCH RISC-V toolchain root directory (contains bin/)")
endif()

if(DEFINED ENV{WCH_TOOLCHAIN_PREFIX} AND NOT "$ENV{WCH_TOOLCHAIN_PREFIX}" STREQUAL "")
    set(WCH_TOOLCHAIN_PREFIX "$ENV{WCH_TOOLCHAIN_PREFIX}"
        CACHE STRING "WCH toolchain executable prefix" FORCE)
elseif(NOT DEFINED WCH_TOOLCHAIN_PREFIX)
    set(WCH_TOOLCHAIN_PREFIX "riscv-wch-elf-"
        CACHE STRING "WCH toolchain executable prefix")
endif()

# 同步到环境变量: try_compile 子工程只加载本文件，靠环境变量继承路径
set(ENV{WCH_TOOLCHAIN_ROOT}   "${WCH_TOOLCHAIN_ROOT}")
set(ENV{WCH_TOOLCHAIN_PREFIX} "${WCH_TOOLCHAIN_PREFIX}")

# 架构参数: 构建入参（-D 传入），未传则用默认值（CH57x 为 rv32imc + bitmanip，ILP32）
if(NOT DEFINED WCH_ARCH)
    set(WCH_ARCH "rv32imc_zba_zbb_zbc_zbs")
endif()
if(NOT DEFINED WCH_ABI)
    set(WCH_ABI "ilp32")
endif()

set(WCH_BIN "${WCH_TOOLCHAIN_ROOT}/bin")

# CMake 4.x 交叉编译不自动补 .exe
set(CMAKE_C_COMPILER   "${WCH_BIN}/${WCH_TOOLCHAIN_PREFIX}gcc.exe")
set(CMAKE_ASM_COMPILER "${WCH_BIN}/${WCH_TOOLCHAIN_PREFIX}gcc.exe")
set(CMAKE_OBJCOPY      "${WCH_BIN}/${WCH_TOOLCHAIN_PREFIX}objcopy.exe")
set(CMAKE_OBJDUMP      "${WCH_BIN}/${WCH_TOOLCHAIN_PREFIX}objdump.exe")
set(CMAKE_SIZE         "${WCH_BIN}/${WCH_TOOLCHAIN_PREFIX}size.exe")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_EXECUTABLE_SUFFIX ".elf")
