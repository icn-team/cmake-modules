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

##############################
# Utils for building libraries and executables
#

include(GNUInstallDirs)
include(Misc)

macro(build_executable exec)
  cmake_parse_arguments(ARG
    "NO_INSTALL"
    "COMPONENT"
    "SOURCES;LINK_LIBRARIES;DEPENDS;INCLUDE_DIRS;DEFINITIONS;COMPILE_OPTIONS;LINK_FLAGS;INSTALL_RPATH"
    ${ARGN}
  )

  pr("Building executable" "${exec}")
  pr("  No Install: ${ARG_NO_INSTALL}")
  pr("  Install component" "${ARG_COMPONENT}")
  pr("  Link libraries" "${ARG_LINK_LIBRARIES}")
  pr("  Link flags" "${ARG_LINK_FLAGS}")
  # pr("  Install headers" "${ARG_INSTALL_HEADERS}")
  pr("  Dependencies" "${ARG_DEPENDS}")
  pr("  Include directories" "${ARG_INCLUDE_DIRS}")
  pr("  Definitions" "${ARG_DEFINITIONS}")
  pr("  Compile options" "${ARG_COMPILE_OPTIONS}")
  pr("  Install rpath" "${ARG_INSTALL_RPATH}")

  # Check for code coverage options
  if (COVERAGE AND CMAKE_BUILD_TYPE MATCHES "Debug" AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    list (APPEND ARG_COMPILE_OPTIONS
      PRIVATE "-fprofile-instr-generate"
      PRIVATE "-fcoverage-mapping"
    )

    list (APPEND ARG_LINK_FLAGS
      "-fprofile-instr-generate"
      "-fcoverage-mapping"
    )
  endif()

  add_executable(${exec}-bin ${ARG_SOURCES})

  set(BUILD_ROOT ${CMAKE_BINARY_DIR}/build-root)

  string (REPLACE ";" " " ARG_LINK_FLAGS_STR "${ARG_LINK_FLAGS}")
  set_target_properties(${exec}-bin
    PROPERTIES
    OUTPUT_NAME ${exec}
    INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
    BUILD_RPATH "${BUILD_ROOT}/lib"
    INSTALL_RPATH_USE_LINK_PATH TRUE
    ARCHIVE_OUTPUT_DIRECTORY "${BUILD_ROOT}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${BUILD_ROOT}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${BUILD_ROOT}/bin"
    LINK_FLAGS "${ARG_LINK_FLAGS_STR}"
  )

  if(ARG_LINK_LIBRARIES)
    target_link_libraries(${exec}-bin ${ARG_LINK_LIBRARIES})
  endif()

  if(ARG_DEPENDS)
    add_dependencies(${exec}-bin ${ARG_DEPENDS})
  endif()

  if (ARG_COMPILE_OPTIONS)
    target_compile_options(${exec}-bin ${ARG_COMPILE_OPTIONS})
  endif()

  if(ARG_DEFINITIONS)
    target_compile_definitions(${exec}-bin PRIVATE ${ARG_DEFINITIONS})
  endif()

  if(ARG_INCLUDE_DIRS)
    target_include_directories(${exec}-bin BEFORE PUBLIC
      ${ARG_INCLUDE_DIRS}
      ${PROJECT_BINARY_DIR}
    )
  endif()

  if(NOT ARG_NO_INSTALL)
    install(
      TARGETS ${exec}-bin
      RUNTIME
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ${ARG_COMPONENT}
    )
  endif()
endmacro()

macro(build_library lib)
  cmake_parse_arguments(ARG
    "SHARED;STATIC;NO_DEV;EMPTY_PREFIX"
    "COMPONENT;"
    "SOURCES;EXPORT_NAME;LINK_LIBRARIES;OBJECT_LIBRARIES;LINK_FLAGS;INSTALL_HEADERS;DEPENDS;INCLUDE_DIRS;DEFINITIONS;HEADER_ROOT_DIR;LIBRARY_ROOT_DIR;INSTALL_FULL_PATH_DIR;COMPILE_OPTIONS;VERSION;INSTALL_RPATH"
    ${ARGN}
  )

  if (ARG_EMPTY_PREFIX)
    set(libtype module)
  else()
    set(libtype library)
  endif()
  pr("Building ${libtype}" "${lib}")
  pr("  Shared" "${ARG_SHARED}")
  pr("  Static" "${ARG_STATIC}")
  pr("  No 'lib' prefix" "${ARG_EMPTY_PREFIX}")
  pr("  Install component" "${ARG_COMPONENT}")
  pr("  Link libraries" "${ARG_LINK_LIBRARIES}")
  pr("  Object libraries" "${ARG_OBJECT_LIBRARIES}")
  pr("  Link flags" "${ARG_LINK_FLAGS}")
  # pr("  Install headers" "${ARG_INSTALL_HEADERS}")
  pr("  Dependencies" "${ARG_DEPENDS}")
  pr("  Include directories" "${ARG_INCLUDE_DIRS}")
  pr("  Definitions" "${ARG_DEFINITIONS}")
  pr("  Header root directory" "${ARG_HEADER_ROOT_DIR}")
  pr("  Library root directory" "${ARG_LIBRARY_ROOT_DIR}")
  pr("  Install full path directory" "${ARG_INSTALL_FULL_PATH_DIR}")
  pr("  Compile options" "${ARG_COMPILE_OPTIONS}")
  pr("  Version" "${ARG_VERSION}")
  pr("  Install rpath" "${ARG_INSTALL_RPATH}")

  # Check for code coverage options
  if (COVERAGE AND CMAKE_BUILD_TYPE MATCHES "Debug" AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    list (APPEND ARG_COMPILE_OPTIONS
      PRIVATE "-fprofile-instr-generate"
      PRIVATE "-fcoverage-mapping"
    )

    list (APPEND ARG_LINK_FLAGS
      "-fprofile-instr-generate"
      "-fcoverage-mapping"
    )
  endif()

  # Clear target_libs
  unset(TARGET_LIBS)

  if (ARG_SHARED)
    list(APPEND TARGET_LIBS
      ${lib}.shared
    )
    add_library(${lib}.shared SHARED ${ARG_SOURCES} ${ARG_OBJECT_LIBRARIES})
  endif()

  if(ARG_STATIC)
    list(APPEND TARGET_LIBS
      ${lib}.static
    )
    add_library(${lib}.static STATIC ${ARG_SOURCES} ${ARG_OBJECT_LIBRARIES})
  endif()

  if(NOT ARG_COMPONENT)
    set(ARG_COMPONENT hicn)
  endif()

  set(BUILD_ROOT ${CMAKE_BINARY_DIR}/build-root)

  foreach(library ${TARGET_LIBS})

    if(HICN_VERSION)
      set_target_properties(${library}
        PROPERTIES
        SOVERSION ${HICN_VERSION}
      )
    endif()

    set(INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
    if (${ARG_INSTALL_RPATH})
      set(INSTALL_RPATH "${INSTALL_RPATH}:${ARG_INSTALL_RPATH}")
    endif()

    set(PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX})
    if (ARG_EMPTY_PREFIX)
      set(PREFIX "")
    endif()

    string (REPLACE ";" " " ARG_LINK_FLAGS_STR "${ARG_LINK_FLAGS}")
    set_target_properties(${library}
      PROPERTIES
      INSTALL_RPATH ${INSTALL_RPATH}
      BUILD_RPATH "${BUILD_ROOT}/lib"
      INSTALL_RPATH_USE_LINK_PATH TRUE
      PREFIX "${PREFIX}"
      ARCHIVE_OUTPUT_DIRECTORY "${BUILD_ROOT}/lib"
      LIBRARY_OUTPUT_DIRECTORY "${BUILD_ROOT}/lib"
      RUNTIME_OUTPUT_DIRECTORY "${BUILD_ROOT}/bin"
      LINK_FLAGS "${ARG_LINK_FLAGS_STR}"
    )

    if (WIN32)
      set(PROPS WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
    else()
      set(PROPS OUTPUT_NAME ${lib})
    endif()

    if (ARG_COMPILE_OPTIONS)
      target_compile_options(${library} ${ARG_COMPILE_OPTIONS})
    endif()

    set_target_properties(${library} PROPERTIES ${PROPS})

    # library deps
    if(ARG_LINK_LIBRARIES)
      target_link_libraries(${library} ${ARG_LINK_LIBRARIES})
    endif()

    if(ARG_DEFINITIONS)
      target_compile_definitions(${library} ${ARG_DEFINITIONS})
    endif()

    if(ARG_INCLUDE_DIRS)
      target_include_directories(${library} BEFORE
        ${ARG_INCLUDE_DIRS}
      )
    endif()

    if(ARG_VERSION)
      set_target_properties(${library}
        PROPERTIES
        VERSION ${ARG_VERSION}
      )
    endif()

    set(INSTALL_LIB_PATH "${CMAKE_INSTALL_LIBDIR}/${ARG_LIBRARY_ROOT_DIR}")

    if (ARG_INSTALL_FULL_PATH_DIR)
      set(INSTALL_LIB_PATH ${ARG_INSTALL_FULL_PATH_DIR})
    endif()

    if (ARG_EXPORT_NAME)
      list(APPEND EXPORT_ARGS
        "EXPORT"
        "${ARG_EXPORT_NAME}-targets"
      )
    endif()

    install(
      TARGETS ${library}
      ${EXPORT_ARGS}
      COMPONENT ${ARG_COMPONENT}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      LIBRARY DESTINATION ${INSTALL_LIB_PATH}
    )

    if(ARG_DEPENDS)
      add_dependencies(${library} ${ARG_DEPENDS})
    endif()
  endforeach()

  # install headers
  if(ARG_INSTALL_HEADERS)
    if (NOT ARG_HEADER_ROOT_DIR)
      set(ARG_HEADER_ROOT_DIR "hicn")
    endif()

    list(APPEND local_comps
      ${ARG_COMPONENT}-dev
    )

    foreach(file ${ARG_INSTALL_HEADERS})
      set(INSTALL_DESTINATION_ROOT ${CMAKE_INSTALL_INCLUDEDIR}/${ARG_HEADER_ROOT_DIR})
      set(tmp_file ${file})
      set(FOLDER_STACK)

      # Limit max depth of search to 5 subfolders
      foreach (time 1 2 3 4 5)
        get_filename_component(_path ${tmp_file} PATH)
        if (_path)
          get_filename_component(dir ${_path} NAME)

          if ("${dir}" STREQUAL src)
            set(dir "")
            break()
          endif()

          if ("${dir}" STREQUAL includes)
            set(dir "")
            break()
          endif()

          if ("${dir}" STREQUAL ${ARG_HEADER_ROOT_DIR})
            set(dir "")
            break()
          endif()

          list(INSERT FOLDER_STACK 0
            ${dir}
          )

          set(tmp_file ${_path})
        endif()
      endforeach()

      foreach(folder ${FOLDER_STACK})
        set(INSTALL_DESTINATION_ROOT ${INSTALL_DESTINATION_ROOT}/${folder})
      endforeach()

      set(COMPONENT ${ARG_COMPONENT})
      if (NOT ARG_NO_DEV)
        set(COMPONENT ${COMPONENT}-dev)
      endif()
      install(
        FILES ${file}
        DESTINATION ${INSTALL_DESTINATION_ROOT}
        COMPONENT ${COMPONENT}
      )
    endforeach()
  endif()
endmacro()

macro (build_module module)
  cmake_parse_arguments(ARG
    ""
    "COMPONENT;"
    "SOURCES;LINK_LIBRARIES;INSTALL_HEADERS;DEPENDS;INCLUDE_DIRS;DEFINITIONS;INSTALL_RPATH;HEADER_ROOT_DIR;LIBRARY_ROOT_DIR;INSTALL_FULL_PATH_DIR;COMPILE_OPTIONS;VERSION"
    ${ARGN}
  )

  if (${CMAKE_SYSTEM_NAME} MATCHES Darwin)
    list(APPEND ARG_LINK_FLAGS "-Wl,-undefined,dynamic_lookup")
  elseif(${CMAKE_SYSTEM_NAME} MATCHES iOS)
    list(APPEND ARG_LINK_FLAGS "-Wl,-undefined,dynamic_lookup")
  elseif(${CMAKE_SYSTEM_NAME} MATCHES Linux)
    list(APPEND ARG_LINK_FLAGS "-Wl,-unresolved-symbols=ignore-all")
  elseif(${CMAKE_SYSTEM_NAME} MATCHES Windows)
    list(APPEND ARG_LINK_FLAGS "/wd4275")
  else()
    message(FATAL_ERROR "Trying to build module on a not supportd platform. Aborting.")
  endif()

  build_library(${module}
    SHARED EMPTY_PREFIX
    SOURCES ${ARG_SOURCES}
    LINK_LIBRARIES ${ARG_LINK_LIBRARIES}
    INSTALL_HEADERS ${ARG_INSTALL_HEADERS}
    DEPENDS ${ARG_DEPENDS}
    COMPONENT ${ARG_COMPONENT}
    INCLUDE_DIRS ${ARG_INCLUDE_DIRS}
    HEADER_ROOT_DIR ${ARG_HEADER_ROOT_DIR}
    LIBRARY_ROOT_DIR ${ARG_LIBRARY_ROOT_DIR}
    INSTALL_FULL_PATH_DIR ${ARG_INSTALL_FULL_PATH_DIR}
    DEFINITIONS ${ARG_DEFINITIONS}
    COMPILE_OPTIONS ${ARG_COMPILE_OPTIONS}
    VERSION ${ARG_VERSION}
    LINK_FLAGS ${ARG_LINK_FLAGS}
  )

endmacro(build_module)

include(IosMacros)
include(WindowsMacros)
