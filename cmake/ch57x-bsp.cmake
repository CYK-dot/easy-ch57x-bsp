# ch57x-bsp.cmake - BSP 接口
# 对外: target_link_wch_startup(<target> [CHIP]) / wch_generate_hex(<target> [CHIP])
# 用法详见 README.md

function(_wch_resolve_chip target out_var)
    set(_opts "")
    set(_one CHIP)
    set(_multi "")
    cmake_parse_arguments(ARG "${_opts}" "${_one}" "${_multi}" ${ARGN})
    set(_chip ${ARG_CHIP})
    if(NOT _chip AND ARG_UNPARSED_ARGUMENTS)
        list(GET ARG_UNPARSED_ARGUMENTS 0 _chip)
    endif()
    if(NOT _chip)
        get_target_property(_prop ${target} WCH_CHIP)
        if(_prop)
            set(_chip ${_prop})
        elseif(DEFINED WCH_DEFAULT_CHIP)
            set(_chip ${WCH_DEFAULT_CHIP})
        else()
            message(FATAL_ERROR
                "target_link_wch_startup: no chip specified for '${target}'.\n"
                "  Use: target_link_wch_startup(${target} CH572)")
        endif()
    endif()
    set(${out_var} ${_chip} PARENT_SCOPE)
endfunction()

function(target_link_wch_startup target)
    set(_bsp "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/..")

    # ---- 芯片查表（Flash/RAM 容量 + 启动文件，数据源: WCH 官方 Link.ld）----
    # 格式: KEY VALUE KEY VALUE ...（芯片名由 _chip 单独匹配）
    set(_chip_params
        FLASH_ORIGIN 0x00000000 FLASH_LENGTH 240K
        RAM_ORIGIN   0x20000000 RAM_LENGTH   12K
        STARTUP      "${_bsp}/src/cpu/startup_CH572.S")

    _wch_resolve_chip(${target} _chip ${ARGN})

    # 查表
    if(NOT _chip STREQUAL "CH572")
        message(FATAL_ERROR
            "target_link_wch_startup: unsupported chip '${_chip}'.\n"
            "  Supported: CH572")
    endif()
    set(_params ${_chip_params})
    list(LENGTH _params _n)
    math(EXPR _n "${_n} - 1")
    foreach(_i RANGE 0 ${_n} 2)
        list(GET _params ${_i} _key)
        math(EXPR _j "${_i} + 1")
        list(GET _params ${_j} _val)
        set(${_key} ${_val})
    endforeach()

    # ---- 链接脚本: 项目自定义优先，否则模板生成 --------------------------
    if(EXISTS "${CMAKE_SOURCE_DIR}/Link.ld")
        set(_ld "${CMAKE_SOURCE_DIR}/Link.ld")
        message(STATUS "WCH: using project custom Link.ld")
    else()
        set(_ld "${CMAKE_BINARY_DIR}/wch/${_chip}.ld")
        configure_file("${_bsp}/cmake/wch_link.ld.in" "${_ld}" @ONLY)
        message(STATUS "WCH: generated ${_ld} for ${_chip}")
    endif()

    # ---- 启动文件: 项目自定义优先，否则查表 ------------------------------
    if(EXISTS "${CMAKE_SOURCE_DIR}/startup.S")
        set(_startup "${CMAKE_SOURCE_DIR}/startup.S")
        message(STATUS "WCH: using project custom startup.S")
    else()
        set(_startup "${STARTUP}")
    endif()

    target_sources(${target} PRIVATE ${_startup})
    target_link_options(${target} PRIVATE "-T${_ld}" -nostartfiles)
endfunction()

####################################################################################################
# @name wch_generate_hex
# @brief 为 elf target 生成 ihex 烧录文件（POST_BUILD），并打印各段大小
#
# @param target 可执行 target（通常已调用 target_link_wch_startup）
# @param chip   可选，芯片型号（打印芯片总 Flash/RAM 容量）
####################################################################################################
function(wch_generate_hex target)
    set(_bsp "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")
    set(_hex "${CMAKE_BINARY_DIR}/${target}.hex")

    set(_flash_total "")
    set(_ram_total "")
    if(ARGN)
        list(GET ARGN 0 _chip)
        if(_chip MATCHES "^CH572")
            set(_flash_total "240K")
            set(_ram_total "12K")
        endif()
    endif()

    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex "$<TARGET_FILE:${target}>" "${_hex}"
        COMMAND ${CMAKE_COMMAND} -P "${_bsp}/wch_size_report.cmake" --
            "$<TARGET_FILE:${target}>" "${CMAKE_SIZE}" "${target}" "${_flash_total}" "${_ram_total}"
        COMMENT "Generate ${target}.hex"
        VERBATIM)
endfunction()
