
#################################################
# ign_find_package(<PACKAGE_NAME>
#                  [REQUIRED] [PRIVATE] [EXACT] [QUIET] [BUILD_ONLY] [PKGCONFIG_IGNORE]
#                  [COMPONENTS <components_of_PACKAGE_NAME>]
#                  [OPTIONAL_COMPONENTS <components_of_PACKAGE_NAME>]
#                  [REQUIRED_BY <components_of_project>]
#                  [PRIVATE_FOR <components_of_project>]
#                  [VERSION <ver>]
#                  [EXTRA_ARGS <args>]
#                  [PRETTY <name>]
#                  [PURPOSE <"explanation for this dependency">]
#                  [PKGCONFIG <pkgconfig_name>]
#                  [PKGCONFIG_LIB <lib_name>]
#                  [PKGCONFIG_VER_COMPARISON  <  >  =  <=  >= ])
#
# This is a wrapper for the standard cmake find_package which behaves according
# to the conventions of the ignition library. In particular, we do not quit
# immediately when a required package is missing. Instead, we check all
# dependencies and provide an overview of what is missing at the end of the
# configuration process. Descriptions of the function arguments are as follows:
#
# <PACKAGE_NAME>: The name of the package as it would normally be passed to
#                 find_package(~). Note if your package corresponds to a
#                 find-module named FindABC.cmake, then <PACKAGE_NAME> must be
#                 ABC, with the case matching. If the find-module is named
#                 FindAbc.cmake, then <PACKAGE_NAME> must be Abc. This will not
#                 necessarily match the library's actual name, nor will it
#                 necessarily match the name used by pkgconfig, so there are
#                 additional arguments (i.e. PRETTY, PKGCONFIG) to specify
#                 alternative names for this package that can be used depending
#                 on the context.
#
# [REQUIRED]: Optional. If provided, macro will trigger an ignition build_error
#             when the package cannot be found. If not provided, this macro will
#             trigger an ignition build_warning when the package is not found.
#             To specify that something is required by some set of components
#             (rather than the main library), use REQUIRED_BY.
#
# [PRIVATE]: Optional. Use this to indicate that consumers of the project do not
#            need to link against the package, but it must be present on the
#            system, because our project must link against it.
#
# [EXACT]: Optional. This will pass on the EXACT option to find_package(~) and
#          also add it to the call to find_dependency(~) in the
#          <project>-config.cmake file.
#
# [QUIET]: Optional. If provided, it will be passed forward to cmake's
#          find_package(~) command. This macro will still print its normal
#          output.
#
# [BUILD_ONLY]: Optional. Use this to indicate that the project only needs this
#               package while building, and it does not need to be available to
#               the consumer of this project at all. Normally this should only
#               apply to (1) a header-only library whose headers are included
#               exclusively in the source files and not included in any public
#               (i.e. installed) project headers, or to (2) a static library
#               dependency.
#
# [PKGCONFIG_IGNORE]: Discouraged. If this option is provided, this package will
#                     not be added to the project's pkgconfig file in any way.
#                     This should only be used in very rare circumstances. Note
#                     that BUILD_ONLY will also prevent a pkgconfig entry from
#                     being produced.
#
# [COMPONENTS]: Optional. If provided, the list that follows it will be passed
#               to find_package(~) to indicate which components of PACKAGE_NAME
#               are considered to be dependencies of either this project
#               (specified by REQUIRED) or this project's components (specified
#               by REQUIRED_BY). This is effectively the same as the
#               find_package( ... COMPONENTS <components>) argument.
#
# [REQUIRED_BY]: Optional. If provided, the list that follows it must indicate
#                which library components require the dependency. Note that if
#                REQUIRED is specified, then REQUIRED_BY does NOT need to be
#                specified for any components which depend on the main library,
#                because their dependence on this package will effectively be
#                inherited from the main library. This will trigger a build
#                warning to tell the user which component requires this
#                dependency.
#
# [PRIVATE_FOR]: Optional. If provided, the list that follows it must indicate
#                which library components depend on this package privately (i.e.
#                the package should not be included in its list of interface
#                libraries). This is only relevant for components that follow
#                the REQUIRED_BY command. Note that the PRIVATE argument does
#                not apply to components specified by REQUIRED_BY. This argument
#                MUST be given for components whose private dependencies have
#                been specified with REQUIRED_BY.
#
# [VERSION]: Optional. Follow this argument with the major[.minor[.patch[.tweak]]]
#            version that you need for this package.
#
# [EXTRA_ARGS]: Optional. Additional args to pass forward to find_package(~)
#
# [PRETTY]: Optional. If provided, the string that follows will replace
#           <PACKAGE_NAME> when printing messages, warnings, or errors to the
#           terminal.
#
# [PURPOSE]: Optional. If provided, the string that follows will be appended to
#            the build_warning or build_error that this function produces when
#            the package could not be found.
#
#  ==========================================================================
#  The following arguments pertain to the automatic generation of your
#  project's pkgconfig file. Ideally, this information should be provided
#  automatically by ignition-cmake through the cmake find-module that is written
#  for your dependency. However, if your package gets distributed with its own
#  cmake config-file or find-module, then it might not automatically set this
#  information. Therefore, we provide the ability to set it through your call to
#  ign_find_package(~). Do not hesitate to ask for help if you need to use these
#  arguments.
#
# [PKGCONFIG]: Optional. If provided, the string that follows will be used to
#              specify a "required" package for pkgconfig. If not provided, then
#              <PACKAGE_NAME> will be used instead.
#
# [PKGCONFIG_LIB]: Optional. Use this to indicate that the package should be
#                  considered a "library" by pkgconfig. This is used for
#                  libraries which do not come with *.pc metadata, such as
#                  system libraries, libm, libdl, or librt. Generally you should
#                  leave this out, because most packages will be considered
#                  "modules" by pkgconfig. The string which follows this argument
#                  will be used as the library name, and the string that follows
#                  a PKGCONFIG argument will be ignored, so the PKGCONFIG
#                  argument can be left out when using this argument.
#
# [PKGCONFIG_VER_COMPARISON]: Optional. If provided, pkgconfig will be told how
#                             the available version of this package must compare
#                             to the specified version. Acceptable values are
#                             =, <, >, <=, >=. Default will be =. If no version
#                             is provided using VERSION, then this will be left
#                             out, whether or not it is provided.
#
macro(ign_find_package PACKAGE_NAME)

  #------------------------------------
  # Define the expected arguments
  set(options REQUIRED EXACT QUIET PRIVATE BUILD_ONLY)
  set(oneValueArgs VERSION PRETTY PURPOSE EXTRA_ARGS PKGCONFIG PKGCONFIG_LIB PKGCONFIG_VER_COMPARISON)
  set(multiValueArgs REQUIRED_BY PRIVATE_FOR COMPONENTS OPTIONAL_COMPONENTS)

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_find_package "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  #------------------------------------
  # Construct the arguments to pass to find_package
  set(${PACKAGE_NAME}_find_package_args ${PACKAGE_NAME})

  if(ign_find_package_VERSION)
    list(APPEND ${PACKAGE_NAME}_find_package_args ${ign_find_package_VERSION})
  endif()

  if(ign_find_package_QUIET)
    list(APPEND ${PACKAGE_NAME}_find_package_args QUIET)
  endif()

  if(ign_find_package_EXACT)
    list(APPEND ${PACKAGE_NAME}_find_package_args EXACT)
  endif()

  if(ign_find_package_COMPONENTS)
    list(APPEND ${PACKAGE_NAME}_find_package_args COMPONENTS ${ign_find_package_COMPONENTS})
  endif()

  if(ign_find_package_OPTIONAL_COMPONENTS)
    list(APPEND ${PACKAGE_NAME}_find_package_args OPTIONAL_COMPONENTS ${ign_find_package_OPTIONAL_COMPONENTS})
  endif()

  if(ign_find_package_EXTRA_ARGS)
    list(APPEND ${PACKAGE_NAME}_find_package_args ${ign_find_package_EXTRA_ARGS})
  endif()


  #------------------------------------
  # Figure out which name to print
  if(ign_find_package_PRETTY)
    set(${PACKAGE_NAME}_pretty ${ign_find_package_PRETTY})
  else()
    set(${PACKAGE_NAME}_pretty ${PACKAGE_NAME})
  endif()


  #------------------------------------
  # Call find_package with the provided arguments
  find_package(${${PACKAGE_NAME}_find_package_args})
  if(${PACKAGE_NAME}_FOUND)

    message(STATUS "Looking for ${${PACKAGE_NAME}_pretty} - found\n")

  else()

    message(STATUS "Looking for ${${PACKAGE_NAME}_pretty} - not found\n")

    #------------------------------------
    # Construct the warning/error message to produce
    set(${PACKAGE_NAME}_msg "Missing: ${${PACKAGE_NAME}_pretty}")
    if(DEFINED ign_find_package_PURPOSE)
      set(${PACKAGE_NAME}_msg "${${PACKAGE_NAME}_msg} - ${ign_find_package_PURPOSE}")
    endif()

    #------------------------------------
    # If the package is unavailable, tell the user.
    if(ign_find_package_REQUIRED)

      # If it was required by the project, we will create an error.
      ign_build_error(${${PACKAGE_NAME}_msg})

    elseif(ign_find_package_REQUIRED_BY)

      foreach(component ${ign_find_package_REQUIRED_BY})

        # Otherwise, if it was only required by some of the components, create
        # a warning about which components will not be available.
        ign_build_warning("Cannot build component [${component}] - ${${PACKAGE_NAME}_msg}")

        # Also create a variable to indicate that we should skip the component
        set(SKIP_${component} true)

      endforeach()

    else()
      ign_build_warning(${${PACKAGE_NAME}_msg})
    endif()

  endif()


  #------------------------------------
  # Add this package to the list of dependencies that will be inserted into the
  # find-config file, unless the invoker specifies that it should not be added.
  # Also, add this package or library as an entry to the pkgconfig file that we
  # will produce for our project.
  if( (ign_find_package_REQUIRED OR ign_find_package_REQUIRED_BY) AND NOT ign_find_package_BUILD_ONLY)

    # Set up the arguments we want to pass to the find_dependency invokation for
    # our ignition project. We always need to pass the name of the dependency.
    #
    # NOTE: We escape the dollar signs because we want those variable
    #       evaluations to be a part of the string that we produce. It is going
    #       to be put into a *-config.cmake file. Those variables determine
    #       whether the find_package(~) call will be REQUIRED and/or QUIET.
    #
    # TODO: When we migrate to cmake-3.9+, this can be removed because calling
    #       find_dependency(~) will automatically forward these properties.
    set(${PACKAGE_NAME}_dependency_args "${PACKAGE_NAME}")

    # If a version is provided here, we should pass that as well.
    if(ign_find_package_VERSION)
      ign_string_append(${PACKAGE_NAME}_dependency_args ${ign_find_package_VERSION})
    endif()

    # If we have specified the exact version, we should provide that as well.
    if(ign_find_package_EXACT)
      ign_string_append(${PACKAGE_NAME}_dependency_args EXACT)
    endif()

    # NOTE (MXG): 7 seems to be the number of escapes required to get
    # "${ign_package_required}" and "${ign_package_quiet}" to show up correctly
    # as strings in the final config-file outputs. It is unclear to me why the
    # escapes get collapsed exactly three times, so it is possible that any
    # changes to this script could cause a different number of escapes to be
    # necessary. Please use caution when modifying this script.
    ign_string_append(${PACKAGE_NAME}_dependency_args "\\\\\\\${ign_package_quiet} \\\\\\\${ign_package_required}")

    # If we have specified components of the dependency, mention those.
    if(ign_find_package_COMPONENTS)
      ign_string_append(${PACKAGE_NAME}_dependency_args "COMPONENTS ${ign_find_package_COMPONENTS}")
    endif()

    # If there are any additional arguments for the find_package(~) command,
    # forward them along.
    if(ign_find_package_EXTRA_ARGS)
      ign_string_append(${PACKAGE_NAME}_dependency_args "${ign_find_package_EXTRA_ARGS}")
    endif()

    # TODO: When we migrate to cmake-3.9+ bring back find_dependency(~) because
    #       at that point it will be able to support COMPONENTS and EXTRA_ARGS
