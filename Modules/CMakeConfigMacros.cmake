# Copyright (c) 2021 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

macro (create_cmake_config module)
  include(CMakePackageConfigHelpers)
  include(GNUInstallDirs)

  cmake_parse_arguments(ARG
    ""
    ""
    "PKG_CONF_FILE;TARGETS;INCLUDE_DIRS;VERSION;COMPONENT"
    ${ARGN}
  )

  # Capitalize the first letter of the module name
  string(SUBSTRING ${module} 0 1 first-letter)
  string(TOUPPER ${first-letter} first-letter)
  STRING(REGEX REPLACE "^.(.*)" "\\1" module_2 ${module})
  unset(module)
  set(module_name "${first-letter}${module_2}")

  # set installation path
  set(CMAKECONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${module}")

  if (NOT ARG_TARGETS)
    set(ARG_TARGETS "${module}-targets")
  endif()

  if (NOT ARG_COMPONENT)
    set(ARG_COMPONENT "cmake-config")
  endif()

  if (NOT ARG_PKG_CONF_FILE)
    set(ARG_PKG_CONF_FILE "${module}-config.cmake")
  endif()

  if (ARG_PACKAGE_REGISTRY)
    if (ARG_INCLUDE_DIRS)
      set(${module_name}_INCLUDE_DIRS "${ARG_INCLUDE_DIRS}")
    endif()

    # create in-source module config file
    configure_package_config_file(
      ${ARG_PKG_CONF_FILE}.in
      ${ARG_PKG_CONF_FILE}
      INSTALL_DESTINATION ${CMAKECONFIG_INSTALL_DIR}
      PATH_VARS ${module_name}_INCLUDE_DIRS
    )

    # export the export group to be used locally
    export (
      EXPORT ${ARG_TARGETS}
      NAMESPACE ${module_name}::
      FILE ${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGETS}.cmake
    )

    # add module to local cmake package registry
    export (
      PACKAGE ${module_name}
    )
  endif()

  set (${module_name}_INCLUDE_DIRS ${CMAKE_INSTALL_INCLUDEDIR})

  # create to-install module config file
  configure_package_config_file(
    ${ARG_PKG_CONF_FILE}.in
    export/${ARG_PKG_CONF_FILE}
    INSTALL_DESTINATION ${CMAKECONFIG_INSTALL_DIR}
    PATH_VARS ${module_name}_INCLUDE_DIRS
  )

  # install module targets
  install(
    EXPORT ${ARG_TARGETS}
    FILE ${ARG_TARGETS}.cmake
    NAMESPACE ${module_name}::
    DESTINATION ${CMAKECONFIG_INSTALL_DIR}
    COMPONENT ${ARG_COMPONENT}
  )

  install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/export/${ARG_PKG_CONF_FILE}"
    DESTINATION ${CMAKECONFIG_INSTALL_DIR}
    COMPONENT ${ARG_COMPONENT}
  )

  # create version file and install it
  if (NOT ARG_VERSION)
    message(FATAL_ERROR "No version specified for module ${module}")
  endif()

  write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${module}-config-version.cmake
    VERSION ${ARG_VERSION}
    COMPATIBILITY SameMinorVersion
  )

  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${module}-config-version.cmake
    DESTINATION ${CMAKECONFIG_INSTALL_DIR}
    COMPONENT ${ARG_COMPONENT}
  )
endmacro(create_cmake_config)
