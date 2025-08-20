cmake_minimum_required(VERSION 2.8)

# Select platform (LINUX or RTOS). Default to LINUX.
if (NOT USE_SYSTEM_ARCH)
    set(USE_SYSTEM_ARCH LINUX)
endif ()

# Allow forcing which prebuilt vendor-lib subdir to use under psdk_lib/lib/
# e.g. x86_64-linux-gnu-gcc, aarch64-linux-gnu-gcc, arm-linux-gnueabihf-gcc
set(PSDK_LIB_ARCH_DIR "" CACHE STRING "PSDK prebuilt lib subdir under psdk_lib/lib")

if (USE_SYSTEM_ARCH MATCHES RTOS)
    cmake_minimum_required(VERSION 3.15)
    set(CMAKE_C_COMPILER arm-none-eabi-gcc)
    set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
    set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
    set(CMAKE_AR arm-none-eabi-ar)
    set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
    set(CMAKE_OBJDUMP arm-none-eabi-objdump)
    set(SIZE arm-none-eabi-size)
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
endif ()

project(entry)

# Disallow in-source builds
if (" ${CMAKE_SOURCE_DIR}" STREQUAL " ${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "FATAL: In-source builds are not allowed.\n"
                        "Create a separate directory for build files.")
endif ()

if (USE_SYSTEM_ARCH MATCHES LINUX)
    # --- Choose which Linux platform's config header to ship ---
# manifold2 (default) or raspberry_pi
set(PSDK_LINUX_PLATFORM "manifold2" CACHE STRING "Linux platform config to install (manifold2|raspberry_pi)")
set_property(CACHE PSDK_LINUX_PLATFORM PROPERTY STRINGS manifold2 raspberry_pi)

# Resolve prebuilt vendor lib path (keep your existing logic / override)
# ... your uname / PSDK_LIB_ARCH_DIR logic that sets LIBRARY_PATH ...

# ---- Build sample static libs? (optional) ----
option(PSDK_BUILD_SAMPLE_LIBS "Build static libs from module_sample sources" OFF)

if(PSDK_BUILD_SAMPLE_LIBS)
  # C sample module
  file(GLOB_RECURSE PSDK_SAMPLES_C_SRC samples/sample_c/module_sample/*.c)
  add_library(psdk_samples_c STATIC ${PSDK_SAMPLES_C_SRC})
  target_include_directories(psdk_samples_c PUBLIC
    ${CMAKE_SOURCE_DIR}/psdk_lib/include
    ${CMAKE_SOURCE_DIR}/samples/sample_c/module_sample
    ${CMAKE_SOURCE_DIR}/samples/sample_c/platform/linux/${PSDK_LINUX_PLATFORM}/application  # <- dji_sdk_config.h
    ${CMAKE_SOURCE_DIR}/samples/sample_c/platform/linux/common
  )
  install(TARGETS psdk_samples_c ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)

  # C++ sample module
  file(GLOB_RECURSE PSDK_SAMPLES_CPP_SRC samples/sample_c++/module_sample/*.cpp)
  add_library(psdk_samples_cpp STATIC ${PSDK_SAMPLES_CPP_SRC})
  target_include_directories(psdk_samples_cpp PUBLIC
    ${CMAKE_SOURCE_DIR}/psdk_lib/include
    ${CMAKE_SOURCE_DIR}/samples/sample_c++/module_sample
    ${CMAKE_SOURCE_DIR}/samples/sample_c/platform/linux/${PSDK_LINUX_PLATFORM}/application
    ${CMAKE_SOURCE_DIR}/samples/sample_c/platform/linux/common
  )
  install(TARGETS psdk_samples_cpp ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
endif()

# ---- Resolve prebuilt vendor lib dir (required) ----
# Prefer explicit override (works for cross builds); otherwise infer from host.
if (USE_SYSTEM_ARCH MATCHES LINUX)
    # --- Choose which Linux platform's config header to ship ---
    set(PSDK_LINUX_PLATFORM "manifold2" CACHE STRING "Linux platform config to install (manifold2|raspberry_pi)")
    set_property(CACHE PSDK_LINUX_PLATFORM PROPERTY STRINGS manifold2 raspberry_pi)

    # ---- Resolve prebuilt vendor lib dir ----
    set(LIBRARY_PATH "")
    if (PSDK_LIB_ARCH_DIR)
      set(LIBRARY_PATH "${CMAKE_SOURCE_DIR}/psdk_lib/lib/${PSDK_LIB_ARCH_DIR}")
    else()
      execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE DEVICE_SYSTEM_ID
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      if (DEVICE_SYSTEM_ID MATCHES "x86_64")
        set(LIBRARY_PATH "${CMAKE_SOURCE_DIR}/psdk_lib/lib/x86_64-linux-gnu-gcc")
      elseif (DEVICE_SYSTEM_ID MATCHES "aarch64")
        set(LIBRARY_PATH "${CMAKE_SOURCE_DIR}/psdk_lib/lib/aarch64-linux-gnu-gcc")
      elseif (DEVICE_SYSTEM_ID MATCHES "arm")
        set(LIBRARY_PATH "${CMAKE_SOURCE_DIR}/psdk_lib/lib/arm-linux-gnueabihf-gcc")
      else()
        message(FATAL_ERROR
          "Could not infer PSDK lib dir for '${DEVICE_SYSTEM_ID}'. "
          "Pass -DPSDK_LIB_ARCH_DIR=<subdir> (e.g. x86_64-linux-gnu-gcc).")
      endif()
    endif()

    if (NOT EXISTS "${LIBRARY_PATH}/libpayloadsdk.a")
      message(FATAL_ERROR
        "libpayloadsdk.a not found in: ${LIBRARY_PATH}\n"
        "Set -DPSDK_LIB_ARCH_DIR to the correct subdir under psdk_lib/lib.")
    endif()

    message(STATUS "PSDK LIBRARY_PATH: ${LIBRARY_PATH}")

    # ---- Build sample libs / install SDK, etc ----
    # ... rest of your sample libs, install(), etc ...
endif()

elseif (USE_SYSTEM_ARCH MATCHES RTOS)
    add_definitions(-DSYSTEM_ARCH_RTOS)
    add_subdirectory(samples/sample_c/platform/rtos_freertos/stm32f4_discovery/project/armgcc)
endif ()

add_custom_target(${PROJECT_NAME} ALL)