#    set(${PACKAGE_NAME}_find_dependency "find_dependency(${${PACKAGE_NAME}_dependency_args})")

    set(${PACKAGE_NAME}_find_dependency "find_package(${${PACKAGE_NAME}_dependency_args})")


    if(ign_find_package_REQUIRED)
      # If this is REQUIRED, add it to PROJECT_CMAKE_DEPENDENCIES
      ign_string_append(PROJECT_CMAKE_DEPENDENCIES ${${PACKAGE_NAME}_find_dependency} DELIM "\n")
    endif()

    if(ign_find_package_REQUIRED_BY)
      # If this is required by some components, add it to the
      # ${component}_CMAKE_DEPENDENCIES variables that are specific to those
      # componenets
      foreach(component ${ign_find_package_REQUIRED_BY})
        ign_string_append(${component}_CMAKE_DEPENDENCIES ${${PACKAGE_NAME}_find_dependency} DELIM "\n")
      endforeach()
    endif()

    #------------------------------------
    # Add this library or project to its relevant pkgconfig entry, unless we
    # have been explicitly instructed to ignore it.
    if(NOT ign_find_package_PKGCONFIG_IGNORE)

      # Here we will set up the pkgconfig entry for this package. Ordinarily,
      # these variables should be set by ign_pkg_check_modules[_quiet]. However,
      # that might not be available for third-party dependencies that provide
      # their own find-module or cmake config-module. Therefore, we provide the
      # option of specifying pkgconfig information through the call to
      # ign_find_package.

      # If the caller has specified the arguments PKGCONFIG_LIB or PKGCONFIG,
      # then we will overwrite these pkgconfig variables with the information
      # provided by the caller.
      if(ign_find_package_PKGCONFIG_LIB)
        # Libraries must be prepended with -l
        set(${PACKAGE_NAME}_PKGCONFIG_ENTRY "-l${ign_find_package_PKGCONFIG_LIB}")
        set(${PACKAGE_NAME}_PKGCONFIG_TYPE PKGCONFIG_LIBS)
      elseif(ign_find_package_PKGCONFIG OR NOT ${PACKAGE_NAME}_PKGCONFIG_ENTRY)

        # If (1) the caller has specified a PKGCONFIG argument, or if (2) the
        # call to find_package(~) did not produce a ${PACKAGE_NAME}_PKGCONFIG_ENTRY
        # (probably because its find-module was not generated by ign-cmake), we
        # will end up here.

        if(ign_find_package_PKGCONFIG)
          # The called explicitly provided a PKGCONFIG argument, so we will use
          # it.
          set(pkgconfig_name ${ign_find_package_PKGCONFIG})
        else()
          # The caller did not provide a PKGCONFIG argument and the package did
          # not provide one itself, so we will assume the package name passed
          # in is suitable for pkg-config.
          set(pkgconfig_name ${PACKAGE_NAME})
        endif()

        # Modules (a.k.a. packages) can just be provided with the name
        set(${PACKAGE_NAME}_PKGCONFIG_ENTRY "${pkgconfig_name}")
        set(${PACKAGE_NAME}_PKGCONFIG_TYPE PKGCONFIG_REQUIRES)

        # Add the version requirements to the entry.
        if(ign_find_package_VERSION)
          # Use equivalency by default
          set(comparison "=")

          # If the caller has specified a version comparison operator, use that
          # instead of equivalency.
          if(ign_find_package_PKGCONFIG_VER_COMPARISON)
            set(comparison ${ign_find_package_PKGCONFIG_VER_COMPARISON})
          endif()

          # Append the comparison and the version onto the pkgconfig entry
          set(${PACKAGE_NAME}_PKGCONFIG_ENTRY "${${PACKAGE_NAME}_PKGCONFIG_ENTRY} ${comparison} ${ign_find_package_VERSION}")

        endif()

      endif()

      if(ign_find_package_REQUIRED)

        if(ign_find_package_PRIVATE)
          # If this is a private library or module, use the _PRIVATE suffix
          set(PROJECT_${PACKAGE_NAME}_PKGCONFIG_TYPE ${${PACKAGE_NAME}_PKGCONFIG_TYPE}_PRIVATE)
        else()
          # Otherwise, use the plain type
          set(PROJECT_${PACKAGE_NAME}_PKGCONFIG_TYPE ${${PACKAGE_NAME}_PKGCONFIG_TYPE})
        endif()

        # Append the entry as a string onto the project-wide variable for
        # whichever requirement type we selected
        ign_string_append(${PROJECT_${PACKAGE_NAME}_PKGCONFIG_TYPE} ${${PACKAGE_NAME}_PKGCONFIG_ENTRY})

      endif()

      if(ign_find_package_REQUIRED_BY)

        # Identify which components are privately requiring this package
        foreach(component ${ign_find_package_PRIVATE_FOR})
          set(${component}_${PACKAGE_NAME}_PRIVATE true)
        endforeach()

        # For each of the components that requires this package, append its
        # entry as a string onto the component-specific variable for whichever
        # requirement type we selected
        foreach(component ${ign_find_package_REQUIRED_BY})

          if(${component}_${PACKAGE_NAME}_PRIVATE)
            # If this is a private library or module, use the _PRIVATE suffix
            set(${component}_${PACKAGE_NAME}_PKGCONFIG_TYPE ${${PACKAGE_NAME}_PKGCONFIG_TYPE}_PRIVATE)
          else()
            # Otherwise, use the plain type
            set(${component}_${PACKAGE_NAME}_PKGCONFIG_TYPE ${${PACKAGE_NAME}_PKGCONFIG_TYPE})
          endif()

          # Append the entry as a string onto the component-specific variable
          # for whichever required type we selected
          ign_string_append(${${component}_${PACKAGE_NAME}_PKGCONFIG_TYPE} ${${PACKAGE_NAME}_PKGCONFIG_ENTRY})

        endforeach()

      endif()

    endif()

  endif()

