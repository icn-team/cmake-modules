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
# Find the hcin libraries and includes
# This module sets:
#  LIBHICN_FOUND: True if hicn was found
#  LIBHICN_LIBRARY:  The hicn library
#  LIBHICN_LIBRARIES:  The hicn library and dependencies
#  LIBHICN_INCLUDE_DIRS:  The hicn include dir
#

set(LIBHICN_SEARCH_PATH_LIST
  ${LIBHICN_HOME}
  $ENV{LIBHICN_HOME}
  $ENV{FOUNDATION_HOME}
  /usr/local
  /opt
  /usr
)

find_path(LIBHICN_INCLUDE_DIR hicn/hicn.h
  HINTS ${LIBHICN_SEARCH_PATH_LIST}
  PATH_SUFFIXES include
  DOC "Find the hicn includes"
)

find_library(LIBHICN_LIBRARY NAMES hicn
  HINTS ${LIBHICN_SEARCH_PATH_LIST}
  PATH_SUFFIXES lib
  DOC "Find the hicn libraries"
)

set(LIBHICN_LIBRARIES ${LIBHICN_LIBRARY})
if (${CMAKE_SYSTEM_NAME} STREQUAL "Android")
  set(LIBHICN_LIBRARIES ${LIBHICN_LIBRARIES} log)
endif()
set(LIBHICN_INCLUDE_DIRS ${LIBHICN_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libhicn  DEFAULT_MSG LIBHICN_LIBRARY LIBHICN_INCLUDE_DIR)
