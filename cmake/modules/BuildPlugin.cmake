# BuildPlugin.cmake - Copyright (c) 2008 Tobias Doerffel
#
# description: build LMMS-plugin
# usage: BUILD_PLUGIN(<PLUGIN_NAME> <PLUGIN_SOURCES> MOCFILES <HEADERS_FOR_MOC> EMBEDDED_RESOURCES <LIST_OF_FILES_TO_EMBED> UICFILES <UI_FILES_TO_COMPILE> )

MACRO(CAR var)
  SET(${var} ${ARGV1})
ENDMACRO(CAR)

MACRO(CDR var junk)
  SET(${var} ${ARGN})
ENDMACRO(CDR)

MACRO(LIST_CONTAINS var value)
	SET(${var})
		FOREACH (value2 ${ARGN})
			IF (${value} STREQUAL ${value2})
				SET(${var} TRUE)
			ENDIF (${value} STREQUAL ${value2})
	ENDFOREACH (value2)
ENDMACRO(LIST_CONTAINS)

MACRO(PARSE_ARGUMENTS prefix arg_names option_names)
  SET(DEFAULT_ARGS)
  FOREACH(arg_name ${arg_names})
    SET(${prefix}_${arg_name})
  ENDFOREACH(arg_name)
  FOREACH(option ${option_names})
    SET(${prefix}_${option} FALSE)
  ENDFOREACH(option)

  SET(current_arg_name DEFAULT_ARGS)
  SET(current_arg_list)
  FOREACH(arg ${ARGN})
    LIST_CONTAINS(is_arg_name ${arg} ${arg_names})
    IF (is_arg_name)
      SET(${prefix}_${current_arg_name} ${current_arg_list})
      SET(current_arg_name ${arg})
      SET(current_arg_list)
    ELSE (is_arg_name)
      LIST_CONTAINS(is_option ${arg} ${option_names})
      IF (is_option)
	SET(${prefix}_${arg} TRUE)
      ELSE (is_option)
	SET(current_arg_list ${current_arg_list} ${arg})
      ENDIF (is_option)
    ENDIF (is_arg_name)
  ENDFOREACH(arg)
  SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO(PARSE_ARGUMENTS)

MACRO(BUILD_PLUGIN)
	PARSE_ARGUMENTS(PLUGIN "MOCFILES;EMBEDDED_RESOURCES;UICFILES" "" ${ARGN} )
	CAR(PLUGIN_NAME ${PLUGIN_DEFAULT_ARGS})
	CDR(PLUGIN_SOURCES ${PLUGIN_DEFAULT_ARGS})

	INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/src/gui)

	ADD_DEFINITIONS(-DPLUGIN_NAME=${PLUGIN_NAME})

	LIST(LENGTH PLUGIN_EMBEDDED_RESOURCES ER_LEN)
	IF(ER_LEN)
		SET(ER_H embedded_resources.h)

		ADD_CUSTOM_COMMAND(OUTPUT ${ER_H}
			COMMAND ${BIN2RES}
			ARGS ${PLUGIN_EMBEDDED_RESOURCES} > ${ER_H})
	ENDIF(ER_LEN)

	QT4_WRAP_CPP(plugin_MOC_out ${PLUGIN_MOCFILES})
	QT4_WRAP_UI(plugin_UIC_out ${PLUGIN_UICFILES})
	FOREACH(f ${PLUGIN_SOURCES})
		ADD_FILE_DEPENDENCIES(${f} ${ER_H} ${plugin_MOC_out} ${plugin_UIC_out})
	ENDFOREACH(f)
#	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -i-static")
	IF(LMMS_BUILD_WIN32)
	        LINK_DIRECTORIES(${CMAKE_BINARY_DIR})
        	LINK_LIBRARIES(-llmms ${QT_LIBRARIES})
	ENDIF(LMMS_BUILD_WIN32)
	ADD_LIBRARY(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})
	IF(LMMS_BUILD_LINUX)
		INSTALL(TARGETS ${PLUGIN_NAME} LIBRARY DESTINATION "${PLUGIN_DIR}")
	ENDIF(LMMS_BUILD_LINUX)
	IF(LMMS_BUILD_WIN32)
		SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")
	ENDIF(LMMS_BUILD_WIN32)
	SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${ER_H} ${plugin_MOC_out}")
ENDMACRO(BUILD_PLUGIN)

