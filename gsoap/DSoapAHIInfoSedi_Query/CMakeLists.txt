set(FILES
	${CMAKE_CURRENT_SOURCE_DIR}/DSoapAHIInfoSedi_Query.h
	${CMAKE_CURRENT_SOURCE_DIR}/DSoapAHIInfoSedi_Query.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/soapH.h
	${CMAKE_CURRENT_SOURCE_DIR}/soapC.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/soapStub.h
	${CMAKE_CURRENT_SOURCE_DIR}/soapzpcu_qinfosedi_fascia_delay_wsWSPortBindingProxy.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/soapzpcu_qinfosedi_fascia_delay_wsWSPortBindingProxy.h
	${CMAKE_CURRENT_SOURCE_DIR}/zpcu_qinfosedi_fascia_delay_wsWSPortBinding.nsmap
	${CMAKE_CURRENT_SOURCE_DIR}/stdsoap2.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/stdsoap2.h
)

#set(SRC_FILES ${SRC_FILES} ${FILES} PARENT_SCOPE)
#target_sources(${PROJECT_NAME} PRIVATE ${SRC_FILES})

target_sources(${PROJECT_NAME} PRIVATE ${FILES})
target_link_options(${PROJECT_NAME} PRIVATE -DWITH_NONAMESPACES)
