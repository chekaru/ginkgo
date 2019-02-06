set(PACKAGE_DOWNLOADER_SCRIPT
    "${CMAKE_CURRENT_LIST_DIR}/DownloadCMakeLists.txt.in")

function(ginkgo_load_git_package package_name package_url package_tag)
    configure_file(${PACKAGE_DOWNLOADER_SCRIPT}
                   download/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
      RESULT_VARIABLE result
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/download)
    if(result)
      message(FATAL_ERROR
        "CMake step for ${package_name}/download failed: ${result}")
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
      RESULT_VARIABLE result
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/download)
    if(result)
      message(FATAL_ERROR
        "Build step for ${package_name}/download failed: ${result}")
    endif()
endfunction()


#   Add external target to external project.
#   Create a new target and declare it as `IMPORTED` for libraries or `INTERFACE`
#       for header only projects.
#
#   \param name             Name of external project
#   \param includedir       Path to include directory
#   \param libdir           Path to library directory
#   \param build_type       Build type {STATIC, SHARED}
#   \param debug_postfix    The debug postfix to use when building in debug mode
#   \param external         Name of the external target
#   \param header_only      Boolean indicating if this should be a header only target
#
macro(ginkgo_add_external_target name includedir libdir build_type debug_postfix external header_only)
    # Declare include directories and library files
    set(${name}_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${libdir})
    set(${name}_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/${includedir}")
    set(${name}_LIBRARY_RELEASE "${${name}_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${CMAKE_${build_type}_LIBRARY_PREFIX}${name}${CMAKE_${build_type}_LIBRARY_SUFFIX}")
    set(${name}_LIBRARY_DEBUG "${${name}_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${CMAKE_${build_type}_LIBRARY_PREFIX}${name}${debug_postfix}${CMAKE_${build_type}_LIBRARY_SUFFIX}")

    # Create an IMPORTED external library available in the GLOBAL scope
    if (${header_only})
        add_library(${name} INTERFACE)
    else()
        add_library(${name} ${build_type} IMPORTED GLOBAL)
    endif()

    # Set a dependency to the external target (ExternalProject fetcher and builder)
    add_dependencies(${name} ${external})

    # Set the target's properties, namely library file and include directory
    if (NOT ${header_only})
        set_target_properties(${name} PROPERTIES IMPORTED_LOCATION_RELEASE ${${name}_LIBRARY_RELEASE})
        set_target_properties(${name} PROPERTIES IMPORTED_LOCATION_DEBUG ${${name}_LIBRARY_DEBUG})
    endif()
    target_include_directories(${name} INTERFACE ${${name}_INCLUDE_DIR})
endmacro(ginkgo_add_external_target)


#   Ginkgo specific add_subdirectory helper macro.
#   If the package was not found or if requested by the user, use the
#       internal version of the package.
#
#   \param package_name     Name of package to be found
#   \param dir_name         Name of the subdirectory for the package
#
macro(ginkgo_add_subdirectory package_name dir_name)
    string(TOUPPER ${package_name} _UPACKAGE_NAME)
    if (NOT ${package_name}_FOUND OR GINKGO_USE_INTERNAL_${_UPACKAGE_NAME})
        add_subdirectory(${dir_name})
    endif()
endmacro(ginkgo_add_subdirectory)


#   Ginkgo specific find_package helper macro. Use this macro for third
#       party libraries.
#   If the user does not specify otherwise, try to find the package.
#
#   \param package_name     Name of package to be found
#   \param ARGN             Extra specifications for the package finder
#
macro(ginkgo_find_package package_name)
    string(TOUPPER ${package_name} _UPACKAGE_NAME)
    if (NOT GINKGO_USE_INTERNAL_${_UPACKAGE_NAME})
        find_package(${package_name} QUIET ${ARGN})
        if (${package_name}_FOUND)
          message(STATUS "Using external version of package ${package_name}. In case of problems, consider setting -DGINKGO_USE_INTERNAL_${_UPACKAGE_NAME}=ON.")
        endif()
    endif()
endmacro(ginkgo_find_package)
