cmake_minimum_required(VERSION 3.20)
project(nesDemo ASM)

set(ROM_NAME "nesDemo")

set(SOURCES
    src/main.asm
)

set(OBJFILES "")
set(DEPENDFILES "")

# Compile asm
foreach(SRC ${SOURCES})
    get_filename_component(FILE_NAME ${SRC} NAME_WE) # name without extension
    
    set(OBJ ${CMAKE_CURRENT_BINARY_DIR}/${FILE_NAME}.o)
    list(APPEND OBJFILES ${OBJ})
    
    # using depfile to track dependencies
    set(DEP ${CMAKE_CURRENT_BINARY_DIR}/${FILE_NAME}.d)
    list(APPEND DEPENDFILES ${DEP})

    add_custom_command(
        OUTPUT ${OBJ}
        COMMAND ${CMAKE_ASM_COMPILER} -g -v --create-dep ${DEP} -o ${OBJ} ${CMAKE_CURRENT_SOURCE_DIR}/${SRC}
        DEPFILE ${DEP}
        DEPENDS ${SRC}
        COMMENT "Assembling ${SRC} -> ${OBJ}"
    )
endforeach()

# link
add_custom_command(
    OUTPUT ${ROM_NAME}
    COMMAND ${CMAKE_ASM_LINKER} -o ${ROM_NAME}.nes -v -t nes ${OBJFILES} --dbgfile ${ROM_NAME}.dbg -Ln ${ROM_NAME}.label.txt
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${OBJFILES}
    COMMENT "Assembling(2/2) NES ROM ..."
)

add_custom_target(build_rom ALL
    DEPENDS ${ROM_NAME}
)
