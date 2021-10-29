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

macro(read_versions_file file)
  file(READ ${file} dep_versions)
  string(REPLACE "\n" ";" dep_versions ${dep_versions})
  foreach(line ${dep_versions})
    if(NOT "${line}" STREQUAL "")
      string(REPLACE "=" ";" line ${line})
      list(GET line 0 _dep)
      list(GET line 1 _ver)
      set(${_dep}_DEFAULT_VERSION ${_ver})
    endif()
  endforeach()
endmacro()