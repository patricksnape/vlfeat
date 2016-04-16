# This macro is based of the vc_determine_compiler from the VC project
# https://github.com/VcDevel/Vc and is used under the terms of their 
# permissive BSD-3 Clause license. A copy of their license can be obtained at
# Vc_LICENSE in this directory.
# Copyright © 2009-2015 Matthias Kretz <kretz@kde.org>

get_filename_component(_currentDir "${CMAKE_CURRENT_LIST_FILE}" PATH)

macro(vl_determine_compiler)
   if(NOT DEFINED VL_COMPILER_IS_INTEL)
      execute_process(COMMAND "${CMAKE_CXX_COMPILER}" "--version" OUTPUT_VARIABLE _cxx_compiler_version ERROR_VARIABLE _cxx_compiler_version)
      set(VL_COMPILER_IS_INTEL false)
      set(VL_COMPILER_IS_OPEN64 false)
      set(VL_COMPILER_IS_CLANG false)
      set(VL_COMPILER_IS_MSVC false)
      set(VL_COMPILER_IS_GCC false)
      if(CMAKE_CXX_COMPILER MATCHES "/(icpc|icc)$")
         set(VL_COMPILER_IS_INTEL true)
         exec_program(${CMAKE_CXX_COMPILER} ARGS -dumpversion OUTPUT_VARIABLE VL_ICC_VERSION)
         message(STATUS "Detected Compiler: Intel ${VL_ICC_VERSION}")
      elseif(CMAKE_CXX_COMPILER MATCHES "(opencc|openCC)$")
         set(VL_COMPILER_IS_OPEN64 true)
         message(STATUS "Detected Compiler: Open64")
      elseif(CMAKE_CXX_COMPILER MATCHES "clang\\+\\+$" OR "${_cxx_compiler_version}" MATCHES "clang")
         set(VL_COMPILER_IS_CLANG true)
         exec_program(${CMAKE_CXX_COMPILER} ARGS --version OUTPUT_VARIABLE VL_CLANG_VERSION)
         string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" VL_CLANG_VERSION "${VL_CLANG_VERSION}")
         message(STATUS "Detected Compiler: Clang ${VL_CLANG_VERSION}")

         # Clang prior to 3.8.0 does not support OpenMP
         if(VL_CLANG_VERSION VERSION_LESS 3.8.0 AND NOT DISABLE_OPENMP)
            message(WARNING "Clang prior to 3.8.0 does not support OpenMP, disabling.")
            set(DISABLE_OPENMP ON CACHE STRING ${DISABLE_DISABLE_OPENMP_STR} FORCE)
         endif()
      elseif(MSVC)
         set(VL_COMPILER_IS_MSVC true)
         execute_process(COMMAND ${CMAKE_CXX_COMPILER} /nologo -EP "${_currentDir}/msvc_version.c" OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE VL_MSVC_VERSION)
         string(STRIP "${VL_MSVC_VERSION}" VL_MSVC_VERSION)
         string(REPLACE "MSVC " "" VL_MSVC_VERSION "${VL_MSVC_VERSION}")
         message(STATUS "Detected Compiler: MSVC ${VL_MSVC_VERSION}")
      elseif(CMAKE_COMPILER_IS_GNUCXX)
         set(VL_COMPILER_IS_GCC true)
         exec_program(${CMAKE_CXX_COMPILER} ARGS -dumpversion OUTPUT_VARIABLE VL_GCC_VERSION)
         message(STATUS "Detected Compiler: GCC ${VL_GCC_VERSION}")

         # some distributions patch their GCC to return nothing or only major and minor version on -dumpversion.
         # In that case we must extract the version number from --version.
         if(NOT VL_GCC_VERSION OR VL_GCC_VERSION MATCHES "^[0-9]\\.[0-9]+$")
            exec_program(${CMAKE_CXX_COMPILER} ARGS --version OUTPUT_VARIABLE VL_GCC_VERSION)
            string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" VL_GCC_VERSION "${VL_GCC_VERSION}")
            message(STATUS "GCC Version from --version: ${VL_GCC_VERSION}")
         endif()

         # GCC prior to 4.6.0 did not support AVX
         if(VL_GCC_VERSION VERSION_LESS 4.6.0 AND NOT DISABLE_AVX)
            message(WARNING "GCC prior to 4.6.0 does not support AVX, disabling.")
            set(DISABLE_AVX ON CACHE STRING ${DISABLE_AVX_STR} FORCE)
         endif()
      else()
         message(WARNING "Untested/-supported Compiler (${CMAKE_CXX_COMPILER}) for use with Vlfeat.\nPlease fill out the missing parts in the CMake scripts and submit a patch to http://github.com/vlfeat/vlfeat")
      endif()
   endif()
endmacro()