#.rst:
# Findlg
# ------
#
# Find the ``lg`` GPIO library.
#
# This module does nothing and sets ``lg_FOUND`` to ``FALSE`` when
# ``GPIO_SUPPORT`` is disabled. When GPIO support is enabled, the source is
# selected according to ``USE_EXTERNAL_LG``:
#
# * If ``USE_EXTERNAL_LG`` is ``OFF``, use the bundled source at
#   ``src/external/lg``.
# * If ``USE_EXTERNAL_LG`` is ``ON`` and ``lg_GIT_REPOSITORY`` is set, clone
#   and build that repository.
# * Otherwise, if ``lg_ROOT`` is set, add that local CMake project.
# * Otherwise, search for an installed ``lg`` library. If it is not found,
#   clone and build the default repository
#   ``https://github.com/joan2937/lg.git``.
#
# Cloning and building from Git requires Git, Make, and a C compiler. The
# default Git ref is ``master``.
#
# Input Variables
# ^^^^^^^^^^^^^^^
#
# ``GPIO_SUPPORT``
#   Enable or disable GPIO support and the search for ``lg``.
# ``USE_EXTERNAL_LG``
#   Use an external installation/source instead of the bundled source.
# ``lg_GIT_REPOSITORY``
#   Optional Git repository to clone when external lg is selected.
# ``lg_GIT_TAG``
#   Optional branch, tag, or commit for the Git repository; defaults to
#   ``master``.
# ``lg_ROOT``
#   Optional path to a local ``lg`` CMake project.
#
# Result Variables
# ^^^^^^^^^^^^^^^^
#
# ``lg_FOUND``
#   True when an ``lg`` source or installation is available. The final value
#   is also assigned to ``GPIO_SUPPORT``.
# ``lg_INCLUDE_DIR`` / ``lg_INCLUDE_DIRS``
#   Include directory for ``lg``, when provided by the selected source.
# ``lgpio_LIBRARY`` / ``lg_LIBRARIES``
#   ``lgpio`` library or imported target for linking.
#
# Imported Targets
# ^^^^^^^^^^^^^^^^
#
# ``lgpio``
#   Imported target provided when ``lg`` is cloned and built from Git.
#
# Example
# ^^^^^^^
#
# .. code-block:: cmake
#
#   set(GPIO_SUPPORT ON)
#   set(USE_EXTERNAL_LG ON)
#   set(lg_GIT_REPOSITORY "https://github.com/joan2937/lg.git")
#   set(lg_GIT_TAG "master")
#   find_package(lg)

include(FindPackageHandleStandardArgs)

# GPIO is optional; do not search for or build lg when it is disabled.
if(NOT GPIO_SUPPORT)
    set(lg_FOUND FALSE)
    set(GPIO_SUPPORT FALSE)
    return()
endif()

