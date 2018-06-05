#
# Copyright 2018, Data61
# Commonwealth Scientific and Industrial Research Organisation (CSIRO)
# ABN 41 687 119 230.
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(DATA61_BSD)

# This file provides helper functions for importing some of the packages contained in this repo
# into CMake targets.

cmake_minimum_required(VERSION 3.7.2)

set(RumprunPackagesDirectory ${CMAKE_CURRENT_LIST_DIR})

# Somewhat generic function for generating ExternalProject target for rumprun-packages
function(CreateRumprunPackagesExternalProject target_name rumptools_target package_name bin_location)
    cmake_parse_arguments(PARSE_ARGV 4 RUMPRUN "OUT_OF_TREE" "MAKE_TARGET" "")
    if (NOT "${RUMPRUN_UNPARSED_ARGUMENTS}" STREQUAL "")
        message(FATAL_ERROR "Unknown arguments to CreateRumprunPackagesExternalProject")
    endif()

    add_custom_target(${package_name}_rumptools_target)
    add_dependencies(${package_name}_rumptools_target ${rumptools_target})

    set(source_dir ${RumprunPackagesDirectory}/${package_name})
    if(RUMPRUN_OUT_OF_TREE)
        set(bin_dir ${CMAKE_CURRENT_BINARY_DIR}/${package_name}-build)
    else()
        set(bin_dir ${RumprunPackagesDirectory}/${package_name})
    endif()
    set(output_file ${bin_dir}/${bin_location})
    set(stamp_dir ${CMAKE_CURRENT_BINARY_DIR}/${package_name}-stamp)

    ExternalProject_Add(${target_name}
        SOURCE_DIR ${source_dir}
        BINARY_DIR ${bin_dir}
        STAMP_DIR ${stamp_dir}
        DEPENDS ${package_name}_rumptools_target
        CONFIGURE_COMMAND true
        EXCLUDE_FROM_ALL
        BUILD_COMMAND   cd ${source_dir} &&
            ${CMAKE_COMMAND} -E env PATH=$ENV{PATH}:$<TARGET_PROPERTY:${rumptools_target},RUMPRUN_TOOLCHAIN_PATH>
            BUILD_DIR=${bin_dir}
            RUMPRUN_TOOLCHAIN_TUPLE=$<TARGET_PROPERTY:${rumptools_target},RUMPRUN_TOOLCHAIN_TUPLE>
            make ${RUMPRUN_MAKE_TARGET}
        INSTALL_COMMAND true
        BUILD_ALWAYS ON
    )
    ExternalProject_Add_StepTargets(${target_name} install)

    # Add custom_command that depends on the install stamp file of ExternalProject to force stale checking of
    # bin_location until after the install step of ExternalProject has been run
    add_custom_command(
        OUTPUT ${output_file}
        COMMAND true
        DEPENDS ${target_name}-install ${stamp_dir}/${target_name}-install
        )

    set_property(TARGET ${target_name} PROPERTY RUMP_BINARIES ${output_file})

endfunction()

# Builds the redis server binary from the redis package
function(RedisRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} redis bin/redis-server MAKE_TARGET redis-server OUT_OF_TREE)
endfunction()

# Builds cjpeg from jpeg package
function(CjpegRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} jpeg build/jpeg-6a/cjpeg)
endfunction()

# Builds djpeg from jpeg package
function(DjpegRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} jpeg build/jpeg-6a/djpeg)
endfunction()

# Builds the memcached binary from the memcached package
function(MemcachedRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} memcached build/memcached)
endfunction()

# Builds nginx
function(NginxRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} nginx bin/nginx)
endfunction()

# Builds susan
function(SusanRumprunPackages target_name rumptools_target)
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} susan build/susan.o)
endfunction()
