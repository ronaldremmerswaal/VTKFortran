# VTK_IO library source files

# Collect all Fortran source files
file(GLOB VTK_FORTRAN_SOURCES "*.f90" "*.F90")

# Create the VTK_IO library
add_library(${LIB} ${VTK_FORTRAN_SOURCES})

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

# Add build-time include directories for third-party modules
# These paths are needed for VTK_IO sources to find dependency module files
target_include_directories(${LIB} PRIVATE
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/third_party/PENF/modules>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/third_party/BeFoR64/modules>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/third_party/StringiFor/modules>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/third_party/FACE/modules>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/third_party/FoXy/modules>
)

# Set include directories for consumers
target_include_directories(${LIB} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_Fortran_MODULE_DIRECTORY}>
    $<INSTALL_INTERFACE:include>
)

# For static libraries, create a monolithic library by combining all static libraries
# For shared libraries, link to dependencies normally
if(BUILD_SHARED_LIBS)
    target_link_libraries(${LIB} PUBLIC 
        PENF::PENF
        BeFoR64::BeFoR64
        StringiFor::StringiFor
        FACE::FACE
        FoXy::FoXy
    )
else()
    # For static libraries, create a combined library using a custom target
    message(STATUS "VTK_IO: Building as static library - combining with dependencies")
    
    # Make sure dependencies are built but don't link to avoid export issues
    add_dependencies(${LIB} PENF BeFoR64 StringiFor FACE FoXy)
    
    # Create a custom command to combine all static libraries
    add_custom_command(TARGET ${LIB} POST_BUILD
        # First extract VTK_IO objects from the original library
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:${LIB}>
        # Then extract all dependency objects
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:PENF>
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:BeFoR64> 
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:StringiFor>
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:FACE>
        COMMAND ${CMAKE_AR} -x $<TARGET_FILE:FoXy>
        # Create new combined library with all objects
        COMMAND ${CMAKE_AR} -qcs $<TARGET_FILE:${LIB}> *.o
        COMMAND ${CMAKE_COMMAND} -E remove *.o
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Combining static libraries into monolithic VTK_IO library"
    )
endif()

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