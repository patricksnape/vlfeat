macro(AddExe exe_name)
   add_executable(${exe_name} ${CMAKE_CURRENT_SOURCE_DIR}/src/${exe_name}.c)
   target_link_libraries(${exe_name} vlfeat)
   target_include_directories(${exe_name} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
   install(TARGETS ${exe_name} RUNTIME DESTINATION bin)
endmacro()
