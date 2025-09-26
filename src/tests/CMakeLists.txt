# VTKFortran test executables

# Only build tests if testing is enabled
if(BUILD_TESTING)
    # Collect all Fortran test source files
    file(GLOB VTK_FORTRAN_TEST_SOURCES "*.f90" "*.F90")
    
    # Create test executables
    foreach(test_source ${VTK_FORTRAN_TEST_SOURCES})
        get_filename_component(test_name ${test_source} NAME_WE)
        add_executable(${test_name} ${test_source})
        target_link_libraries(${test_name} ${LIB})
        
        # Add as a test if it follows naming convention
        if(test_name MATCHES "vtk_fortran_")
            add_test(NAME ${test_name} COMMAND ${test_name})
        endif()
    endforeach()
endif()