#[=======================================================================[.rst:
FindVTK_IO
----------

Find or build the VTK_IO library

This module first attempts to find an existing VTK_IO installation.
If not found, it will automatically download, build, and install VTK_IO
using CMake's FetchContent functionality.

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``VTK_IO_FOUND``
  True if VTK_IO was found or successfully built
``VTK_IO_VERSION``
  Version of VTK_IO
``VTK_IO_BUILT_FROM_SOURCE``
  True if VTK_IO was built from source rather than found pre-installed

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may be set:

``VTK_IO_ROOT``
  Directory containing VTK_IO installation
``VTK_IO_GIT_REPOSITORY``
  Git repository URL for VTK_IO (default: https://github.com/ronaldremmerswaal/VTKFortran.git)
``VTK_IO_GIT_TAG``
  Git tag/branch to checkout (default: master)
``VTK_IO_BUILD_SHARED_LIBS``
  Whether to build VTK_IO as shared library (default: ON)
``VTK_IO_AUTO_BUILD``
  Enable automatic building if not found (default: ON)
``VTK_IO_INSTALL_PREFIX``
  Installation prefix for auto-built VTK_IO (default: $HOME/.local)

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported target:

``VTK_IO::VTK_IO``
  The VTK_IO library

Example Usage
^^^^^^^^^^^^^

.. code-block:: cmake

  find_package(VTK_IO REQUIRED)
  target_link_libraries(my_target VTK_IO::VTK_IO)

Advanced Usage
^^^^^^^^^^^^^^

.. code-block:: cmake

  # Disable auto-building and only find existing installation
  set(VTK_IO_AUTO_BUILD OFF)
  find_package(VTK_IO REQUIRED)

  # Force building from specific repository and tag
  set(VTK_IO_GIT_REPOSITORY "https://github.com/your-fork/VTKFortran.git")
  set(VTK_IO_GIT_TAG "your-branch")
  find_package(VTK_IO REQUIRED)

#]=======================================================================]

# Set default cache variables
set(VTK_IO_GIT_REPOSITORY "https://github.com/ronaldremmerswaal/VTKFortran.git" 
    CACHE STRING "Git repository for VTK_IO")
set(VTK_IO_GIT_TAG "master" 
    CACHE STRING "Git tag/branch for VTK_IO")
set(VTK_IO_BUILD_SHARED_LIBS OFF 
    CACHE BOOL "Build VTK_IO as shared library")
set(VTK_IO_AUTO_BUILD ON 
    CACHE BOOL "Automatically build VTK_IO if not found")
set(VTK_IO_FORCE_BUILD OFF
    CACHE BOOL "Force building VTK_IO from source even if found")
set(VTK_IO_INSTALL_PREFIX "$ENV{HOME}/.local"
    CACHE PATH "Installation prefix for auto-built VTK_IO")

# Initialize result variables
set(VTK_IO_FOUND FALSE)
set(VTK_IO_BUILT_FROM_SOURCE FALSE)

# Check if we should force building from source
if(VTK_IO_FORCE_BUILD)
    message(STATUS "VTK_IO_FORCE_BUILD is ON - will build from source")
    set(VTK_IO_FOUND FALSE)
else()
    # First, try to find an existing VTK_IO installation
    if(VTK_IO_AUTO_BUILD)
        message(STATUS "Looking for existing VTK_IO installation...")
    endif()

    # Look for VTK_IO using the standard CMake package mechanism
    # Check if VTK_IO config files exist first
    find_file(VTK_IO_CONFIG_FILE VTK_IOConfig.cmake 
        HINTS ${CMAKE_PREFIX_PATH}/lib/cmake/VTK_IO
              $ENV{HOME}/.local/lib/cmake/VTK_IO
    )
    
    if(VTK_IO_CONFIG_FILE)
        # Config file exists, but we need to check if library file exists too
        # before calling find_package which might fail on missing targets
        find_file(VTK_IO_LIB_FILE libVTK_IO.a
            HINTS ${CMAKE_PREFIX_PATH}/lib
                  $ENV{HOME}/.local/lib
        )
        
        if(VTK_IO_LIB_FILE)
            find_package(VTK_IO QUIET CONFIG)
        else()
            message(STATUS "VTK_IO config found but library missing - will rebuild")
            set(VTK_IO_FOUND FALSE)
        endif()
    else()
        find_package(VTK_IO QUIET CONFIG)
    endif()
endif()

if(VTK_IO_FOUND)
    message(STATUS "Found existing VTK_IO installation")
    if(TARGET VTK_IO::VTK_IO)
        get_target_property(VTK_IO_TYPE VTK_IO::VTK_IO TYPE)
        message(STATUS "  VTK_IO type: ${VTK_IO_TYPE}")
        get_target_property(VTK_IO_LOCATION VTK_IO::VTK_IO LOCATION)
        if(VTK_IO_LOCATION)
            message(STATUS "  VTK_IO location: ${VTK_IO_LOCATION}")
            # Check if the library file actually exists
            if(NOT EXISTS "${VTK_IO_LOCATION}")
                message(STATUS "  VTK_IO library file missing - will rebuild")
                set(VTK_IO_FOUND FALSE)
            endif()
        else()
            message(STATUS "  VTK_IO location not found - will rebuild")
            set(VTK_IO_FOUND FALSE)
        endif()
    endif()
endif()

if(NOT VTK_IO_FOUND)
    if(VTK_IO_AUTO_BUILD)
        message(STATUS "VTK_IO not found - will build from source")
        
        # Include FetchContent for downloading and building
        include(FetchContent)
        
        # Declare the VTK_IO dependency
        FetchContent_Declare(
            VTK_IO_Source
            GIT_REPOSITORY ${VTK_IO_GIT_REPOSITORY}
            GIT_TAG        ${VTK_IO_GIT_TAG}
            GIT_SHALLOW    TRUE
            GIT_PROGRESS   TRUE
        )
        
        # Check if already built and installed
        if(NOT VTK_IO_INSTALL_PREFIX)
            set(VTK_IO_INSTALL_PREFIX "$ENV{HOME}/.local" CACHE PATH "VTK_IO installation prefix")
        endif()
        
        # Check if VTK_IO is already installed at the target location
        # First check if library file exists to avoid broken config
        find_file(VTK_IO_TARGET_LIB libVTK_IO.a
            PATHS ${VTK_IO_INSTALL_PREFIX}/lib
            NO_DEFAULT_PATH
        )
        
        if(VTK_IO_TARGET_LIB)
            find_package(VTK_IO QUIET CONFIG PATHS ${VTK_IO_INSTALL_PREFIX}/lib/cmake/VTK_IO NO_DEFAULT_PATH)
        else()
            set(VTK_IO_FOUND FALSE)
        endif()
        
        if(VTK_IO_FOUND)
            message(STATUS "Found VTK_IO installation at ${VTK_IO_INSTALL_PREFIX}")
            set(VTK_IO_BUILT_FROM_SOURCE FALSE)
        else()
            message(STATUS "Building and installing VTK_IO to ${VTK_IO_INSTALL_PREFIX}")
            
            # Download the source
            FetchContent_Populate(VTK_IO_Source)
            
            # Configure build directory
            set(_vtk_io_build_dir ${CMAKE_CURRENT_BINARY_DIR}/_deps/vtk_io_build)
            file(MAKE_DIRECTORY ${_vtk_io_build_dir})
            
            # Configure VTK_IO with installation
            execute_process(
                COMMAND ${CMAKE_COMMAND} 
                    -DCMAKE_BUILD_TYPE=Release
                    -DBUILD_SHARED_LIBS=${VTK_IO_BUILD_SHARED_LIBS}
                    -DBUILD_TESTING=OFF
                    -DVTK_IO_ENABLE_MPI=OFF
                    -DVTK_IO_ENABLE_OPENMP=OFF
                    -DCMAKE_INSTALL_PREFIX=${VTK_IO_INSTALL_PREFIX}
                    -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
                    -DCMAKE_C_COMPILER=/usr/bin/gcc
                    ${vtk_io_source_SOURCE_DIR}
                WORKING_DIRECTORY ${_vtk_io_build_dir}
                RESULT_VARIABLE _vtk_io_config_result
                OUTPUT_VARIABLE _vtk_io_config_output
                ERROR_VARIABLE _vtk_io_config_error
            )
            
            if(NOT _vtk_io_config_result EQUAL 0)
                message(FATAL_ERROR "Failed to configure VTK_IO:\n${_vtk_io_config_error}")
            endif()
            
            # Build VTK_IO
            execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --parallel
                WORKING_DIRECTORY ${_vtk_io_build_dir}
                RESULT_VARIABLE _vtk_io_build_result
                OUTPUT_VARIABLE _vtk_io_build_output
                ERROR_VARIABLE _vtk_io_build_error
            )
            
            if(NOT _vtk_io_build_result EQUAL 0)
                message(FATAL_ERROR "Failed to build VTK_IO:\n${_vtk_io_build_error}")
            endif()
            
            # Install VTK_IO
            execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target install
                WORKING_DIRECTORY ${_vtk_io_build_dir}
                RESULT_VARIABLE _vtk_io_install_result
                OUTPUT_VARIABLE _vtk_io_install_output
                ERROR_VARIABLE _vtk_io_install_error
            )
            
            if(NOT _vtk_io_install_result EQUAL 0)
                message(FATAL_ERROR "Failed to install VTK_IO:\n${_vtk_io_install_error}")
            endif()
            
            message(STATUS "VTK_IO successfully built and installed to ${VTK_IO_INSTALL_PREFIX}")
            
            # Now find the installed VTK_IO
            find_package(VTK_IO REQUIRED CONFIG PATHS ${VTK_IO_INSTALL_PREFIX}/lib/cmake/VTK_IO NO_DEFAULT_PATH)
            
            set(VTK_IO_BUILT_FROM_SOURCE TRUE)
            set(VTK_IO_VERSION "0.0.1")
        endif()
    else()
        message(FATAL_ERROR 
            "VTK_IO not found and VTK_IO_AUTO_BUILD is disabled. "
            "Please either:\n"
            "  1. Install VTK_IO and set VTK_IO_ROOT to the installation directory\n"
            "  2. Set VTK_IO_AUTO_BUILD=ON to enable automatic building\n"
            "  3. Set CMAKE_PREFIX_PATH to include VTK_IO installation directory")
    endif()
endif()

# Verify we have the target we need
if(VTK_IO_FOUND AND NOT TARGET VTK_IO::VTK_IO)
    set(VTK_IO_FOUND FALSE)
    message(FATAL_ERROR "VTK_IO found but VTK_IO::VTK_IO target is not available")
endif()

# Standard find_package result handling
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(VTK_IO
    FOUND_VAR VTK_IO_FOUND
    REQUIRED_VARS VTK_IO_FOUND
    VERSION_VAR VTK_IO_VERSION
)

# Mark cache variables as advanced
mark_as_advanced(
    VTK_IO_GIT_REPOSITORY
    VTK_IO_GIT_TAG
)

# Provide summary information
if(VTK_IO_FOUND)
    if(VTK_IO_BUILT_FROM_SOURCE)
        message(STATUS "VTK_IO: Built from source (${VTK_IO_GIT_REPOSITORY}@${VTK_IO_GIT_TAG})")
    else()
        message(STATUS "VTK_IO: Using existing installation")
    endif()
    
    if(TARGET VTK_IO::VTK_IO)
        get_target_property(_vtk_io_type VTK_IO::VTK_IO TYPE)
        message(STATUS "VTK_IO: Library type is ${_vtk_io_type}")
    endif()
endif()