# VTK_IO library source files

# Collect all Fortran source files
file(GLOB VTK_FORTRAN_SOURCES "*.f90" "*.F90")

# Create the VTK_IO library
add_library(${LIB} ${VTK_FORTRAN_SOURCES})

# Link against third-party dependencies as PRIVATE to avoid propagating dependencies
target_link_libraries(${LIB} PRIVATE 
    PENF::PENF
    BeFoR64::BeFoR64
    StringiFor::StringiFor
    FoXy::FoXy
)

# Set target properties
set_target_properties(${LIB} PROPERTIES
    VERSION ${${PROJECT_NAME}_VERSION}
    SOVERSION ${${PROJECT_NAME}_SOVERSION}
    Fortran_MODULE_DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}
)

# Create alias for namespaced usage
add_library(VTK_IO::VTK_IO ALIAS ${LIB})

# Install library with export
install(TARGETS ${LIB}
    EXPORT VTK_IOTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    INCLUDES DESTINATION include
)

# Install module files
install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/
    DESTINATION include
    FILES_MATCHING PATTERN "*.mod"
)