endmacro()

#################################################
# Macro to turn a list into a string (why doesn't CMake have this built-in?)
macro(ign_list_to_string _string _list)
    set(${_string})
    foreach(_item ${_list})
      set(${_string} "${${_string}} ${_item}")
    endforeach(_item)
    #string(STRIP ${${_string}} ${_string})
endmacro()

#################################################
# ign_string_append(<output_var> <value_to_append> [DELIM <delimiter>])
#
# <output_var>: The name of the string variable that should be appended to
#
# <value_to_append>: The value that should be appended to the string
#
# [DELIM]: Specify a delimiter to separate the contents with. Default value is a
#          space
#
# Macro to append a value to a string
macro(ign_string_append output_var val)

  #------------------------------------
  # Define the expected arguments
  # NOTE: options cannot be set to PARENT_SCOPE alone, so we put it explicitly
  # into cmake_parse_arguments(~). We use a semicolon to concatenate it with
  # this options variable, so all other options should be specified here.
  set(options)
  set(oneValueArgs DELIM)
  set(multiValueArgs) # We are not using multiValueArgs yet

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_string_append "PARENT_SCOPE;${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(ign_string_append_DELIM)
    set(delim "${ign_string_append_DELIM}")
  else()
    set(delim " ")
  endif()

  if(ign_string_append_PARENT_SCOPE)
    set(${output_var} "${${output_var}}${delim}${val}" PARENT_SCOPE)
  else()
    set(${output_var} "${${output_var}}${delim}${val}")
  endif()

endmacro()

#################################################
# ign_get_sources_and_unittests(<lib_srcs> <tests>)
#
# From the current directory, grab all the files ending in "*.cc" and sort them
# into library source files <lib_srcs> and unittest source files <tests>. Remove
# their paths to make them suitable for passing into ign_add_[library/tests].
function(ign_get_libsources_and_unittests lib_sources_var tests_var)

  # GLOB all the source files
  file(GLOB source_files "*.cc")
  list(SORT source_files)

  # GLOB all the unit tests
  file(GLOB test_files "*_TEST.cc")
  list(SORT test_files)

  # Initialize these lists
  set(tests)
  set(sources)

  # Remove the unit tests from the list of source files
  foreach(test_file ${test_files})

    list(REMOVE_ITEM source_files ${test_file})

    # Remove the path from the unit test and append to the list of tests.
    get_filename_component(test ${test_file} NAME)
    list(APPEND tests ${test})

  endforeach()

  foreach(source_file ${source_files})

    # Remove the path from the library source file and append it to the list of
    # library source files.
    get_filename_component(source ${source_file} NAME)
    list(APPEND sources ${source})

  endforeach()

  # Return the lists that have been created.
  set(${lib_sources_var} ${sources} PARENT_SCOPE)
  set(${tests_var} ${tests} PARENT_SCOPE)

endfunction()

#################################################
# ign_get_sources(<sources>)
#
# From the current directory, grab all the source files and place them into
# <sources>. Remove their paths to make them suitable for passing into
# ign_add_[library/tests].
function(ign_get_sources sources_var)

  # GLOB all the source files
  file(GLOB source_files "*.cc")
  list(SORT source_files)

  # Initialize this list
  set(sources)

  foreach(source_file ${source_files})

    # Remove the path from the source file and append it the list of soures
    get_filename_component(source ${source_file} NAME)
    list(APPEND sources ${source})

  endforeach()

  # Return the list that has been created
  set(${sources_var} ${sources} PARENT_SCOPE)

