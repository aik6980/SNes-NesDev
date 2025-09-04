cmake_minimum_required(VERSION 3.20)
project(hello ASM)

set(ROM_NAME "hello.nes")

set(SOURCES
    src/main.asm
    src/app.asm
)

# Build rules
# compile asm
add_custom_command(
    OUTPUT main.o
    COMMAND ${CMAKE_ASM_COMPILER} -g -v -o ${CMAKE_CURRENT_BINARY_DIR}/main.o ${CMAKE_CURRENT_SOURCE_DIR}/src/main.asm
    COMMAND ${CMAKE_ASM_COMPILER} -g -v -o ${CMAKE_CURRENT_BINARY_DIR}/app.o ${CMAKE_CURRENT_SOURCE_DIR}/src/app.asm
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src
    DEPENDS ${SOURCES}
    COMMENT "Assembling(1/2) NES ROM ..."
)

# link
add_custom_command(
    OUTPUT ${ROM_NAME}
    COMMAND ${CMAKE_ASM_LINKER} -o ${ROM_NAME} -g -v -t nes main.o app.o
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS main.o
    COMMENT "Assembling(2/2) NES ROM ..."
)

add_custom_target(build_rom ALL
    DEPENDS ${ROM_NAME}
)
