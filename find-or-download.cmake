# cmake-find-or-download
# Copyright (C) 2022 Alexander Kraus <nr4@z10.info>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Sometimes we want to find programs, sometimes other files.
function(find_unknown VARIABLE_NAME EXTENSION EXECUTABLE_NAME HINTS)
    if(${EXTENSION} MATCHES "exe")
        find_program(${VARIABLE_NAME} NAMES ${EXECUTABLE_NAME} HINTS ${HINTS})
    else()
        find_file(${VARIABLE_NAME} NAMES ${EXECUTABLE_NAME} HINTS ${HINTS})
    endif()
endfunction()

# Download and unpack dependencies if not present
function(find_or_download_if_not_present VARIABLE_NAME EXECUTABLE_NAME URL PATH_IN_ARCHIVE)
    # Extract relevant information
    get_filename_component(URL_EXTENSION ${URL} EXT)
    string(TOLOWER ${URL_EXTENSION} ${URL_EXTENSION})

    get_filename_component(DOWNLOAD_NAME ${URL} NAME)
    set(FULL_DOWNLOAD_PATH "${DOWNLOAD_CACHE}/${DOWNLOAD_NAME}")

    get_filename_component(FILE_EXTENSION ${EXECUTABLE_NAME} EXT)
    string(TOLOWER ${FILE_EXTENSION} ${FILE_EXTENSION})

    # Check if program is found and no download necessary
    find_unknown(${VARIABLE_NAME} ${FILE_EXTENSION} ${EXECUTABLE_NAME} "${DOWNLOAD_CACHE}/${PATH_IN_ARCHIVE}")
    if(NOT ${${VARIABLE_NAME}} MATCHES ${VARIABLE_NAME}-NOTFOUND)
        message(STATUS "Found ${VARIABLE_NAME} at ${${VARIABLE_NAME}}.")
        return()
    endif()
    message(STATUS "Did not find ${VARIABLE_NAME}. Will inspect Cache.")

    # Check if download is already downloaded and if no: download it.
    find_unknown(${VARIABLE_NAME}_DOWNLOAD ${URL_EXTENSION} ${DOWNLOAD_NAME} ${DOWNLOAD_CACHE})
    if(${${VARIABLE_NAME}_DOWNLOAD} MATCHES ${VARIABLE_NAME}_DOWNLOAD-NOTFOUND)
        message(STATUS "Did not find ${VARIABLE_NAME} in cache. Will download from ${URL}.")
        file(DOWNLOAD ${URL} ${FULL_DOWNLOAD_PATH} SHOW_PROGRESS)
    else()
        message(STATUS "Found ${VARIABLE_NAME} in cache. Will reuse.")
    endif()

    # If download is zipped: unzip it.
    if(${URL_EXTENSION} MATCHES "zip")
    get_filename_component(UNPACKED_DOWNLOAD_PATH ${FULL_DOWNLOAD_PATH} DIRECTORY)
        message(STATUS "Download ${DOWNLOAD_NAME} is zipped. Will unpack to ${UNPACKED_DOWNLOAD_PATH}.")
        file(ARCHIVE_EXTRACT INPUT ${FULL_DOWNLOAD_PATH} DESTINATION ${UNPACKED_DOWNLOAD_PATH})
    endif()

    # Find program in now downloaded and extracted folder structure.
    find_unknown(${VARIABLE_NAME} ${FILE_EXTENSION} ${EXECUTABLE_NAME} "${DOWNLOAD_CACHE}/${PATH_IN_ARCHIVE}")
    message(STATUS "${VARIABLE_NAME} found at ${${VARIABLE_NAME}}.")

    # Set the downloaded flag to enable updating the python installation if downloaded.
    set(${VARIABLE_NAME}_DOWNLOADED ON)
endfunction()
