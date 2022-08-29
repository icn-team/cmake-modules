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

include(ExternalProject)
ExternalProject_Add(unity
  URL https://github.com/ThrowTheSwitch/Unity/archive/refs/tags/v2.5.2.zip
  PREFIX ${CMAKE_BINARY_DIR}/unity
  CMAKE_ARGS
    -DUNITY_EXTENSION_FIXTURE=ON
    -DUNITY_EXTENSION_MEMORY=ON
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} 
  BUILD_BYPRODUCTS
    ${CMAKE_BINARY_DIR}/unity/src/unity-build/libunity.a
  INSTALL_COMMAND ""
)

ExternalProject_Get_Property(unity source_dir binary_dir)

message (STATUS "Unity test framework include dir: ${source_dir}/src ${source_dir}/extras/fixture/src ${source_dir}/extras/memory/src")
message (STATUS "Unity libs: ${binary_dir}/libunity.a")

set(UNITY_INCLUDE_DIRS
  ${source_dir}/src
  ${source_dir}/extras/fixture/src
  ${source_dir}/extras/memory/src
)

set(UNITY_LIBRARIES
  ${binary_dir}/libunity.a
)


macro(unity_add_test_internal test)
  add_test(NAME ${test} COMMAND ${test}-bin)
endmacro(unity_add_test_internal)
