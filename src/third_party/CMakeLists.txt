# Third-party dependencies for VTKFortran
    
# Update submodules as needed
option(GIT_SUBMODULE "Check submodules during build" ON)
if(GIT_SUBMODULE)
    message(STATUS "Submodule update (non-recursive to avoid nested dependency duplication)")
    execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init ${CMAKE_CURRENT_SOURCE_DIR}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    RESULT_VARIABLE GIT_SUBMOD_RESULT)
    if(NOT GIT_SUBMOD_RESULT EQUAL "0")
        message(FATAL_ERROR "git submodule update --init ${CMAKE_CURRENT_SOURCE_DIR} failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
    endif()
endif()

# The submodule libraries each have their own third_party dependencies
# We need to build them in the correct order to satisfy dependencies
# Each library creates a namespaced target (e.g., PENF::PENF)

# 1. PENF - Base library (no dependencies)
# Build PENF first as it's a base dependency for others
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/PENF/CMakeLists.txt)
    # Disable PENF tests to speed up build
    set(BUILD_TESTING OFF CACHE BOOL "Disable testing for PENF" FORCE)
    add_subdirectory(PENF)
    message(STATUS "Added PENF third-party library")
else()
    message(FATAL_ERROR "PENF source not found - ensure git submodules are initialized")
endif()

# 2. FACE - Build early since it's needed by others
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/FACE/CMakeLists.txt)
    set(BUILD_TESTING OFF CACHE BOOL "Disable testing for FACE" FORCE)
    add_subdirectory(FACE)
    message(STATUS "Added FACE third-party library")
else()
    message(FATAL_ERROR "FACE source not found - ensure git submodules are initialized")
endif()

# 3. BeFoR64 - Depends on PENF
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/BeFoR64/CMakeLists.txt)
    set(BUILD_TESTING OFF CACHE BOOL "Disable testing for BeFoR64" FORCE)
    add_subdirectory(BeFoR64)
    message(STATUS "Added BeFoR64 third-party library")
else()
    message(FATAL_ERROR "BeFoR64 source not found - ensure git submodules are initialized")
endif()

# 4. StringiFor - Skip nested dependencies since we provide them at parent level
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/StringiFor/CMakeLists.txt)
    set(BUILD_TESTING OFF CACHE BOOL "Disable testing for StringiFor" FORCE)
    # Tell StringiFor that dependencies are already available
    set(PENF_FOUND TRUE)
    set(BeFoR64_FOUND TRUE) 
    set(FACE_FOUND TRUE)
    add_subdirectory(StringiFor)
    message(STATUS "Added StringiFor third-party library")
else()
    message(FATAL_ERROR "StringiFor source not found - ensure git submodules are initialized")
endif()

# 5. FoXy - Depends on all previous libraries
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/FoXy/CMakeLists.txt)
    set(BUILD_TESTING OFF CACHE BOOL "Disable testing for FoXy" FORCE)
    add_subdirectory(FoXy)
    message(STATUS "Added FoXy third-party library")
else()
    message(FATAL_ERROR "FoXy source not found - ensure git submodules are initialized")
endif()

# Create an interface target that links all third-party dependencies
# Using namespaced targets as created by the individual libraries
add_library(vtk_fortran_third_party INTERFACE)
target_link_libraries(vtk_fortran_third_party INTERFACE
    PENF::PENF
    BeFoR64::BeFoR64
    StringiFor::StringiFor
    FACE::FACE  
    FoXy::FoXy
)