endfunction()

#################################################
# ign_install_all_headers(
#   [EXCLUDE_FILES <excluded_headers>]
#   [EXCLUDE_DIRS  <dirs>])
#
# From the current directory, install all header files, including files from all
# subdirectories (recursively). You can optionally specify directories or files
# to include (the names must be provided relative to the current source directory).
#
# This will accept all files ending in *.h and *.hh. You may append an
# additional suffix (like .old or .backup) to prevent a file from being included.
#
# This will also run configure_file on ign_auto_headers.hh.in and config.hh.in
# and install them. This will NOT install any other files or directories that
# appear in the ${CMAKE_CURRENT_BINARY_DIR}.
#
function(ign_install_all_headers)

  #------------------------------------
  # Define the expected arguments
  set(options) # We are not using options yet
  set(oneValueArgs) # We are not using oneValueArgs yet
  set(multiValueArgs EXCLUDE_FILES EXCLUDE_DIRS)

  message(STATUS "multiValueArgs:${multiValueArgs}")

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_install_all_headers "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})


  #------------------------------------
  # Build the list of directories
  file(GLOB_RECURSE all_files LIST_DIRECTORIES TRUE RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*")
  list(SORT all_files)

  set(directories)
  foreach(f ${all_files})
    # Check if this file is a directory
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${f})

      # Check if it is in the list of excluded directories
      list(FIND ign_install_all_headers_EXCLUDE_DIRS ${f} f_index)

      set(append_file TRUE)
      foreach(subdir ${ign_install_all_headers_EXCLUDE_DIRS})

        # Check if ${f} contains ${subdir} as a substring
        string(FIND ${f} ${subdir} pos)

        # If ${subdir} is a substring of ${f} at the very first position, then
        # we should not include anything from this directory. This makes sure
        # that if a user specifies "EXCLUDE_DIRS foo" we will also exclude
        # the directories "foo/bar/..." and so on. We will not, however, exclude
        # a directory named "bar/foo/".
        if(${pos} EQUAL 0)
          set(append_file FALSE)
          break()
        endif()

      endforeach()

      if(append_file)
        list(APPEND directories ${f})
      endif()

    endif()
  endforeach()

  # Append the current directory to the list
  list(APPEND directories ".")

  #------------------------------------
  # Install all the non-excluded header directories along with all of their
  # non-excluded headers
  foreach(dir ${directories})

    # GLOB all the header files in dir
    file(GLOB headers RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "${dir}/*.h" "${dir}/*.hh")
    list(SORT headers)

    # Remove the excluded headers
    if(headers)
      foreach(exclude ${excluded})
        list(REMOVE_ITEM headers ${exclude})
      endforeach()
    endif()

    # Add each header, prefixed by its directory, to the auto headers variable
    foreach(header ${headers})
      set(ign_headers "${ign_headers}#include <ignition/${IGN_DESIGNATION}/${header}>\n")
    endforeach()

    if("." STREQUAL ${dir})
      set(destination "${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESIGNATION}")
    else()
      set(destination "${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESIGNATION}/${dir}")
    endif()

    install(
      FILES ${headers}
      DESTINATION ${destination}
      COMPONENT headers)

  endforeach()

  # Define the install directory for the meta headers
  set(meta_header_install_dir ${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESIGNATION})

  # Define the input/output of the configuration for the "master" header
  set(master_header_in ${IGNITION_CMAKE_DIR}/ign_auto_headers.hh.in)
  set(master_header_out ${CMAKE_CURRENT_BINARY_DIR}/../${IGN_DESIGNATION}.hh)

  # Generate the "master" header that includes all of the headers
  configure_file(${master_header_in} ${master_header_out})

  # Install the "master" header
  install(
    FILES ${master_header_out}
    DESTINATION ${meta_header_install_dir}/..
    COMPONENT headers)

  # Define the input/output of the configuration for the "config" header
  set(config_header_in ${CMAKE_CURRENT_SOURCE_DIR}/config.hh.in)
  set(config_header_out ${CMAKE_CURRENT_BINARY_DIR}/config.hh)

  if(NOT EXISTS ${config_header_in})
    message(FATAL_ERROR
      "Developer error: You are missing the file [${config_header_in}]! "
      "Did you forget to move it from your project's cmake directory while "
      "migrating to the use of ignition-cmake?")
  endif()

  # Generate the "config" header that describes our project configuration
  configure_file(${config_header_in} ${config_header_out})

  # Install the "config" header
  install(
    FILES ${config_header_out}
    DESTINATION ${meta_header_install_dir}
    COMPONENT headers)

endfunction()


#################################################
# ign_build_error macro
macro(ign_build_error)
  foreach(str ${ARGN})
    set(msg "\t${str}")
    list(APPEND build_errors ${msg})
  endforeach()
endmacro(ign_build_error)

#################################################
# ign_build_warning macro
macro(ign_build_warning)
  foreach(str ${ARGN})
    set(msg "\t${str}" )
    list(APPEND build_warnings ${msg})
  endforeach(str ${ARGN})
endmacro(ign_build_warning)

#################################################
macro(ign_add_library)

  message(FATAL_ERROR "ign_add_library is deprecated. Instead, use "
                      "ign_create_main_library(SOURCES <sources>). The library "
                      "name is determined automatically by the project name. "
                      "To add a component library, use ign_add_component(~). "
                      "Be sure to pass the CXX_STANDARD argument to these "
                      "functions in order to set the C++ standard that they "
                      "require.")

endmacro()

#################################################
# _ign_check_known_cxx_standards(<11|14|...>)
#
# Creates a fatal error if the variable passed in does not represent a supported
# version of the C++ standard.
#
# NOTE: This function is meant for internal ign-cmake use
#
function(_ign_check_known_cxx_standards standard)

  list(FIND IGN_KNOWN_CXX_STANDARDS ${standard} known)
  if(${known} EQUAL -1)
    message(FATAL_ERROR "You have specified unsupported standard: ${standard}. "
                        "Accepted values are: ${IGN_KNOWN_CXX_STANDARDS}.")
  endif()

endfunction()

