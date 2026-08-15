# ch57x-bsp

CH57x 系列（CH572）的 CMake BSP 基座，以子目录形式被应用工程引用（git-submodule 形态）。
基于 WCH CH572EVT 官方标准库封装。

## 目录结构

```
ch57x-bsp/
├── CMakeLists.txt                 # 静态库 libwch_periph.a + 接口注入
├── inc/                           # 0层头文件（CH57x_*.h / CH572SFR.h / core_riscv.h / ISP572.h）
├── src/
│   ├── cpu/                       # 内核适配（CH57x_sys.c / startup_CH572.S）
│   └── peri/                      # 外设驱动（CH57x_*.c）
├── lib/                           # WCH 预编译闭源库（libISP572.a / libCH572BLE_PERI.a）
└── cmake/
    ├── ch57x-bsp.cmake            # 对外cmake接口实现
    ├── toolchain-riscv-wch.cmake  # 交叉工具链声明，外部无需感知
    ├── wch_link.ld.in             # 链接脚本模板，外部无需感知
    └── wch_size_report.cmake      # 段大小打印脚本，外部无需感知
```

## 使用方法

### step1. 设置环境变量
工具链路径设置到环境变量 `WCH_TOOLCHAIN_ROOT`（MounRiver Studio 自带：
`resources\app\resources\win32\components\WCH\Toolchain\RISC-V Embedded GCC12`）。

### step2. 在项目中引用BSP库

单 elf、无 bootloader 场景，使用默认链接脚本与启动汇编：

```cmake
cmake_minimum_required(VERSION 3.20)
project(my_app C ASM)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/ch57x-bsp/cmake/toolchain-riscv-wch.cmake)
add_subdirectory(ch57x-bsp)

add_executable(my_app.elf src/main.c)
target_link_libraries(my_app.elf PRIVATE wch_periph)   # 链接bsp库（含 ISP + BLE 闭源库）
target_link_wch_startup(my_app.elf CH572)              # 注入启动文件 + 链接脚本
wch_generate_hex(my_app.elf CH572)                     # 生成 hex + 打印各段大小
```

多段分散加载场景：链接 `wch_periph` 静态库即可（不注入启动/链接脚本）。

### step3. 构建

```bash
cmake -B build -G "MinGW Makefiles"
cmake --build build
```

产物：`build/my_app.elf`、`build/my_app.hex`。

## 对外接口

| 接口 | 说明 |
|---|---|
| `target_link_wch_startup(<target> [CHIP])` | 注入启动文件 + 链接脚本（+ 必要的 -nostartfiles） |
| `wch_generate_hex(<target> [CHIP])` | 生成 hex 并打印各段大小 |

## 支持芯片

| 芯片 | Flash | RAM |
|---|---|---|
| CH572 | 240K | 12K |

## 定制

- 链接脚本 / 启动文件：应用工程根目录放自己的 `Link.ld` / `startup.S`，自动优先
- 时钟频率：`SetSysClock(CLK_SOURCE_HSE_PLL_xxMHz)`，见 `CH57x_clk.h`

## License

本仓库为**双许可**结构：

- 本仓库原创内容（CMake 构建系统、封装接口、示例代码、文档）：**GPLv3**，见 `LICENSE`
- WCH 官方标准库源码（`inc/`、`src/`）与预编译库（`lib/`）：遵循**沁恒原始许可**
  （Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.，
  仅限用于沁恒微控制器），见 `LICENSE-WCH.txt`
