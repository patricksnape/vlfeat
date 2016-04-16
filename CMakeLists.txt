cmake_minimum_required (VERSION 3.4)
project (VLFEAT VERSION 0.9.20)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(CompilerMacro)
include(Prepend)
include(AddExe)
include(AddTestExe)

# All the compilation options
set(BUILD_TESTS_STR "If enabled, build tests.")
option(BUILD_TESTS ${BUILD_TESTS_STR} ON)

set(BUILD_MATLAB_TOOLBOX_STR "If enabled, build the Matlab toolbox.")
option(BUILD_MATLAB_TOOLBOX ${BUILD_MATLAB_TOOLBOX_STR} OFF)

set(DISABLE_SSE2_STR "Disables SSE2 intrinsics.")
option(DISABLE_SSE2 ${DISABLE_SSE2_STR} OFF)

set(DISABLE_AVX_STR "Disables AVX intrinsics.")
option(DISABLE_AVX ${DISABLE_AVX_STR} OFF)

set(DISABLE_THREADS_STR "Disables support for pthread multithreading.")
option(DISABLE_THREADS ${DISABLE_THREADS_STR} OFF)

set(DISABLE_OPENMP_STR "Disables support for OpenMP multithreading.")
option(DISABLE_OPENMP ${DISABLE_OPENMP_STR} OFF)

# Set up the configuration files
vl_determine_compiler()

# Optimisation options
if (VL_COMPILER_IS_GCC OR VL_COMPILER_IS_CLANG)
	if (CMAKE_BUILD_TYPE STREQUAL "Debug")
		set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG -O0")
	elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
		set(CMAKE_C_FLAGS_RELWITHDEBINFO "-g -DDEBUG -O3")
	else()
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNDEBUG -O3")
	endif()
elseif(VL_COMPILER_IS_MSVC)

endif()

set(VL_VL_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vl")
set(VL_LIB_SRC aib.c array.c covdet.c dsift.c fisher.c generic.c getopt_long.c
gmm.c hikmeans.c hog.c homkermap.c host.c ikmeans.c imopv_sse2.c imopv.c
kdtree.c kmeans.c lbp.c liop.c mathop_avx.c mathop_sse2.c mathop.c mser.c pgm.c
quickshift.c random.c rodrigues.c scalespace.c sift.c slic.c stringop.c svm.c
svmdataset.c vlad.c)
Prepend(VL_LIB_SRC ${VL_VL_SRC_DIR} ${VL_LIB_SRC})

add_library(vlfeat SHARED ${VL_LIB_SRC})
target_include_directories(vlfeat PUBLIC ${VL_VL_SRC_DIR})

# General compilation options for the vlfeat shared library
if (VL_COMPILER_IS_GCC OR VL_COMPILER_IS_CLANG)
	target_compile_definitions(vlfeat PRIVATE -DVL_BUILD_DLL)
	# Warnings
	target_compile_options(vlfeat PRIVATE -Wno-unused-function -Wno-long-long 
	                                      -Wno-variadic-macros -Wall -Wextra)
	target_compile_options(vlfeat PRIVATE -std=c99 -fvisibility=hidden)
	target_link_libraries(vlfeat PUBLIC m)
elseif(VL_COMPILER_IS_MSVC)

endif()

if (DISABLE_SSE)
	message(STATUS "VL - SSE2: Disabled")
    target_compile_definitions(vlfeat PRIVATE -DVL_DISABLE_SSE2)
else()
	message(STATUS "VL - SSE2: Enabled")
    if (VL_COMPILER_IS_MSVC)
    	target_compile_options(vlfeat PUBLIC "/arch:SSE2")
    else()
        target_compile_options(vlfeat PUBLIC "-msse2")
    endif()
endif()
if (DISABLE_AVX)
	message(STATUS "VL - AVX: Disabled")
    target_compile_definitions(vlfeat PRIVATE -DVL_DISABLE_AVX)
else()
	message(STATUS "VL - AVX: Enabled")
    if (VL_COMPILER_IS_MSVC)
    	target_compile_options(vlfeat PUBLIC "/arch:AVX")
    else()
        target_compile_options(vlfeat PUBLIC "-mavx")
    endif()
endif()
if (DISABLE_THREADS)
	message(STATUS "VL - PThreads: Disabled")
    target_compile_definitions(vlfeat PRIVATE -DVL_DISABLE_THREADS)
endif()

FIND_PACKAGE(OpenMP QUIET)
if (DISABLE_OPENMP OR NOT OPENMP_FOUND)
	message(STATUS "VL - OpenMP: Disabled")
    target_compile_definitions(vlfeat PRIVATE -DVL_DISABLE_OPENMP)
    if (NOT DISABLE_OPENMP)
    	message(WARNING "VL - OpenMP was requested, but could not be found, disabling.")
    endif()
elseif(OPENMP_FOUND)
	message(STATUS "VL - OpenMP: Enabled")
	target_compile_options(vlfeat PUBLIC ${OpenMP_C_FLAGS})
	target_link_libraries(vlfeat PUBLIC ${OpenMP_C_FLAGS})
endif()

if (APPLE)
	set_target_properties(vlfeat PROPERTIES LINK_FLAGS "-undefined suppress -flat_namespace -compatibility_version ${VLFEAT_VERSION} -current_version ${VLFEAT_VERSION}")
elseif(${CMAKE_SYSTEM_NAME} MATCHES ".*Linux.*")
	target_compile_definitions(vlfeat PRIVATE -D_GNU_SOURCE)
	target_compile_options(vlfeat PRIVATE -fno-stack-protector)
endif()

# Executables/Tests
AddExe(aib)
AddExe(mser)
AddExe(sift)

if (BUILD_TESTS)
	message(STATUS "VL - Building Tests")
	enable_testing()
	AddTestExe(gauss_elimination)
	AddTestExe(getopt_long)
	AddTestExe(gmm)
	AddTestExe(host)
	AddTestExe(imopv)
	AddTestExe(kmeans)
	AddTestExe(liop)
	AddTestExe(mathop_abs)
	AddTestExe(mathop)
	AddTestExe(nan)
	AddTestExe(rand)
	AddTestExe(sqrti)
	AddTestExe(stringop)
	AddTestExe(svd2)
	AddTestExe(threads)
	AddTestExe(vec_comp)
else()
	message(STATUS "VL - NOT building Tests")
endif()

# Matlab
if (BUILD_MATLAB_TOOLBOX)
	FIND_PACKAGE(Matlab REQUIRED)
	message(SEND_ERROR "Matlab builds are not currently supported from CMake.")
endif()

#set_target_properties(libjpeg PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
#add_definitions(-D_CRT_SECURE_NO_WARNINGS)
#target_link_libraries (wrjpgcom libjpeg)
#add_library(jpeg STATIC ${JPEG_SRC})

install(TARGETS vlfeat
  		RUNTIME DESTINATION bin
  		LIBRARY DESTINATION lib
  		ARCHIVE DESTINATION lib)

file(GLOB VL_HEADERS ${VL_LIB_SRC_DIR}/*.h)
install(FILES ${VL_HEADERS} DESTINATION include)
