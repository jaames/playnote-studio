cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

execute_process(
		COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
		COMMAND head -n 1
		COMMAND cut -c9-
		OUTPUT_VARIABLE SDK
		OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Game Name Customization
set(PLAYDATE_GAME_NAME Playnote)
set(PLAYDATE_GAME_DEVICE Playnote_DEVICE)

project(${PLAYDATE_GAME_NAME} C ASM)

if (TOOLCHAIN STREQUAL "armgcc")
	add_executable(${PLAYDATE_GAME_DEVICE} ${SDK}/C_API/buildsupport/setup.c extension/main.c ppmlib/ppm.c ppmlib/video.c ppmlib/ppmlib.c)
else()
	add_library(${PLAYDATE_GAME_NAME} SHARED extension/main.c ppmlib/ppm.c ppmlib/video.c ppmlib/ppmlib.c)
endif()

include(${SDK}/C_API/buildsupport/playdate_game.cmake)
