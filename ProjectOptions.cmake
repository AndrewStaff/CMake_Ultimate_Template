include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(CMake_Ultimate_Template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(CMake_Ultimate_Template_setup_options)
  option(CMake_Ultimate_Template_ENABLE_HARDENING "Enable hardening" ON)
  option(CMake_Ultimate_Template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    CMake_Ultimate_Template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    CMake_Ultimate_Template_ENABLE_HARDENING
    OFF)

  CMake_Ultimate_Template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR CMake_Ultimate_Template_PACKAGING_MAINTAINER_MODE)
    option(CMake_Ultimate_Template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(CMake_Ultimate_Template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(CMake_Ultimate_Template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(CMake_Ultimate_Template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(CMake_Ultimate_Template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(CMake_Ultimate_Template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(CMake_Ultimate_Template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(CMake_Ultimate_Template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(CMake_Ultimate_Template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(CMake_Ultimate_Template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(CMake_Ultimate_Template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(CMake_Ultimate_Template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(CMake_Ultimate_Template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(CMake_Ultimate_Template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(CMake_Ultimate_Template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      CMake_Ultimate_Template_ENABLE_IPO
      CMake_Ultimate_Template_WARNINGS_AS_ERRORS
      CMake_Ultimate_Template_ENABLE_USER_LINKER
      CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS
      CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK
      CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED
      CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD
      CMake_Ultimate_Template_ENABLE_SANITIZER_MEMORY
      CMake_Ultimate_Template_ENABLE_UNITY_BUILD
      CMake_Ultimate_Template_ENABLE_CLANG_TIDY
      CMake_Ultimate_Template_ENABLE_CPPCHECK
      CMake_Ultimate_Template_ENABLE_COVERAGE
      CMake_Ultimate_Template_ENABLE_PCH
      CMake_Ultimate_Template_ENABLE_CACHE)
  endif()

  CMake_Ultimate_Template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS OR CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD OR CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(CMake_Ultimate_Template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(CMake_Ultimate_Template_global_options)
  if(CMake_Ultimate_Template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    CMake_Ultimate_Template_enable_ipo()
  endif()

  CMake_Ultimate_Template_supports_sanitizers()

  if(CMake_Ultimate_Template_ENABLE_HARDENING AND CMake_Ultimate_Template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${CMake_Ultimate_Template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED}")
    CMake_Ultimate_Template_enable_hardening(CMake_Ultimate_Template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(CMake_Ultimate_Template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(CMake_Ultimate_Template_warnings INTERFACE)
  add_library(CMake_Ultimate_Template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  CMake_Ultimate_Template_set_project_warnings(
    CMake_Ultimate_Template_warnings
    ${CMake_Ultimate_Template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(CMake_Ultimate_Template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    CMake_Ultimate_Template_configure_linker(CMake_Ultimate_Template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  CMake_Ultimate_Template_enable_sanitizers(
    CMake_Ultimate_Template_options
    ${CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS}
    ${CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK}
    ${CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED}
    ${CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD}
    ${CMake_Ultimate_Template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(CMake_Ultimate_Template_options PROPERTIES UNITY_BUILD ${CMake_Ultimate_Template_ENABLE_UNITY_BUILD})

  if(CMake_Ultimate_Template_ENABLE_PCH)
    target_precompile_headers(
      CMake_Ultimate_Template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(CMake_Ultimate_Template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    CMake_Ultimate_Template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(CMake_Ultimate_Template_ENABLE_CLANG_TIDY)
    CMake_Ultimate_Template_enable_clang_tidy(CMake_Ultimate_Template_options ${CMake_Ultimate_Template_WARNINGS_AS_ERRORS})
  endif()

  if(CMake_Ultimate_Template_ENABLE_CPPCHECK)
    CMake_Ultimate_Template_enable_cppcheck(${CMake_Ultimate_Template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(CMake_Ultimate_Template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    CMake_Ultimate_Template_enable_coverage(CMake_Ultimate_Template_options)
  endif()

  if(CMake_Ultimate_Template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(CMake_Ultimate_Template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(CMake_Ultimate_Template_ENABLE_HARDENING AND NOT CMake_Ultimate_Template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_UNDEFINED
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_ADDRESS
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_THREAD
       OR CMake_Ultimate_Template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    CMake_Ultimate_Template_enable_hardening(CMake_Ultimate_Template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
