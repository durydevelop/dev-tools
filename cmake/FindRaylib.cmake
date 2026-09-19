#### Find Raylib lib
# Version 1.0.1

function(get_package_from_git)
    include(FetchContent)
    set(FETCHCONTENT_QUIET OFF)
    set(FETCHCONTENT_UPDATES_DISCONNECTED OFF)
    set(FETCHCONTENT_BASE_DIR _deps)
    FetchContent_Declare(
        ${ARGV0}
        GIT_REPOSITORY ${ARGV1}
        #GIT_TAG main
        #GIT_PROGRESS TRUE
    )
    FetchContent_MakeAvailable(${ARGV0})
endfunction()

unset(BUILD_EXAMPLES CACHE)
#cmake_policy(SET CMP0077 NEW) # for BUILD_SHARED_LIBS and BUILD_EXAMPLES in raylib
if (USE_EXTERNAL_RAYLIB)
    # Do not use internal Raylib
    message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} is finding <${BOLD_CYAN}raylib${BOLD_MAGENTA}>")
    if (raylib_GIT_REPOSITORY)
        # GIT forced
        get_package_from_git(raylib ${raylib_GIT_REPOSITORY})
        if (raylib_FOUND)
            message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}raylib${BOLD_MAGENTA}> loaded custom repo")
        endif()
    elseif(raylib_ROOT)
        # Local FORCED
        add_subdirectory(${raylib_ROOT} _deps/raylib)
    else()
        # Try to find in system
        find_package(raylib QUIET CONFIG)
        if (raylib_FOUND)
            if (ZLIB_FOUND)
                link_libraries(ZLIB::ZLIB)
            endif()
            get_target_property(raylib_INCLUDE_DIRECTORIES raylib::raylib INTERFACE_INCLUDE_DIRECTORIES)
            message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}raylib${BOLD_MAGENTA}> found in system")
        else()
            # Load from official repo
            get_package_from_git(raylib https://github.com/raysan5/raylib.git)
            set(raylib_FOUND TRUE)
            message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} <${BOLD_CYAN}raylib${BOLD_MAGENTA}> loaded from official repo")
        endif()
    endif()
else()
    # Use embedded one
    message_c(${BOLD_MAGENTA} "${BOLD_WHITE}${PROJECT_NAME}${BOLD_MAGENTA} use <${BOLD_CYAN}raylib${BOLD_MAGENTA}> embedded")
    add_subdirectory(external/raylib)
    #install(
    #    DIRECTORY ${raylib_SOURCE_DIR}/raylib
    #    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBRARY_TARGET_NAME}"
    #    FILES_MATCHING PATTERN "*.h"
    #)
endif()

#print_var(raylib)
#print_target_prop(raylib)
#include_directories(${raylib_SOURCE_DIR})
#set(${LIBRARY_TARGET_NAME}_INCLUDE_DIRS ${${LIBRARY_TARGET_NAME}_INCLUDE_DIRS} ${raylib_SOURCE_DIR})
