# RPi Zero (ARMv6, hard-float)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Use full paths so CMake never complains
set(CMAKE_C_COMPILER   /usr/bin/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/arm-linux-gnueabihf-g++)

# Tune for ARM11 (ARMv6), VFP, hard-float ABI
set(PI_ZERO_FLAGS "-mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -marm")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} ${PI_ZERO_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PI_ZERO_FLAGS}")
