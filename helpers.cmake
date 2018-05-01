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
function(CreateRumprunPackagesExternalProject target_name rumptools_target package_name make_target bin_location)

    add_custom_target(${package_name}_rumptools_target)
    add_dependencies(${package_name}_rumptools_target ${rumptools_target})

    set(source_dir ${RumprunPackagesDirectory}/${package_name})
    set(bin_dir ${CMAKE_CURRENT_BINARY_DIR}/${package_name}-build)
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
            make ${make_target}
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
    CreateRumprunPackagesExternalProject(${target_name} ${rumptools_target} redis redis-server bin/redis-server)
endfunction()
