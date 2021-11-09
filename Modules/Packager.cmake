# Copyright (c) 2017-2019 Cisco and/or its affiliates.
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

#############
# RPM/DEB/TGZ Packaging utils
#

set(CONTACT "hicn-dev@lists.fd.io" CACHE STRING "Contact")
set(PACKAGE_MAINTAINER "ICN Team" CACHE STRING "Maintainer")
set(PACKAGE_VENDOR "fd.io" CACHE STRING "Vendor")
macro(extract_version)
  # Extract version from git
  set(BRANCH "$ENV{BRANCH_NAME}")
  if (BRANCH STREQUAL "")
    execute_process(
      COMMAND git rev-parse --abbrev-ref HEAD
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE BRANCH
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()

  execute_process(
    COMMAND git log -1 --pretty=format:%B
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE LAST_LOG
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  string(REPLACE "\n" ";" LAST_LOG ${LAST_LOG})
  foreach(line ${LAST_LOG})
    if("${line}" MATCHES "#promote [0-9]+.[0-9]+")
      string(REPLACE "\n" ";" line ${line})
      string(REGEX MATCH "\\#promote [0-9]+.[0-9]+" PROMOTE ${line})
      string(REGEX MATCH "[0-9]+.[0-9]+" NEXT_VERSION ${PROMOTE})
      message(STATUS "Next Version ${NEXT_VERSION}")
      break()
    endif()
  endforeach()
  message(STATUS "Branch name: ${BRANCH}")
  if (BRANCH MATCHES "master")
    execute_process(
      COMMAND git describe --tags --abbrev=0
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE VER
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NEXT_VERSION)
      string(REGEX REPLACE "v([0-9]+).([0-9]+).([0-9]+)" "\\1;\\2;\\3;" VER_LIST ${VER})
      list(GET VER_LIST 0 VERSION_MAJOR)
      list(GET VER_LIST 1 VERSION_MINOR)
      list(GET VER_LIST 2 VERSION_PATCH)
      if ("${VERSION_MAJOR}.${VERSION_MINOR}" STRLESS "${NEXT_VERSION}")
        set(VER "v${NEXT_VERSION}.0")
      else()
        MATH(EXPR VERSION_PATCH "${VERSION_PATCH}+1")
        set(VER "v${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
      endif()
    else()
      unset(VER)
    endif()

  elseif(BRANCH MATCHES "^release/")
    string(REGEX REPLACE "release/" "" VER ${BRANCH})
    set(VER "v${VER}.9999")
  endif()
  if (NOT VER)
    set(VER "v99.99.9999")
  endif()
  message(STATUS "Next Version: ${VER}")
  string(REGEX REPLACE "v([0-9]+).([0-9]+).([0-9]+)" "\\1;\\2;\\3;" VER ${VER})
  list(GET VER 0 VERSION_MAJOR)
  list(GET VER 1 VERSION_MINOR)
  list(GET VER 2 VERSION_PATCH)
endmacro(extract_version)

function(make_packages)
  if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    # parse /etc/os-release
    file(READ "/etc/os-release" os_version)
    string(REPLACE "\n" ";" os_version ${os_version})
    foreach(_ver ${os_version})
      string(REPLACE "=" ";" _ver ${_ver})
      list(GET _ver 0 _name)
      list(GET _ver 1 _value)
      set(OS_${_name} ${_value})
    endforeach()

    extract_version()

    message(STATUS "Version major: ${VERSION_MAJOR}")
    message(STATUS "Version minor: ${VERSION_MINOR}")
    message(STATUS "Version patch: ${VERSION_PATCH}")
    if (NOT ENV{BUILD_NUMBER} STREQUAL "")
      message(STATUS "Build number $ENV{BUILD_NUMBER}")
      set(BUILD_NUMBER ".$ENV{BUILD_NUMBER}")
    endif()
    if(PREFIX_VERSION)
      set(tag "${PREFIX_VERSION}-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}${BUILD_NUMBER}")
    else()
      set(tag "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}${BUILD_NUMBER}")
    endif()

    set(deb_ver "${tag}")
    set(rpm_ver "${tag}")

    message(STATUS "Version: ${deb_ver}")

    #get_next_version(${tag} next_version)
    set(next_version "${tag}")
    message(STATUS "Next version: ${next_version}")

    get_cmake_property(components COMPONENTS)
    list(REMOVE_ITEM components "Unspecified")
    set(CPACK_COMPONENTS_ALL ${components})

    list(LENGTH components N_COMPONENTS)

    if (NOT N_COMPONENTS)
      return()
    endif()

    if(OS_ID MATCHES "debian" OR OS_ID_LIKE MATCHES "debian")
      set(CPACK_GENERATOR "DEB")
      set(type "DEBIAN")

      execute_process(
        COMMAND dpkg --print-architecture
        OUTPUT_VARIABLE arch
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(CPACK_${type}_PACKAGE_VERSION "${deb_ver}")
      foreach(lc ${components})
        if (${lc} MATCHES ".*Unspecified.*")
          continue()
        endif()

        string(TOUPPER ${lc} uc)
        set(CPACK_${type}_${uc}_FILE_NAME "${lc}_${deb_ver}_${arch}.deb")

        set(DEB_DEPS)
        if (NOT ${${lc}_DEB_DEPENDENCIES} STREQUAL "")
          string(REPLACE "stable_version" ${tag} DEB_DEPS ${${lc}_DEB_DEPENDENCIES})
          string(REPLACE "next_version" ${next_version} DEB_DEPS ${DEB_DEPS})
        endif()

        set(CPACK_${type}_${uc}_PACKAGE_DEPENDS "${DEB_DEPS}")
        set(CPACK_${type}_${uc}_PACKAGE_NAME "${lc}")
        set(CPACK_COMPONENT_${uc}_DESCRIPTION "${${lc}_DESCRIPTION}")

        if (${lc}_DEB_PACKAGE_CONTROL_EXTRA)
          set(CPACK_DEBIAN_${uc}_PACKAGE_CONTROL_EXTRA "${${lc}_DEB_PACKAGE_CONTROL_EXTRA}")
        endif()
      endforeach()
    elseif(OS_ID_LIKE MATCHES "rhel")
      set(CPACK_GENERATOR "RPM")
      set(type "RPM")

      execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE arch
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )

      set(CPACK_${type}_PACKAGE_VERSION "${rpm_ver}")
      set(CPACK_${type}_PACKAGE_RELEASE "${rpm_release}")
      foreach(lc ${components})
        if (${lc} MATCHES ".*Unspecified.*")
          continue()
        endif()

        string(TOUPPER ${lc} uc)
        set(CPACK_${type}_${uc}_DESCRIPTION "${${lc}_DESCRIPTION}")

        set(RPM_DEPS)
        if (NOT ${${lc}_RPM_DEPENDENCIES} STREQUAL "")
          string(REPLACE "stable_version" ${tag} RPM_DEPS ${${lc}_RPM_DEPENDENCIES})
          string(REPLACE "next_version" ${next_version} RPM_DEPS ${RPM_DEPS})
        endif()

        set(CPACK_${type}_${uc}_PACKAGE_REQUIRES "${RPM_DEPS}")

        if(${lc} MATCHES ".*-dev")
          set(package_name ${lc}el)
        else()
          set(package_name ${lc})
        endif()

        set(CPACK_RPM_${uc}_PACKAGE_NAME "${package_name}")
        set(CPACK_${type}_${uc}_FILE_NAME "${package_name}-${rpm_ver}-${rpm_release}.${arch}.rpm")

        if (NOT ${${lc}_RPM_POST_INSTALL_SCRIPT_FILE} STREQUAL "")
          set(CPACK_RPM_${uc}_POST_INSTALL_SCRIPT_FILE "${${lc}_RPM_POST_INSTALL_SCRIPT_FILE}")
        endif()

        if (NOT ${${lc}_RPM_POST_UNINSTALL_SCRIPT_FILE} STREQUAL "")
          set(CPACK_RPM_${uc}_POST_UNINSTALL_SCRIPT_FILE "${${lc}_RPM_POST_UNINSTALL_SCRIPT_FILE}")
        endif()

        if (NOT ${${lc}_RPM_PRE_UNINSTALL_SCRIPT_FILE} STREQUAL "")
          set(CPACK_RPM_${uc}_PRE_UNINSTALL_SCRIPT_FILE "${${lc}_RPM_PRE_UNINSTALL_SCRIPT_FILE}")
        endif()
      endforeach()
    endif()

    if(CPACK_GENERATOR)
      set(CPACK_PACKAGE_NAME ${ARG_NAME})
      set(CPACK_STRIP_FILES OFF)
      set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
      set(CPACK_COMPONENTS_IGNORE_GROUPS 1)
      set(CPACK_${CPACK_GENERATOR}_COMPONENT_INSTALL ON)
      set(CPACK_${type}_PACKAGE_MAINTAINER "HICN Team")
      set(CPACK_PACKAGE_CONTACT ${CONTACT})
      include(CPack)
    endif()
  elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin" OR ${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(CMAKE_SKIP_BUILD_RPATH FALSE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH /opt/hicn)

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    set(CPACK_SET_DESTDIR true)

    set(CMAKE_INSTALL_RPATH "\${CPACK_INSTALL_PREFIX}")
    set(CMAKE_SKIP_INSTALL_RPATH FALSE)
    set(HICN_DEPENDECIES_INSTALLER "${LIBTRANSPORT_LIBRARIES_LIST};${FACEMGR_LIBRARY_LIST};${APPS_LIBRARY_LIST}")
    separate_arguments(HICN_DEPENDECIES_INSTALLER)
    foreach (HICN_DEPENDECY ${HICN_DEPENDECIES_INSTALLER})
      get_filename_component(DEPENDENCY_NAME "${HICN_DEPENDECY}" NAME)
      get_filename_component(DEPENDENCY "${HICN_DEPENDECY}" REALPATH)
      get_filename_component(DEPENDENCY_PATH "${DEPENDENCY}" DIRECTORY)
      install(FILES ${DEPENDENCY} DESTINATION lib COMPONENT dependencies)
    endforeach()
    set(CPACK_PACKAGE_NAME "hicn")
    extract_version()
    set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "hICN")
    set(CPACK_PACKAGE_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_REVISION}")
    set(CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
    set(CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
    set(CPACK_PACKAGE_VERSION_PATCH "${VERSION_PATCH}")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "hICN Components")

    set(CPACK_COMPONENTS_ALL dependencies ${HICN_UTILS} ${HICN_LIGHT} ${HICN_APPS} ${FACEMGR} lib${LIBTRANSPORT} ${LIBTRANSPORT}-dev lib${LIBHICN} ${LIBHICN}-dev ${HICN_UTILS}-dev ${HICN_LIGHT}-dev ${HICN_APPS}-dev ${FACEMGR}-dev)
    set(CPACK_COMPONENT_DEPENDENCIES_DISPLAY_NAME "Dependencies")
    if (NOT "${HICN_UTILS}" STREQUAL "")
      string(TOUPPER ${HICN_UTILS} HICN_UTILS_UPPERCASE)
      string(TOUPPER ${HICN_UTILS}-dev HICN_UTILS_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${HICN_UTILS_UPPERCASE}_DISPLAY_NAME "hICN utils")
      set(CPACK_COMPONENT_${HICN_UTILS_DEV_UPPERCASE}_DISPLAY_NAME "hicn utils headers")
      set(CPACK_COMPONENT_${HICN_UTILS_UPPERCASE}_GROUP "Executables")
      set(CPACK_COMPONENT_${HICN_UTILS_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${HICN_UTILS_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${HICN_UTILS_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()

    if (NOT "${HICN_LIGHT}" STREQUAL "")
      string(TOUPPER ${HICN_LIGHT} HICN_LIGHT_UPPERCASE)
      string(TOUPPER ${HICN_LIGHT}-dev HICN_LIGHT_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${HICN_LIGHT_UPPERCASE}_DISPLAY_NAME "hICN light apps")
      set(CPACK_COMPONENT_${HICN_LIGHT_DEV_UPPERCASE}_DISPLAY_NAME "hicn-light headers")
      set(CPACK_COMPONENT_${HICN_LIGHT_UPPERCASE}_GROUP "Executables")
      set(CPACK_COMPONENT_${HICN_LIGHT_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${HICN_LIGHT_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${HICN_LIGHT_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()

    if (NOT "${HICN_APPS}" STREQUAL "")
      string(TOUPPER ${HICN_APPS} HICN_APPS_UPPERCASE)
      string(TOUPPER ${HICN_APPS}-dev HICN_APPS_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${HICN_APPS_UPPERCASE}_DISPLAY_NAME "hICN apps")
      set(CPACK_COMPONENT_${HICN_APPS_DEV_UPPERCASE}_DISPLAY_NAME "hicn-apps headers")
      set(CPACK_COMPONENT_${HICN_APPS_UPPERCASE}_GROUP "Executables")
      set(CPACK_COMPONENT_${HICN_APPS_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${HICN_APPS_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${HICN_APPS_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()
  
    if (NOT "${FACEMGR}" STREQUAL "")
      string(TOUPPER ${FACEMGR} FACEMGR_UPPERCASE)
      string(TOUPPER ${FACEMGR}-dev FACEMGR_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${FACEMGR_UPPERCASE}_DISPLAY_NAME "facemgr")
      set(CPACK_COMPONENT_${FACEMGR_DEV_UPPERCASE}_DISPLAY_NAME "facemgr headers")
      set(CPACK_COMPONENT_${FACEMGR_UPPERCASE}_GROUP "Executables")
      set(CPACK_COMPONENT_${FACEMGR_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${FACEMGR_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${FACEMGR_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()

    if (NOT "${LIBTRANSPORT}" STREQUAL "")
      string(TOUPPER lib${LIBTRANSPORT} LIBTRANSPORT_UPPERCASE)
      string(TOUPPER ${LIBTRANSPORT}-dev LIBTRANSPORT_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${LIBTRANSPORT_UPPERCASE}_DISPLAY_NAME "libtransport libs")
      set(CPACK_COMPONENT_${LIBTRANSPORT_DEV_UPPERCASE}_DISPLAY_NAME "libtransport headers")
      set(CPACK_COMPONENT_${LIBTRANSPORT_UPPERCASE}_GROUP "Libraries")
      set(CPACK_COMPONENT_${LIBTRANSPORT_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${LIBTRANSPORT_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${LIBTRANSPORT_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()

    if (NOT "${LIBHICN}" STREQUAL "")
      string(TOUPPER lib${LIBHICN} LIBHICN_UPPERCASE)
      string(TOUPPER ${LIBHICN}-dev LIBHICN_DEV_UPPERCASE)
      set(CPACK_COMPONENT_${LIBHICN_UPPERCASE}_DISPLAY_NAME "hicn libs")
      set(CPACK_COMPONENT_${LIBHICN_DEV_UPPERCASE}_DISPLAY_NAME "hicn headers")
      set(CPACK_COMPONENT_${LIBHICN_UPPERCASE}_GROUP "Libraries")
      set(CPACK_COMPONENT_${LIBHICN_DEV_UPPERCASE}_GROUP "Headers")
      set(CPACK_COMPONENT_${LIBHICN_UPPERCASE}_INSTALL_TYPES Full)
      set(CPACK_COMPONENT_${LIBHICN_DEV_UPPERCASE}_INSTALL_TYPES Full)
    endif ()

    set (CPACK_RESOURCE_FILE_LICENSE
        "${PROJECT_SOURCE_DIR}/cmake/Modules/License.txt")
    set(CPACK_COMPONENT_DEPENDENCIES_DESCRIPTION
      "All dependency libreries")
    set(CPACK_COMPONENT_DEPENDENCIES_GROUP "Dependencies")
    set(CPACK_COMPONENT_GROUP_DEVELOPMENT_EXPANDED ON)
    set(CPACK_COMPONENT_GROUP_DEPENDENCIES_DESCRIPTION
      "All dependency libreries")
    set(CPACK_ALL_INSTALL_TYPES Full Developer)
    set(CPACK_INSTALL_TYPE_FULL_DISPLAY_NAME "Everything")
    if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
      set(CMAKE_INSTALL_RPATH /opt/hicn)

      set(CPACK_INSTALL_PREFIX "/opt/hicn")
      set(CPACK_GENERATOR productbuild)
      set( CPACK_PRE_BUILD_SCRIPTS "${PROJECT_SOURCE_DIR}/cmake/Modules/PostInstall.cmake")
    else()
      set(CPACK_INSTALL_PREFIX "c:/Program Files/hicn")
    endif()
    include(CPack)
  endif()
endfunction()
