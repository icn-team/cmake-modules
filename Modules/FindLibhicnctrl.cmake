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

########################################
#
# Find the hICN control library and include files
#

set(LIBHICN_SEARCH_PATH_LIST
  ${LIBHICN_HOME}
  $ENV{LIBHICN_HOME}
  $ENV{FOUNDATION_HOME}
  /usr/local
  /opt
  /usr
)

find_path(LIBHICNCTRL_INCLUDE_DIR hicn/ctrl.h
  HINTS ${LIBHICN_SEARCH_PATH_LIST}
  PATH_SUFFIXES include
  DOC "Find the hICN control include"
)

find_library(LIBHICNCTRL_LIBRARY NAMES hicnctrl
  HINTS ${LIBHICN_SEARCH_PATH_LIST}
  PATH_SUFFIXES lib
  DOC "Find the hicn control library"
)


macro(parse lineinput returnValue)
    string(REPLACE "\"" "" line ${lineinput})
    string(REPLACE " " ";" line ${line})
    list (GET line 2 returnValue)
endmacro()

set(LIBHICNCTRL_FOUND False)
if (NOT "${LIBHICNCTRL_INCLUDE_DIR}" STREQUAL "")
  set(LIBHICN_FOUND True)
  file(READ "${LIBHICNCTRL_INCLUDE_DIR}/hicn/transport/config.h" libhicnctrl)
  string(REPLACE "\n" ";" libhicnctrl ${libhicnctrl})
  foreach(line ${transport})
    if ("${line}" MATCHES "#define HICNTRANSPORT_VERSION_MAJOR")
      parse(${line} returnValue)
      set(LIBHICNCTRL_MAJOR "${returnValue}")
    endif ()
    if ("${line}" MATCHES "#define HICNTRANSPORT_VERSION_MINOR")
      parse(${line} returnValue)
      set(LIBHICNCTRL_MINOR "${returnValue}")
    endif ()
    if ("${line}" MATCHES "#define HICNTRANSPORT_VERSION_PATCH")
      parse(${line} returnValue)
      set(LIBHICNCTRL_PATCH "${returnValue}")
    endif ()
  endforeach()
  set(LIBHICNCTRL_VERSION "${LIBHICNCTRL_MAJOR}.${LIBHICNCTRL_MINOR}.${LIBHICNCTRL_PATCH}")
endif ()
set(LIBHICNCTRL_LIBRARIES ${LIBHICNCTRL_LIBRARY})
set(LIBHICNCTRL_INCLUDE_DIRS ${LIBHICNCTRL_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libhicnctrl REQUIRED_VARS
        LIBHICNCTRL_LIBRARY LIBHICNCTRL_INCLUDE_DIR VERSION_VAR LIBHICNCTRL_VERSION)