#################################################
# _ign_handle_cxx_standard(<function_prefix>
#                          <target_name>
#                          <pkgconfig_cflags_variable>)
#
# Handles the C++ standard argument for ign_create_main_library(~) and
# ign_add_component(~).
#
# NOTE: This is only meant for internal ign-cmake use.
#
macro(_ign_handle_cxx_standard prefix target pkgconfig_cflags)

  if(${prefix}_CXX_STANDARD)
    _ign_check_known_cxx_standards(${${prefix}_CXX_STANDARD})
  endif()

  if(${prefix}_PRIVATE_CXX_STANDARD)
    _ign_check_known_cxx_standards(${${prefix}_PRIVATE_CXX_STANDARD})
  endif()

  if(${prefix}_INTERFACE_CXX_STANDARD)
    _ign_check_known_cxx_standards(${${prefix}_INTERFACE_CXX_STANDARD})
  endif()

  if(${prefix}_CXX_STANDARD
      AND (${prefix}_PRIVATE_CXX_STANDARD
           OR ${prefix}_INTERFACE_CXX_STANDARD))
    message(FATAL_ERROR
      "If CXX_STANDARD has been specified, then you are not allowed to specify "
      "PRIVATE_CXX_STANDARD or INTERFACE_CXX_STANDARD. Please choose to either "
      "specify CXX_STANDARD alone, or else specify some combination of "
      "PRIVATE_CXX_STANDARD and INTERFACE_CXX_STANDARD")
  endif()

  if(${prefix}_CXX_STANDARD)
    set(${prefix}_INTERFACE_CXX_STANDARD ${${prefix}_CXX_STANDARD})
    set(${prefix}_PRIVATE_CXX_STANDARD ${${prefix}_CXX_STANDARD})
  endif()

  if(${prefix}_INTERFACE_CXX_STANDARD)
    target_compile_features(${target} INTERFACE ${IGN_CXX_${${prefix}_INTERFACE_CXX_STANDARD}_FEATURES})
    ign_string_append(${pkgconfig_cflags} "-std=c++${${prefix}_INTERFACE_CXX_STANDARD}")
  endif()

  if(${prefix}_PRIVATE_CXX_STANDARD)
    target_compile_features(${target} PRIVATE ${IGN_CXX_${${prefix}_PRIVATE_CXX_STANDARD}_FEATURES})
  endif()

endmacro()

#################################################
# ign_create_main_library(SOURCES <sources>
#                         [CXX_STANDARD <11|14|...>]
#                         [PRIVATE_CXX_STANDARD <11|14|...>]
#                         [INTERFACE_CXX_STANDARD <11|14|...>]
#                         [GET_TARGET_NAME <output_var>])
#
# This function will produce the "main" library for your project. There is no
# need to specify a name for the library, because that will be determined by
# your project information.
#
# SOURCES: Required. Specify the source files that will be used to generate the
#          library.
#
# [GET_TARGET_NAME]: Optional. The variable that follows this argument will be
#                    set to the library target name that gets produced by this
#                    function. The target name will always be
#                    ${PROJECT_LIBRARY_TARGET_NAME}.
#
# If you need a specific C++ standard, you must also specify it in this
# function in order to ensure that your library's target properties get set
# correctly. The following is a breakdown of your choices:
#
# [CXX_STANDARD]: This library must compile using the specified standard, and so
#                 must any libraries which link to it.
#
# [PRIVATE_CXX_STANDARD]: This library must compile using the specified standard,
#                         but libraries which link to it do not need to.
#
# [INTERFACE_CXX_STANDARD]: Any libraries which link to this library must compile
#                           with the specified standard.
#
# Most often, you will want to use CXX_STANDARD, but there may be cases in which
# you want a finer degree of control. If your library must compile with a
# different standard than what is required by dependent libraries, then you can
# specify both PRIVATE_CXX_STANDARD and INTERFACE_CXX_STANDARD without any
# conflict. However, both of those arguments conflict with CXX_STANDARD, so you
# are not allowed to use either of them if you use the CXX_STANDARD argument.
#
function(ign_create_main_library)

  #------------------------------------
  # Define the expected arguments
  set(options) # Not using options yet
  set(oneValueArgs INCLUDE_SUBDIR CXX_STANDARD PRIVATE_CXX_STANDARD INTERFACE_CXX_STANDARD GET_TARGET_NAME)
  set(multiValueArgs SOURCES)

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_create_main_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(ign_create_main_library_SOURCES)
    set(sources ${ign_create_main_library_SOURCES})
  else()
    message(FATAL_ERROR "You must specify SOURCES for ign_create_main_library(~)!")
  endif()

  #------------------------------------
  # Create the target for the main library, and configure it to be installed
  _ign_add_library_or_component(
    LIB_NAME ${PROJECT_LIBRARY_TARGET_NAME}
    INCLUDE_DIR "ignition/${IGN_DESIGNATION_LOWER}"
    EXPORT_BASE IGNITION_${IGN_DESIGNATION_UPPER}
    SOURCES ${sources})

  # This generator expression is necessary for multi-configuration generators,
  # such as MSVC on Windows, and also to ensure that our target exports the
  # headers correctly
  target_include_directories(${PROJECT_LIBRARY_TARGET_NAME}
    PUBLIC
      # This is the publicly installed ignition/math headers directory.
      $<INSTALL_INTERFACE:${IGN_INCLUDE_INSTALL_DIR_FULL}>
      # This is the build directory version of the headers. When exporting the
      # target, this will not be included, because it is tied to the build
      # interface instead of the install interface.
      $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>)


  #------------------------------------
  # Adjust variables if a specific C++ standard was requested
  _ign_handle_cxx_standard(ign_create_main_library
    ${PROJECT_LIBRARY_TARGET_NAME} PROJECT_PKGCONFIG_CFLAGS)


  #------------------------------------
  # Handle cmake and pkgconfig packaging

  # Export and install the main library's cmake target and package information
  _ign_create_cmake_package()

  # Generate and install the main library's pkgconfig information
  _ign_create_pkgconfig()


  #------------------------------------
  # Pass back the target name if they ask for it.
  if(ign_create_main_library_GET_TARGET_NAME)
    set(${ign_create_main_library_GET_TARGET_NAME} ${PROJECT_LIBRARY_TARGET_NAME} PARENT_SCOPE)
  endif()

endfunction()