# Select an external installation/source or the bundled copy of lg.
set(lg_FOUND FALSE)
if(USE_EXTERNAL_LG)
    message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} is finding <${BOLD_CYAN}lg${BOLD_MAGENTA}>")

    if(lg_GIT_REPOSITORY)
        set(_lg_git_repository "${lg_GIT_REPOSITORY}")
    elseif(lg_ROOT)
        # Use a caller-provided lg checkout that has its own CMake project.
        if(NOT EXISTS "${lg_ROOT}/CMakeLists.txt")
            message(FATAL_ERROR
                "lg_ROOT='${lg_ROOT}' does not contain a CMakeLists.txt file."
            )
        endif()

        add_subdirectory("${lg_ROOT}" "${CMAKE_BINARY_DIR}/_deps/lg")
        set(lg_FOUND TRUE)
        message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}lg${BOLD_MAGENTA}> loaded from local source")
    else()
        # Fall back to an lg installation available through the normal system search paths.
        find_path(
            lg_INCLUDE_DIR
            NAMES lgpio.h
        )

        find_library(
            lgpio_LIBRARY
            NAMES lgpio
        )

        if(lg_INCLUDE_DIR AND lgpio_LIBRARY)
            set(lg_FOUND TRUE)
            set(lg_INCLUDE_DIRS "${lg_INCLUDE_DIR}")
            set(lg_INCLUDES "${lg_INCLUDE_DIR}")
            set(lg_INCLUDE_DIRECTORIES "${lg_INCLUDE_DIR}")
            set(lg_LIBRARIES "${lgpio_LIBRARY}")
            message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}lg${BOLD_MAGENTA}> found in system")
        else()
            # Use the upstream repository only after the system search fails.
            set(_lg_git_repository "https://github.com/joan2937/lg.git")
        endif()
    endif()

    if(_lg_git_repository)
        # Upstream lg uses a Makefile rather than CMake; build its libraries as an external project.
        find_package(Git REQUIRED)
        include(ExternalProject)

        find_program(lg_MAKE_EXECUTABLE NAMES gmake make)
        if(NOT lg_MAKE_EXECUTABLE)
            message(FATAL_ERROR
                "A make executable (gmake or make) is required to build lg from Git."
            )
        endif()

        set(_lg_source_dir "${CMAKE_BINARY_DIR}/_deps/lg-src")
        file(MAKE_DIRECTORY "${_lg_source_dir}")
        # Allow pinning a branch, tag, or commit; otherwise use the upstream default branch.
        if(lg_GIT_TAG)
            set(_lg_git_tag "${lg_GIT_TAG}")
        else()
            set(_lg_git_tag master)
        endif()

        ExternalProject_Add(lg_external
            GIT_REPOSITORY "${_lg_git_repository}"
            GIT_TAG "${_lg_git_tag}"
            SOURCE_DIR "${_lg_source_dir}"
            CONFIGURE_COMMAND ""
            BUILD_IN_SOURCE TRUE
            BUILD_COMMAND "${lg_MAKE_EXECUTABLE}" lib
            INSTALL_COMMAND ""
            BUILD_BYPRODUCTS
                "${_lg_source_dir}/liblgpio.so"
                "${_lg_source_dir}/librgpio.so"
        )

        if(TARGET lgpio)
            message(FATAL_ERROR
                "Cannot build lg from Git because a target named 'lgpio' already exists."
            )
        endif()

        # Expose lgpio as an imported target so consumers wait for the external build.
        add_library(lgpio UNKNOWN IMPORTED GLOBAL)
        set_target_properties(lgpio PROPERTIES
            IMPORTED_LOCATION "${_lg_source_dir}/liblgpio.so"
            INTERFACE_INCLUDE_DIRECTORIES "${_lg_source_dir}"
        )
        add_dependencies(lgpio lg_external)

        set(lg_INCLUDE_DIR "${_lg_source_dir}")
        set(lg_INCLUDE_DIRS "${_lg_source_dir}")
        set(lg_INCLUDES "${_lg_source_dir}")
        set(lg_INCLUDE_DIRECTORIES "${_lg_source_dir}")
        set(lgpio_LIBRARY "${_lg_source_dir}/liblgpio.so")
        set(rgpio_LIBRARY "${_lg_source_dir}/librgpio.so")
        set(lg_LIBRARIES lgpio)

        set(lg_FOUND TRUE)
        message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}lg${BOLD_MAGENTA}> will be cloned from ${_lg_git_repository} (${_lg_git_tag})")
    endif()
else()
    # The bundled source is stored relative to this find-module, not the caller's directory.
    set(_lg_source_dir "${CMAKE_CURRENT_LIST_DIR}/../src/external/lg")
    if(NOT EXISTS "${_lg_source_dir}/CMakeLists.txt")
        message(FATAL_ERROR
            "The embedded lg source is missing or incomplete at '${_lg_source_dir}'. "
            "Initialize or restore that source, or configure with USE_EXTERNAL_LG=ON."
        )
    endif()

    message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} use <${BOLD_CYAN}lg${BOLD_MAGENTA}> embedded")
    add_subdirectory("${_lg_source_dir}" "${CMAKE_BINARY_DIR}/_deps/lg")
    set(lg_FOUND TRUE)

    # Install bundled headers when that source tree provides them.
    if(EXISTS "${_lg_source_dir}/lg")
        install(
            DIRECTORY "${_lg_source_dir}/lg"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBRARY_TARGET_NAME}"
            FILES_MATCHING PATTERN "*.h"
        )
    endif()
endif()

# Keep GPIO support in sync with whether a usable lg implementation was found.
set(GPIO_SUPPORT "${lg_FOUND}")

if(NOT lg_FOUND)
    find_package_handle_standard_args(
        lg
        DEFAULT_MSG
        lg_INCLUDE_DIR
        lgpio_LIBRARY
    )
endif()
