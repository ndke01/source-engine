#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== Nillerusr's source compiler ===${NC}"

echo "Target OS:"
PS3="Enter number: "
options_os=("Linux" "Android" "Server" "Continue compile" "Continue compile(android)" "Guide" "Exit")

select os in "${options_os[@]}"
do
    case $os in
        "Linux")   PLATFORM="linux"; break ;;
        "Android") PLATFORM="android"; break ;;
        "Server") PLATFORM="server"; break ;;
        "Continue compile") PLATFORM="continuepc"; break ;;
        "Continue compile(android)") PLATFORM="continue"; break ;;
        "Гайд") echo -e "This script simplifies engine compilation and APK building.\n
Android: Use 'download.sh' to get the NDK/SDK and clang. Place the folder with your APK source code
next to the engine sources and rename it to 'apk-sources' (or edit this script to match your folder's name).\n
For Linux builds, create a 'games' folder next to the engine; all compiled libraries will be saved there, making it easier to launch the game.\n
Server builds will be saved in the 'out' folder inside your engine directory.\n
Script author: ndke" ;;
    "Выход")   exit 0 ;;
        *) echo "Wrong number $REPLY" ;;
    esac
done

if [[ "$PLATFORM" != "continuepc" && "$PLATFORM" != "continue" ]]; then
    echo "Game:"
    options_game=("Half-Life 2" "Half-Life 2 Episodes" "Half-life 2 Multiplayer" "Counter-Strike: Source" "Portal" "Day of Defeat: Source" "Half-Life: Source" "Custom Mod")
    select build_game in "${options_game[@]}"
    do
        case $build_game in
            "Half-Life 2")
                GAME=""
                break
                ;;
            "Half-Life 2 Episodes")
                GAME="episodic"
                break
                ;;
            "Half-life 2 Multiplayer")
                GAME="hl2mp"
                break
                ;;
            "Counter-Strike: Source")
                GAME="cstrike"
                break
                ;;
            "Portal")
                GAME="portal"
                break
                ;;
            "Day of Defeat: Source")
                GAME="dod"
                break
                ;;
            "Half-Life: Source")
                GAME="hl1"
                break
                ;;
            "Custom Mod")
                echo -n "Enter custom mod name"
                read GAME
                break
                ;;
            *) echo "Wrong number $REPLY" ;;
        esac
    done
fi

echo -e "\nArchitecture:"

if [[ "$PLATFORM" != "android" && "$PLATFORM" != "continuepc" && "$PLATFORM" != "continue" ]]; then
    bit_build_pc=("64bit" "32bit")
    select build_pc_bit in "${bit_build_pc[@]}"
    do
        case $build_pc_bit in
            "64bit")
                BIT_PC_FLAGS="" 
                break
                ;;
            "32bit")
                BIT_PC_FLAGS="--32bits"
                break
                ;;
            *) echo "Wrong number $REPLY" ;;
        esac
    done
elif [[ "$PLATFORM" != "continuepc" && "$PLATFORM" != "continue" ]]; then
    bit_build_pc=("arm64-v8a" "armeabi-v7a")
    select build_bit in "${bit_build[@]}"
    do
        case $build_bit in
            "arm64-v8a")
                BIT_FLAGS="--android=aarch64,host,21" 
                break
                ;;
            "armeabi-v7a")
                BIT_FLAGS="--android=armeabi-v7a-hard,host,21"
                break
                ;;
            *) echo "Wrong number $REPLY" ;;
        esac
    done
fi

echo -e "\nBuild type:"
options_type=("Release" "Debug")
select build_type in "${options_type[@]}"
do
    case $build_type in
        "Release")
            MODE="release"
            FINAL_FLAGS="--strip"
            APK_FLAGS="assembledebug"
            break
            ;;
        "Debug")
            MODE="debug"
            APK_FLAGS="assembledebug"
            break
            ;;
        *) echo "Wrong number $REPLY" ;;
    esac
done

echo -e "\nConfiguration: ${GREEN}$os [$MODE]${NC}"
echo "----------------------------------------"

if [[ "$PLATFORM" == "linux" ]]; then
    rm -r build
    python3 ./waf configure -T $MODE --build-games=$GAME --prefix=../games/ --disable-warns --togles $BIT_PC_FLAGS

elif [[ "$PLATFORM" == "android" ]]; then
    export ANDROID_NDK_HOME="$(readlink -f ../android-ndk-r10e)"
    export PATH="$(readlink -f ../clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04/bin):$PATH"
    rm -r build
    python3 ./waf configure -T $MODE --build-games=$GAME --prefix=../apk-sources/app/src/main/ --disable-warns --togles $BIT_FLAGS

elif [[ "$PLATFORM" == "server" ]]; then
    rm -r build
    python3 ./waf configure -T $MODE --build-games=$GAME --prefix=out/ --disable-warns -d $BIT_PC_FLAGS

elif [[ "$PLATFORM" == "continue" ]]; then
    export ANDROID_NDK_HOME="$(readlink -f ../android-ndk-r10e)"
    export PATH="$(readlink -f ../clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04/bin):$PATH"
fi

echo -e "\n${GREEN}Starting compilation...${NC}"
python3 ./waf install -p $FINAL_FLAGS
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Compilation completed successfully${NC}"
else
    echo -e "\n\033[0;31mError: Compilation failed with an error\033[0m"
    exit 1
fi

if [[ "$PLATFORM" == "android" || "$PLATFORM" == "continue" ]]; then
    echo -e "\n${GREEN}Building APK...${NC}"
    cd ../apk-sources/app/src/main
    cp -a lib/. jniLibs/
    rm -rf lib
    cd ../../../
    export ANDROID_HOME="$(readlink -f ../android-sdk)"
    ./gradlew assemble $APK_FLAGS
    echo -e "\n${GREEN}APK build completed${NC}"
fi