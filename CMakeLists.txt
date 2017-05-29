PROJECT (SimLang)

cmake_minimum_required(VERSION 2.8)

FIND_PACKAGE(CUDA REQUIRED)
INCLUDE(FindCUDA)
include_directories(${CUDA_INCLUDE_DIRS})
include_directories("/usr/local/cuda-8.0/samples/common/inc/")
link_directories(${CUDA_LINK_DIRS})
SET (CUDA_RT_LIB "/usr/local/cuda-8.0/lib64/")
LINK_DIRECTORIES(${CUDA_RT_LIB})

FIND_PACKAGE(OpenMP)
IF (OPENMP_FOUND)
    SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS} -fPIC")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -fPIC")
ENDIF()
SET (CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS}; -O3 -gencode arch=compute_30,code=sm_30)
ENABLE_LANGUAGE(CXX)

# the option is here so that we can plug it into other
# codes where HDF5 may be optional
option(ENABLE_HDF5 "Enable HDF5 support" ON)
if(ENABLE_HDF5)
    find_package(HDF5)
    if(HDF5_FOUND)
        include_directories(${HDF5_INCLUDE_DIR})
        set(_hdf5_libs hdf5 hdf5_cpp)
    else()
        # we did not find it so we fetch it from the web, configure, compile, and link
        include(ExternalProject)
        set(ExternalProjectCMakeArgs
            -DHDF5_BUILD_CPP_LIB=ON
            )
        set(_hdf5_version "1.8.15-patch1")
        file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/hdf5_local/src)
        ExternalProject_Add(hdf5_local
            DOWNLOAD_COMMAND curl http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-${_hdf5_version}.tar.gz | tar xvz -C ${PROJECT_BINARY_DIR}/hdf5_local/src
            CMAKE_ARGS ${ExternalProjectCMakeArgs}
            SOURCE_DIR ${PROJECT_BINARY_DIR}/hdf5_local/src/hdf5-${_hdf5_version}
            BINARY_DIR ${PROJECT_BINARY_DIR}/hdf5_local/build
            STAMP_DIR  ${PROJECT_BINARY_DIR}/hdf5_local/stamp
            TMP_DIR    ${PROJECT_BINARY_DIR}/hdf5_local/tmp
            INSTALL_COMMAND ""
            )
        include_directories(
            ${PROJECT_BINARY_DIR}/hdf5_local/src/hdf5-${_hdf5_version}/src
            ${PROJECT_BINARY_DIR}/hdf5_local/src/hdf5-${_hdf5_version}/c++/src
            ${PROJECT_BINARY_DIR}/hdf5_local/build
            )
        set(_hdf5_libs
            ${PROJECT_BINARY_DIR}/hdf5_local/build/bin/libhdf5_cpp.a
            ${PROJECT_BINARY_DIR}/hdf5_local/build/bin/libhdf5.a
            -ldl
            )
    endif()
endif()

CUDA_ADD_LIBRARY(simplelang SHARED 
    sl_code.cpp
    sl_misc.cpp
    sl_pars.cpp
    sl_tbl.cpp
    sl_tkn.cpp
    sl_device.cu
    sl_host.cpp
    sl_run.cu
)

CUDA_ADD_EXECUTABLE(simple main.cu)

TARGET_LINK_LIBRARIES(simple simplelang ${_hdf5_libs} cudart)

INSTALL (TARGETS simple RUNTIME DESTINATION /usr/local/bin)
INSTALL (TARGETS simplelang LIBRARY DESTINATION /usr/lib)
INSTALL (FILES sl.h sl_prot.h sl_device.cuh sl_run.cuh DESTINATION /usr/local/include)
