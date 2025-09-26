# VTKFortran library source files

# Collect all Fortran source files
file(GLOB VTK_FORTRAN_SOURCES "*.f90" "*.F90")

# Create the VTKFortran library
add_library(${LIB} ${VTK_FORTRAN_SOURCES})

# Set target properties
set_target_properties(${LIB} PROPERTIES
    VERSION ${${PROJECT_NAME}_VERSION}
    SOVERSION ${${PROJECT_NAME}_SOVERSION}
)

# Install library
install(TARGETS ${LIB}
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Install module files
install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/
    DESTINATION include
    FILES_MATCHING PATTERN "*.mod"
)