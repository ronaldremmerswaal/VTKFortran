#################################################################
# HEADER
#################################################################
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS TRUE)


PROJECT(VTK_IO Fortran C)

# Note the agreement between the first number of the triplet 
# VERSION and the SOVERSION
SET(${PROJECT_NAME}_VERSION 0.0.1)
SET(${PROJECT_NAME}_SOVERSION 0)

SET(LIB ${PROJECT_NAME})  

SET(CMAKE_VERBOSE_MAKEFILE TRUE)


#################################################################
# DEFINE PATHS
#################################################################

SET(SRC_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src)
SET(LIB_SRC_PATH ${SRC_PATH}/lib)
SET(TEST_SRC_PATH ${SRC_PATH}/tests)

SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake/Modules/")


#################################################################
# BUILD PATHS
#################################################################

SET(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)
SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
SET(CMAKE_Fortran_MODULE_DIRECTORY ${PROJECT_BINARY_DIR}/modules)
INCLUDE_DIRECTORIES(${CMAKE_Fortran_MODULE_DIRECTORY})


#################################################################
# CONFIGURATION TYPES & BUILD MODE
#################################################################

SET(CMAKE_CONFIGURATION_TYPES DEBUG RELEASE)
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE RELEASE CACHE STRING
      "Choose the type of build, options are: NONE DEBUG RELEASE"
      FORCE)

  SET_PROPERTY(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS NONE DEBUG RELEASE)
ENDIF(NOT CMAKE_BUILD_TYPE)


#################################################################
# Setting up options
#################################################################

GET_FILENAME_COMPONENT(Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)

OPTION(${PROJECT_NAME}_ENABLE_F03STD "To force strict conformance to the Fortran 2008 standard" OFF)
OPTION(${PROJECT_NAME}_ENABLE_OPTIMIZE "To activate optimization flags" OFF)
OPTION(${PROJECT_NAME}_ENABLE_OPENMP "To activate the OpenMP extensions for Fortran" OFF)
OPTION(${PROJECT_NAME}_ENABLE_MPI "To compile MPI tests and link against MPI library" OFF)
OPTION(${PROJECT_NAME}_ENABLE_R16P "To define a real precission type with 128 bits" OFF)
#OPTION(${PROJECT_NAME}_ENABLE_HUGE "To use 64 bit instead 32 bit integer as a bit counter" OFF)



IF (${${PROJECT_NAME}_ENABLE_F03STD})
    IF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "GNU" OR Fortran_COMPILER_NAME MATCHES "gfortran*")
        SET(EXTRA_FLAGS "${EXTRA_FLAGS}  -std=f2008 -fall-intrinsics")
    ELSEIF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "Intel" OR Fortran_COMPILER_NAME MATCHES "ifort*")
        SET(EXTRA_FLAGS "${EXTRA_FLAGS}  -std08")
    ENDIF ()
ENDIF ()

IF (${${PROJECT_NAME}_ENABLE_OPTIMIZE})
    IF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "GNU" OR Fortran_COMPILER_NAME MATCHES "gfortran*")
        SET(EXTRA_FLAGS "${EXTRA_FLAGS}  -O3")
    ELSEIF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "Intel" OR Fortran_COMPILER_NAME MATCHES "ifort*")
        SET(EXTRA_FLAGS "${EXTRA_FLAGS}  -O3 -ipo -inline all -ipo-jobs4 -vec-report1")
    ENDIF ()
ENDIF ()

IF (${${PROJECT_NAME}_ENABLE_OPENMP})
    FIND_PACKAGE( OpenMP )
    IF (${OPENMP_FOUND})
        SET(EXTRA_FLAGS ${OpenMP_Fortran_FLAGS})
        ADD_DEFINITIONS("-DOPENMP")
    ELSE ()
        OPTION(${PROJECT_NAME}_ENABLE_OPENMP "To activate the OpenMP extensions for Fortran" OFF)
    ENDIF ()
ENDIF ()

IF (${${PROJECT_NAME}_ENABLE_MPI})
    FIND_PACKAGE(MPI)
    IF(${MPI_FOUND})
        INCLUDE(CMakeForceCompiler)
        CMAKE_FORCE_Fortran_COMPILER(${MPI_Fortran_COMPILER} ${CMAKE_Fortran_COMPILER_ID})
        ADD_DEFINITIONS(${MPI_Fortran_COMPILE_FLAGS})
        INCLUDE_DIRECTORIES(${MPI_Fortran_INCLUDE_PATH})
        LINK_DIRECTORIES(${MPI_Fortran_LIBRARIES})
        ADD_DEFINITIONS("-DMPI2")
    ELSE ()
        OPTION(${PROJECT_NAME}_ENABLE_MPI "To compile MPI tests and link against MPI library" OFF)
    ENDIF ()
ENDIF ()

IF (${${PROJECT_NAME}_ENABLE_R16P})
    ADD_DEFINITIONS("-Dr16p")
ENDIF ()

#IF (${${PROJECT_NAME}_ENABLE_HUGE})
#    ADD_DEFINITIONS("-DHUGE")
#ENDIF ()


#################################################################
# FFLAGS depend on the compiler and the build type
#################################################################


