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

# Post build
# Copy artifacts to bin/   
set(ROM_ARTIFACTS 
    ${CMAKE_CURRENT_BINARY_DIR}/${ROM_NAME}.nes
    ${CMAKE_CURRENT_BINARY_DIR}/${ROM_NAME}.dbg
    ${CMAKE_CURRENT_BINARY_DIR}/${ROM_NAME}.label.txt   
)

set(OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bin)

# Copy them to bin/
add_custom_command(
    TARGET build_rom POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy ${ROM_ARTIFACTS} ${OUTPUT_DIR}/
    COMMENT "Copying all ${ROM_NAME}.* files to bin/"
)

# Clean target
add_custom_target(clean_rom
    COMMAND ${CMAKE_COMMAND} -E echo "Cleaning ROM artifacts..."
    COMMAND ${CMAKE_COMMAND} -E rm -f ${ROM_ARTIFACTS}
    COMMENT "Remove ${ROM_NAME} build outputs"
)

# Run NEW rom
add_custom_target(run_emulator
    COMMAND ${EMULATOR} ${ROM_NAME}.nes
    WORKING_DIRECTORY ${OUTPUT_DIR}
    COMMENT "Running ROM in emulator"
)