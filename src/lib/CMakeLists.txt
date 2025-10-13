# VTK_IO library source files

# Collect all Fortran source files
file(GLOB VTK_FORTRAN_SOURCES "*.f90" "*.F90")

# Create the VTK_IO library
add_library(${LIB} ${VTK_FORTRAN_SOURCES})

# For shared library builds, we want to hide third-party dependencies
# For static library builds, dependencies need to be propagated
if(BUILD_SHARED_LIBS)
    # Link third-party dependencies as PRIVATE to hide them from consumers
    target_link_libraries(${LIB} PRIVATE 
        PENF::PENF
        BeFoR64::BeFoR64
        StringiFor::StringiFor
        FoXy::FoXy
    )
else()
    # For static libraries, dependencies must be PUBLIC to be propagated
    target_link_libraries(${LIB} PUBLIC 
        PENF::PENF
        BeFoR64::BeFoR64
        StringiFor::StringiFor
        FoXy::FoXy
    )
endif()

# Set target properties
set_target_properties(${LIB} PROPERTIES
    VERSION ${${PROJECT_NAME}_VERSION}
    SOVERSION ${${PROJECT_NAME}_SOVERSION}
    Fortran_MODULE_DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}
    INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib"
    INSTALL_RPATH_USE_LINK_PATH TRUE
)

# For shared libraries, ensure dependencies don't leak symbols
if(BUILD_SHARED_LIBS)
    set_target_properties(${LIB} PROPERTIES
        CXX_VISIBILITY_PRESET hidden
        C_VISIBILITY_PRESET hidden  
        VISIBILITY_INLINES_HIDDEN ON
    )
endif()

# Set include directories for consumers
target_include_directories(${LIB} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_Fortran_MODULE_DIRECTORY}>
    $<INSTALL_INTERFACE:include>
    $<INSTALL_INTERFACE:include/PENF>
    $<INSTALL_INTERFACE:include/BeFoR64>
    $<INSTALL_INTERFACE:include/StringiFor>
    $<INSTALL_INTERFACE:include/FACE>
    $<INSTALL_INTERFACE:include/FoXy>
)

# Create alias for namespaced usage
add_library(VTK_IO::VTK_IO ALIAS ${LIB})

# Install library with export
install(TARGETS ${LIB}
    EXPORT VTK_IOTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

# Install module files
install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/
    DESTINATION include
    FILES_MATCHING PATTERN "*.mod"
)