
# Copyright (c) 2022 Cisco and/or its affiliates.
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

list(APPEND CMAKE_MODULE_PATH
  ${CMAKE_CURRENT_LIST_DIR}
)

include(GNUInstallDirs)
include(Misc)
include(BuildMacros)
include(CMakeConfigMacros)
include(Packager)
include(CPU)
include(WindowsMacros)
include(IosMacros)
include(FetchContent)
extract_version()

if ("${VERSION_PATCH}" STREQUAL "")
  set(CURRENT_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}")
else()
  set(CURRENT_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
endif()

message(STATUS "${PROJECT_NAME} current version: ${CURRENT_VERSION}")

# Generate compiler commands
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(DEFAULT_COMPILER_OPTIONS
  PRIVATE "-Wall" "-Werror"
)

set(MARCH_COMPILER_OPTIONS
  PUBLIC ${DEFAULT_MARCH_FLAGS}
)

if (NOT CMAKE_BUILD_TYPE)
  message(STATUS "${PROJECT_NAME}: No build type selected, default to Release")
  set(CMAKE_BUILD_TYPE "Release")
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)