#################################################
# ign_add_component(<component>
#                   SOURCES <sources>
#                   [INCLUDE_SUBDIR <subdirectory_name>]
#                   [GET_TARGET_NAME <output_var>]
#                   [INDEPENDENT_FROM_PROJECT_LIB]
#                   [PRIVATELY_DEPENDS_ON_PROJECT_LIB]
#                   [INTERFACE_DEPENDS_ON_PROJECT_LIB]
#                   [CXX_STANDARD <11|14|...>]
#                   [PRIVATE_CXX_STANDARD <11|14|...>]
#                   [INTERFACE_CXX_STANDARD <11|14|...>])
#
# This function will produce a "component" library for your project. This is the
# recommended way to produce plugins or library modules.
#
# <component>: Required. Name of the component. The final name of this library
#              and its target will be ignition-<project><major_ver>-<component>
#
# SOURCES: Required. Specify the source files that will be used to generate the
#          library.
#
# [INCLUDE_SUBDIR]: Optional. If specified, the public include headers for this
#                   component will go into "ignition/<project>/<subdirectory_name>/".
#                   If not specified, they will go into "ignition/<project>/<component>/"
#
# [GET_TARGET_NAME]: Optional. The variable that follows this argument will be
#                    set to the library target name that gets produced by this
#                    function. The target name will always be
#                    ${PROJECT_LIBRARY_TARGET_NAME}-<component>.
#
# [INDEPENDENT_FROM_PROJECT_LIB]:
#     Optional. Specify this if you do NOT want this component to automatically
#     be linked to the main library of this project. The default behavior is to
#     be publically linked.
#
# [PRIVATELY_DEPENDS_ON_PROJECT_LIB]:
#     Optional. Specify this if this component privately depends on the main
#     library of this project (i.e. users of this component do not need to
#     interface with the main library). The default behavior is to be publicly
#     linked.
#
# [INTERFACE_DEPENDS_ON_PROJECT_LIB]:
#     Optional. Specify this if the component's interface depends on the main
#     library of this project (i.e. users of this component need to interface
#     with the main library), but the component itself does not need to link to
#     the main library.
#
# See the documentation of ign_create_main_library(~) for more information about
# specifying the C++ standard. If your component publicly depends on the main
# library, then you probably do not need to specify the standard, because it
# will get inherited from the main library.
function(ign_add_component component_name)

  #------------------------------------
  # Define the expected arguments
  set(options INDEPENDENT_FROM_PROJECT_LIB PRIVATELY_DEPENDS_ON_PROJECT_LIB INTERFACE_DEPENDS_ON_PROJECT_LIB)
  set(oneValueArgs INCLUDE_SUBDIR GET_TARGET_NAME)
  set(multiValueArgs SOURCES)

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_add_component "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(ign_add_component_SOURCES)
    set(sources ${ign_add_component_SOURCES})
  else()
    message(FATAL_ERROR "You must specify SOURCES for ign_add_component(~)!")
  endif()

  if(ign_add_component_INCLUDE_SUBDIR)
    set(include_subdir ${ign_add_component_INCLUDE_SUBDIR})
  else()
    set(include_subdir ${component_name})
  endif()

  # Set the name of the component's target
  set(component_target_name ${PROJECT_LIBRARY_TARGET_NAME}-${component_name})

  # Pass the component's target name back to the caller if requested
  if(ign_add_component_GET_TARGET_NAME)
    set(${ign_add_component_GET_TARGET_NAME} ${component_target_name} PARENT_SCOPE)
  endif()

  # Create an upper case version of the component name, to be used as an export
  # base name.
  string(TOUPPER ${component_name} component_name_upper)

  #------------------------------------
  # Create the target for this component, and configure it to be installed
  _ign_add_library_or_component(
    LIB_NAME ${component_target_name}
    INCLUDE_DIR "ignition/${IGN_DESIGNATION_LOWER}/${include_subdir}"
    EXPORT_BASE IGNITION_${IGN_DESIGNATION_UPPER}_${component_name_upper}
    SOURCES ${sources})

  if(ign_add_component_INDEPENDENT_FROM_PROJECT_LIB  OR
     ign_add_component_PRIVATELY_DEPENDS_ON_PROJECT_LIB)

    # If we are not linking this component to the main library, then we need to
    # add these include directories to this component library directly. This is
    # not needed if we link to the main library, because that will pull in these
    # include directories automatically.
    target_include_directories(${PROJECT_LIBRARY_TARGET_NAME}
      PUBLIC
        # This is the publicly installed ignition/math headers directory.
        $<INSTALL_INTERFACE:${IGN_INCLUDE_INSTALL_DIR_FULL}>
        # This is the build directory version of the headers. When exporting the
        # target, this will not be included, because it is tied to the build
        # interface instead of the install interface.
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>)

  endif()


  #------------------------------------
  # Adjust variables if a specific C++ standard was requested
  _ign_handle_cxx_standard(ign_add_component
    ${component_target_name} ${component_name}_PKGCONFIG_CFLAGS)


  #------------------------------------
  # Adjust the packaging variables based on how this component depends (or not)
  # on the main library.
  if(ign_add_component_PRIVATELY_DEPENDS_ON_PROJECT_LIB)

    target_link_libraries(${component_target_name}
      PRIVATE ${PROJECT_LIBRARY_TARGET_NAME})

  endif()

  if(ign_add_component_INTERFACE_DEPENDS_ON_PROJECT_LIB)

    target_link_libraries(${component_target_name}
      INTERFACE ${PROJECT_LIBRARY_TARGET_NAME})

  endif()

  if(NOT ign_add_component_INDEPENDENT_FROM_PROJECT_LIB AND
     NOT ign_add_component_PRIVATELY_DEPENDS_ON_PROJECT_LIB AND
     NOT ign_add_component_INTERFACE_DEPENDS_ON_PROJECT_LIB)

    target_link_libraries(${component_target_name}
      PUBLIC ${PROJECT_LIBRARY_TARGET_NAME})

  endif()

  if(NOT ign_add_component_INDEPENDENT_FROM_PROJECT_LIB)

    # Add the main library as a cmake dependency for this component
    # NOTE: It seems we need to triple-escape "${ign_package_required}" and
    #       "${ign_package_quiet}" here.
    ign_string_append(${component_name}_CMAKE_DEPENDENCIES
      "find_package(${PKG_NAME} ${PROJECT_VERSION_FULL} EXACT \\\${ign_package_quiet} \\\${ign_package_required})" DELIM "\n")

    # Choose what type of pkgconfig entry the main library belongs to
    set(lib_pkgconfig_type ${component_name}_PKGCONFIG_REQUIRES)
    if(ign_add_component_PRIVATELY_DEPENDS_ON_PROJECT_LIB
        AND NOT ign_add_component_INTERFACE_DEPENDS_ON_PROJECT_LIB)
      set(lib_pkgconfig_type ${lib_pkgconfig_type}_PRIVATE)
    endif()

    ign_string_append(${lib_pkgconfig_type} "${PKG_NAME}=${PROJECT_VERSION_FULL}")

  endif()

  #------------------------------------
  # Set variables that are needed by cmake/ignition-component-config.cmake.in
  set(component_pkg_name ${component_target_name})
  set(component_cmake_dependencies ${${component_name}_CMAKE_DEPENDENCIES})
  # This next set is redundant, but it serves as a reminder that this input
  # variable is used in config files
  set(component_name ${component_name})

  # ... and by cmake/pkgconfig/ignition-component.pc.in
  set(component_pkgconfig_requires ${${component_name}_PKGCONFIG_REQUIRES})
  set(component_pkgconfig_requires_private ${${component_name}_PKGCONFIG_REQUIRES_PRIVATE})
  set(component_pkgconfig_libs ${${component_name}_PKGCONFIG_LIBS})
  set(component_pkgconfig_libs_private ${${component_name}_PKGCONFIG_LIBS_PRIVATE})
  set(component_pkgconfig_cflags ${${component_name}_PKGCONFIG_CFLAGS})

  # Export and install the cmake target and package information
  _ign_create_cmake_package(COMPONENT ${component_name})

  # Generate and install the pkgconfig information for this component
  _ign_create_pkgconfig(COMPONENT ${component_name})

endfunction()

#################################################
# Used internally by _ign_add_library_or_component to report argument errors
macro(_ign_add_library_or_component_arg_error missing_arg)

  message(FATAL_ERROR "ignition-cmake developer error: Must specify "
                      "${missing_arg} to _ign_add_library_or_component!")

endmacro()