IF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "GNU" OR Fortran_COMPILER_NAME MATCHES "gfortran*")
  # gfortran - append to existing flags if not already present
  set(PROJECT_FORTRAN_FLAGS "-cpp -frealloc-lhs")
  set(PROJECT_Fortran_FLAGS_RELEASE "${EXTRA_FLAGS}")
  set(PROJECT_Fortran_FLAGS_DEBUG "-O0 -g3 -Warray-bounds -Wcharacter-truncation -Wline-truncation -Wimplicit-interface -Wimplicit-procedure -Wunderflow -Wuninitialized -fcheck=all -fmodule-private -ffree-line-length-132 -fimplicit-none -fbacktrace -fdump-core -finit-real=nan -std=f2008 -fall-intrinsics")
  
  # Only append flags if they're not already present
  if(NOT CMAKE_Fortran_FLAGS MATCHES "${PROJECT_FORTRAN_FLAGS}")
    string(STRIP "${CMAKE_Fortran_FLAGS} ${PROJECT_FORTRAN_FLAGS}" CMAKE_Fortran_FLAGS)
  endif()
  if(NOT CMAKE_Fortran_FLAGS_RELEASE MATCHES "${EXTRA_FLAGS}" AND EXTRA_FLAGS)
    string(STRIP "${CMAKE_Fortran_FLAGS_RELEASE} ${PROJECT_Fortran_FLAGS_RELEASE}" CMAKE_Fortran_FLAGS_RELEASE)
  endif()
  if(NOT CMAKE_BUILD_TYPE STREQUAL "RELEASE" AND NOT CMAKE_Fortran_FLAGS_DEBUG MATCHES "fcheck=all")
    string(STRIP "${CMAKE_Fortran_FLAGS_DEBUG} ${PROJECT_Fortran_FLAGS_DEBUG}" CMAKE_Fortran_FLAGS_DEBUG)
  endif()
  
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}" CACHE STRING "Fortran compiler flags" FORCE)
  set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE}" CACHE STRING "Fortran compiler flags for Release" FORCE)
  set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG}" CACHE STRING "Fortran compiler flags for Debug" FORCE)
  
ELSEIF (${CMAKE_Fortran_COMPILER_ID} STREQUAL "Intel" OR Fortran_COMPILER_NAME MATCHES "ifort*")
  # ifort - append to existing flags if not already present
  set(PROJECT_FORTRAN_FLAGS "-cpp -assume realloc_lhs")
  set(PROJECT_Fortran_FLAGS_RELEASE "${EXTRA_FLAGS}")
  set(PROJECT_Fortran_FLAGS_DEBUG "-O0 -debug all -check all -warn all -extend-source 132 -traceback -gen-interfaces")
  #-fpe-all=0 -fp-stack-check -fstack-protector-all -ftrapuv -no-ftz -std03
  
  # Only append flags if they're not already present
  if(NOT CMAKE_Fortran_FLAGS MATCHES "${PROJECT_FORTRAN_FLAGS}")
    string(STRIP "${CMAKE_Fortran_FLAGS} ${PROJECT_FORTRAN_FLAGS}" CMAKE_Fortran_FLAGS)
  endif()
  if(NOT CMAKE_Fortran_FLAGS_RELEASE MATCHES "${EXTRA_FLAGS}" AND EXTRA_FLAGS)
    string(STRIP "${CMAKE_Fortran_FLAGS_RELEASE} ${PROJECT_Fortran_FLAGS_RELEASE}" CMAKE_Fortran_FLAGS_RELEASE)
  endif()
  if(NOT CMAKE_BUILD_TYPE STREQUAL "RELEASE" AND NOT CMAKE_Fortran_FLAGS_DEBUG MATCHES "check all")
    string(STRIP "${CMAKE_Fortran_FLAGS_DEBUG} ${PROJECT_Fortran_FLAGS_DEBUG}" CMAKE_Fortran_FLAGS_DEBUG)
  endif()
  
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}" CACHE STRING "Fortran compiler flags" FORCE)
  set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE}" CACHE STRING "Fortran compiler flags for Release" FORCE)
  set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG}" CACHE STRING "Fortran compiler flags for Debug" FORCE)
  
ELSE ()
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  # Append basic optimization flags to existing flags
  string(STRIP "${CMAKE_Fortran_FLAGS_RELEASE} -O2" CMAKE_Fortran_FLAGS_RELEASE)
  string(STRIP "${CMAKE_Fortran_FLAGS_DEBUG} -O0 -g" CMAKE_Fortran_FLAGS_DEBUG)
  
  set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE}" CACHE STRING "Fortran compiler flags for Release" FORCE)
  set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG}" CACHE STRING "Fortran compiler flags for Debug" FORCE)
ENDIF ()

message("CMAKE_Fortran_FLAGS: ${CMAKE_Fortran_FLAGS}")
message("CMAKE_Fortran_FLAGS_RELEASE: ${CMAKE_Fortran_FLAGS_RELEASE}")
message("CMAKE_Fortran_FLAGS_DEBUG: ${CMAKE_Fortran_FLAGS_DEBUG}")
message("CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")


#################################################################
# ADD SOURCE SUBDIRS
#################################################################

# Add third-party dependencies first
ADD_SUBDIRECTORY(${SRC_PATH}/third_party)

ADD_SUBDIRECTORY(${LIB_SRC_PATH})
ADD_SUBDIRECTORY(${TEST_SRC_PATH})