#################################################
# This is only meant for internal use by ignition-cmake. If you are a consumer
# of ignition-cmake, please use ign_create_main_library(~) or
# ign_add_component(~) instead of this.
#
# _ign_add_library_or_component(LIB_NAME <lib_name>
#                               INCLUDE_DIR <dir_name>
#                               EXPORT_BASE <export_base>
#                               SOURCES <sources>)
#
macro(_ign_add_library_or_component)

  # NOTE: The following local variables are used in the Export.hh.in file, so if
  # you change their names here, you must also change their names there:
  # - include_dir
  # - export_base
  # - lib_name

  #------------------------------------
  # Define the expected arguments
  set(options) # We are not using options yet
  set(oneValueArgs LIB_NAME INCLUDE_DIR EXPORT_BASE)
  set(multiValueArgs SOURCES)

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(_ign_add_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(_ign_add_library_LIB_NAME)
    set(lib_name ${_ign_add_library_LIB_NAME})
  else()
    _ign_add_library_or_component_arg_error(LIB_NAME)
  endif()

  if(_ign_add_library_SOURCES)
    set(sources ${_ign_add_library_SOURCES})
  else()
    _ign_add_library_or_component_arg_error(SOURCES)
  endif()

  if(_ign_add_library_INCLUDE_DIR)
    set(include_dir ${_ign_add_library_INCLUDE_DIR})
  else()
    _ign_add_library_or_component_arg_error(INCLUDE_DIR)
  endif()

  if(_ign_add_library_EXPORT_BASE)
    set(export_base ${_ign_add_library_EXPORT_BASE})
  else()
    _ign_add_library_or_component_arg_error(EXPORT_BASE)
  endif()

  #------------------------------------
  # Create the library target
  add_library(${lib_name} ${sources})

  #------------------------------------
  # Add fPIC if we are supposed to
  if(IGN_ADD_fPIC_TO_LIBRARIES)
    target_compile_options(${lib_name} PRIVATE -fPIC)
  endif()

  #------------------------------------
  # Generate export macro headers
  set(binary_include_dir
    "${CMAKE_BINARY_DIR}/include/${include_dir}")

  set(implementation_file_name "${binary_include_dir}/detail/Export.hh")

  include(GenerateExportHeader)
  # This macro will generate a header called detail/Export.hh which implements
  # some C-macros that are useful for exporting our libraries. The
  # implementation header does not provide any commentary or explanation for its
  # macros, so we tuck it away in the detail/ subdirectory, and then provide a
  # public-facing header that provides commentary for the macros.
  generate_export_header(${lib_name}
    BASE_NAME ${export_base}
    EXPORT_FILE_NAME ${implementation_file_name}
    EXPORT_MACRO_NAME DETAIL_${export_base}_VISIBLE
    NO_EXPORT_MACRO_NAME DETAIL_${export_base}_HIDDEN
    DEPRECATED_MACRO_NAME IGN_DEPRECATED_ALL_VERSIONS)

  set(install_include_dir
    "${IGN_INCLUDE_INSTALL_DIR_FULL}/${include_dir}")

  # Configure the installation of the automatically generated file.
  install(
    FILES "${implementation_file_name}"
    DESTINATION "${install_include_dir}/detail"
    COMPONENT headers)

  # Configure the public-facing header for exporting and deprecating. This
  # header provides commentary for the macros so that developers can know their
  # purpose.
  configure_file(
    "${IGNITION_CMAKE_DIR}/Export.hh.in"
    "${binary_include_dir}/Export.hh")

  # Configure the installation of the public-facing header.
  install(
    FILES "${binary_include_dir}/Export.hh"
    DESTINATION "${install_include_dir}"
    COMPONENT headers)


  #------------------------------------
  # Configure the installation of the target
  set_target_properties(
    ${lib_name}
    PROPERTIES
      SOVERSION ${PROJECT_VERSION_MAJOR}
      VERSION ${PROJECT_VERSION_FULL})

  install(
    TARGETS ${lib_name}
    EXPORT ${lib_name}
    LIBRARY DESTINATION ${IGN_LIB_INSTALL_DIR}
    ARCHIVE DESTINATION ${IGN_LIB_INSTALL_DIR}
    RUNTIME DESTINATION ${IGN_LIB_INSTALL_DIR}
    COMPONENT libraries)

endmacro()

#################################################
macro(ign_add_executable _name)
  add_executable(${_name} ${ARGN})
  target_link_libraries(${_name} ${general_libraries})
endmacro()

#################################################
# ign_target_interface_include_directories(<target> [include_targets])
#
# Add the INTERFACE_INCLUDE_DIRECTORIES of [include_targets] to the public
# INCLUDE_DIRECTORIES of <target>. This allows us to propagate the include
# directories of <target> along to any other libraries that depend on it.
#
# You MUST pass in targets to include, not directory names. We must not use
# explicit directory names here if we want our package to be relocatable.
function(ign_target_interface_include_directories name)

  foreach(include_target ${ARGN})
    target_include_directories(
      ${name} PUBLIC
      $<TARGET_PROPERTY:${include_target},INTERFACE_INCLUDE_DIRECTORIES>)
  endforeach()

endfunction()

#################################################
macro(ign_install_includes _subdir)
  install(FILES ${ARGN}
    DESTINATION ${IGN_INCLUDE_INSTALL_DIR}/${_subdir} COMPONENT headers)
endmacro()

#################################################
macro(ign_install_library)

  message(FATAL_ERROR "ign_install_library is deprecated. Please remove it "
                      "from your cmake script!")

endmacro()

#################################################
macro(ign_install_executable _name )
  set_target_properties(${_name} PROPERTIES VERSION ${PROJECT_VERSION_FULL})
  install (TARGETS ${_name} DESTINATION ${IGN_BIN_INSTALL_DIR})
  manpage(${_name} 1)
endmacro()

#################################################
# Macro to setup supported compiler warnings
# Based on work of Florent Lamiraux, Thomas Moulard, JRL, CNRS/AIST.
macro(ign_filter_valid_compiler_options var)

  include(CheckCXXCompilerFlag)
  # Store the current setting for CMAKE_REQUIRED_QUIET
  set(original_cmake_required_quiet ${CMAKE_REQUIRED_QUIET})

  # Make these tests quiet so they don't pollute the cmake output
  set(CMAKE_REQUIRED_QUIET true)

  foreach(flag ${ARGN})
    CHECK_CXX_COMPILER_FLAG(${flag} result${flag})
    if(result${flag})
      set(${var} "${${var}} ${flag}")
    endif()
  endforeach()

  # Restore the old setting for CMAKE_REQUIRED_QUIET
  set(CMAKE_REQUIRED_QUIET ${original_cmake_required_quiet})
endmacro()

#################################################
# ign_build_executables(SOURCES <sources>
#                       [PREFIX <prefix>]
#                       [LIB_DEPS <library_dependencies>]
#                       [INCLUDE_DIRS <include_dependencies>]
#                       [EXEC_LIST <output_var>]
#                       [EXCLUDE_PROJECT_LIB])
#
# Build executables for an ignition project. Arguments are as follows:
#
# SOURCES: Required. The names (without a path) of the source files for your
#          executables.
#
# PREFIX: Optional. This will append <prefix> onto each executable name.
#
# LIB_DEPS: Optional. Additional library dependencies that every executable
#           should link to, not including the library build by this project (it
#           will be linked automatically, unless you pass in the
#           EXCLUDE_PROJECT_LIB option).
#
# INCLUDE_DIRS: Optional. Additional include directories that should be visible
#               to all of these executables.
#
# EXEC_LIST: Optional. Provide a variable which will be given the list of the
#            names of the executables generated by this macro. These will also
#            be the names of the targets.
#
# EXCLUDE_PROJECT_LIB: Pass this argument if you do not want your executables to
#                      link to your project's main library. On Windows, this
#                      will also skip the step of copying the runtime library
#                      into your executable's directory.
#
macro(ign_build_executables)

  #------------------------------------
  # Define the expected arguments
  set(options EXCLUDE_PROJECT_LIB)
  set(oneValueArgs PREFIX EXEC_LIST)
  set(multiValueArgs SOURCES LIB_DEPS INCLUDE_DIRS)

  if(ign_build_executables_EXEC_LIST)
    set(${ign_build_executables_EXEC_LIST} "")
  endif()


  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_build_executables "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  foreach(exec_file ${ign_build_executables_SOURCES})

    string(REGEX REPLACE ".cc" "" BINARY_NAME ${exec_file})
    set(BINARY_NAME ${ign_build_executables_PREFIX}${BINARY_NAME})

    add_executable(${BINARY_NAME} ${exec_file})

    if(ign_build_executables_EXEC_LIST)
      list(APPEND ${ign_build_executables_EXEC_LIST} ${BINARY_NAME})
    endif()

    if(NOT ign_build_executables_EXCLUDE_PROJECT_LIB)
      target_link_libraries(${BINARY_NAME} ${PROJECT_LIBRARY_TARGET_NAME})
    endif()

    if(ign_build_executables_LIB_DEPS)
      target_link_libraries(${BINARY_NAME} ${ign_build_executables_LIB_DEPS})
    endif()

    target_include_directories(${BINARY_NAME}
      PRIVATE
        ${PROJECT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/include
        ${PROJECT_BINARY_DIR}
        ${PROJECT_BINARY_DIR}/include
        ${ign_build_executables_INCLUDE_DIRS})

      if(WIN32 AND NOT ign_build_executables_EXCLUDE_PROJECT_LIB)

        # If we have not installed our project's library yet, then it will not
        # be visible to the executable when we attempt to run it. Therefore, we
        # place a copy of our project's library into the directory that contains
        # the executable. We do not need to do this for any of the test's other
        # dependencies, because the fact that they were found by the build
        # system means they are installed and should be visible when the test is
        # run.

        # Get the full file path to the original dll for this project
        set(dll_original "$<TARGET_FILE:${PROJECT_LIBRARY_TARGET_NAME}>")

        # Get the full file path for where we need to paste the dll for this project
        set(dll_target "$<TARGET_FILE_DIR:${BINARY_NAME}>/$<TARGET_FILE_NAME:${PROJECT_LIBRARY_TARGET_NAME}>")

        # Add the copy_if_different command as a custom command that is tied the target
        # of this test.
        add_custom_command(
          TARGET ${BINARY_NAME}
          COMMAND ${CMAKE_COMMAND}
          ARGS -E copy_if_different ${dll_original} ${dll_target}
          VERBATIM)

      endif()

  endforeach()

endmacro()

#################################################
# ign_build_tests(TYPE <test_type>
#                 SOURCES <sources>
#                 [LIB_DEPS <library_dependencies>]
#                 [INCLUDE_DIRS <include_dependencies>]
#                 [TEST_LIST <output_var>])
#
# Build tests for an ignition project. Arguments are as follows:
#
# TYPE: Required. Preferably UNIT, INTEGRATION, PERFORMANCE, or REGRESSION.
#
# SOURCES: Required. The names (without the path) of the source files for your
#          tests. Each file will turn into a test.
#
# LIB_DEPS: Optional. Additional library dependencies that every test should
#           link to, not including the library built by this project (it will be
#           linked automatically). gtest and gtest_main will also be linked.
#
# INCLUDE_DIRS: Optional. Additional include directories that should be visible
#               to all the tests of this type.
#
# TEST_LIST: Optional. Provide a variable which will be given the list of the
#            names of the tests generated by this macro. These will also be the
#            names of the targets.
#
macro(ign_build_tests)

  #------------------------------------
  # Define the expected arguments
  set(options)
  set(oneValueArgs TYPE)
  set(multiValueArgs SOURCES LIB_DEPS INCLUDE_DIRS)


  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_build_tests "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT ign_build_tests_TYPE)
    # If you have encountered this error, you are probably migrating to the
    # new ignition-cmake system. Be sure to also provide a SOURCES argument
    # when calling ign_build_tests.
    message(FATAL_ERROR "Developer error: You must specify a TYPE for your tests!")
  endif()

  set(TEST_TYPE ${ign_build_tests_TYPE})

  if(NOT DEFINED ign_build_tests_SOURCES)
    message(STATUS "No tests have been specified for ${TEST_TYPE}")
  endif()

  ign_build_executables(
    PREFIX "${TEST_TYPE}_"
    SOURCES ${ign_build_tests_SOURCES}
    LIB_DEPS gtest gtest_main ${ign_build_tests_LIB_DEPS}
    INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/test/gtest/include ${ign_build_tests_INCLUDE_DIRS}
    EXEC_LIST test_list)

  if(ign_build_tests_TEST_LIST)
    set(${ign_build_tests_TEST_LIST} ${test_list})
  endif()

  # Find the Python interpreter for running the
  # check_test_ran.py script
  find_package(PythonInterp QUIET)

  # Build all the tests
  foreach(BINARY_NAME ${test_list})

    if(USE_LOW_MEMORY_TESTS)
      target_compile_options(${BINARY_NAME} PRIVATE -DUSE_LOW_MEMORY_TESTS=1)
    endif()

    add_test(${BINARY_NAME} ${CMAKE_CURRENT_BINARY_DIR}/${BINARY_NAME}
             --gtest_output=xml:${CMAKE_BINARY_DIR}/test_results/${BINARY_NAME}.xml)

    if(UNIX)
      # gtest requies pthread when compiled on a Unix machine
      target_link_libraries(${BINARY_NAME} pthread)
    endif()

    set_tests_properties(${BINARY_NAME} PROPERTIES TIMEOUT 240)

    if(PYTHONINTERP_FOUND)
      # Check that the test produced a result and create a failure if it didn't.
      # Guards against crashed and timed out tests.
      add_test(check_${BINARY_NAME} ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/tools/check_test_ran.py
        ${CMAKE_BINARY_DIR}/test_results/${BINARY_NAME}.xml)
    endif()
  endforeach()

endmacro()

#################################################
# ign_set_target_public_cxx_standard(<11|14>)
#
# NOTE: This was a temporary workaround for the first pull request and is
#       removed as of the "Components" pull request.
#
macro(ign_set_project_public_cxx_standard standard)

  message(FATAL_ERROR
    "The ign_set_project_public_cxx_standard(~) macro is no longer allowed. "
    "Instead, use the CXX_STANDARD argument of ign_create_main_library(~).")

endmacro()
