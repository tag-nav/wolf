#!/bin/bash
set -e

# COLORS
BLACK='\033[0;30m'
DARK_GRAY='\033[1;30m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
LIGHT_GRAY='\033[0;37m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET_STYLE='\033[0m'

## FUNCTIONS #####################################################
func_make_install () {
   if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
      make install
   else
      sudo make install
   fi
}

func_ldconfig () {
   if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
      ldconfig
   else
      sudo ldconfig
   fi
}

func_echo () {
   echo -e "\n${BOLD}[install_wolf]: ${BLUE}${1}${RESET_STYLE}"
}

func_echo_error () {
   echo -e "\n${BOLD}[install_wolf]: ${RED}${1}${RESET_STYLE}"
}

usage() { 
   echo -e "\n${BOLD}[install_wolf]: ${BLUE}Usage: $0 with the following optional inputs. If not set, everything will be asked during execution."
   echo -e "    ${BOLD}-d <string>${BLUE}: dependencies destination path (either /global/path or relative/path)."
   echo -e "    ${BOLD}-w <string>${BLUE}: wolf folder destination path (either /global/path or relative/path)."
   echo -e "    ${BOLD}-a ${BLUE}: installs all plugins (incompatible with -p)"
   echo -e "    ${BOLD}-p <string>${BLUE}: plugins to be installed (incompatible with -a) being a string of 6 chars y/n corresponding to plugins imu, gnss, laser, vision, apriltag, bodydynamics (for example 'ynynnn'). Plugins apriltag and bodydynamics won't be installed if vision and imu plugins are installed, respectively."
   echo -e "    ${BOLD}-f <y/n>${BLUE}: install Falko optional laser dependency (if laser plugin is installed)."
   echo -e "    ${BOLD}-c <y/n>${BLUE}: install CSM optional laser dependency (if laser plugin is installed).${RESET_STYLE}"  
}

func_check_yn () {
   if [ "$1" != "y" ] && [ "$1" != "n" ]; then
      func_echo_error "options -p, -f, -c should containing only 'y' or 'n'"
      usage
      exit 0
   fi
}



# START #####################################################
CORES=$(nproc)
func_echo "The number of available cores on this machine is $CORES"
RUN_PATH=$PWD

## OPTIONS #####################################################
INSTALL_PLUGINS=""
INSTALL_IMU="undefined"
INSTALL_GNSS="undefined"
INSTALL_LASER="undefined"
INSTALL_VISION="undefined"
INSTALL_APRILTAG="undefined"
INSTALL_BODYDYNAMICS="undefined"
INSTALL_FALKO="undefined"
INSTALL_CSM="undefined"
DEPS_PATH="undefined"
WOLF_PATH="undefined"

while getopts "ap:d:w:hf:c:" opt; do
   case ${opt} in
      a) # install all plugins
      	if [ "$INSTALL_PLUGINS" != "" ]; then
      	   func_echo_error "options -p and -a are incompatible."
      	   usage
      	   exit 0
      	fi
         INSTALL_PLUGINS="a"
         INSTALL_IMU="y"
         INSTALL_GNSS="y"
         INSTALL_LASER="y"
         INSTALL_VISION="y"
         INSTALL_APRILTAG="y"
         INSTALL_BODYDYNAMICS="y"
         ;;
      p) # install all plugins
      	if [ "$INSTALL_PLUGINS" != "" ]; then
      	   func_echo_error "options -p and -a are incompatible."
      	   usage
      	   exit 0
      	fi
         if [ ${#OPTARG} != 6 ]; then
            func_echo_error "option -p should contain 6 characters."
      	   usage
      	   exit 0
      	 fi
         INSTALL_PLUGINS=$OPTARG
         INSTALL_IMU=${INSTALL_PLUGINS:0:1}
         INSTALL_GNSS=${INSTALL_PLUGINS:1:1}
         INSTALL_LASER=${INSTALL_PLUGINS:2:1}
         INSTALL_VISION=${INSTALL_PLUGINS:3:1}
         INSTALL_APRILTAG=${INSTALL_PLUGINS:4:1}
         INSTALL_BODYDYNAMICS=${INSTALL_PLUGINS:5:1}
         func_check_yn $INSTALL_IMU
         func_check_yn $INSTALL_GNSS
         func_check_yn $INSTALL_LASER
         func_check_yn $INSTALL_VISION
         func_check_yn $INSTALL_APRILTAG
         func_check_yn $INSTALL_BODYDYNAMICS
         ;;
      f) # install falko      
         INSTALL_FALKO=$OPTARG
         func_check_yn $INSTALL_FALKO
         ;;
      c) # install csm      
         INSTALL_CSM=$OPTARG
         func_check_yn $INSTALL_CSM
         ;;
      d) # deps path      
         DEPS_PATH=$OPTARG
         if cd $DEPS_PATH ; then
            func_echo "Valid dependency path."
         else
            func_echo_error "Invalid dependency path."
            exit 1
         fi
         ;;
      w) # wolf path       
         WOLF_PATH=$OPTARG
         if cd $WOLF_PATH ; then
            func_echo "Valid wolf folder path."
         else
            func_echo_error "Invalid wolf folder path."
            exit 1
         fi
         ;;
      h ) # help
         usage
         exit 0
         ;;
      :)
         func_echo_error "Error: -${OPTARG} requires an argument."
         usage
         exit 1
         ;;
      *)
         usage
         exit 1
         ;;
   esac
done

# check sudo permissions
func_ldconfig

# UBUNTU
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
   apt install -y lsb-core
else
   sudo apt install -y lsb-core
fi
UBUNTU_DISTRO=$(lsb_release -rs);
if [ $UBUNTU_DISTRO == "18.04" ]; then
   func_echo "Ubuntu 18.04 - OK"
elif [ $UBUNTU_DISTRO == "20.04" ]; then
   func_echo "Ubuntu 20.04 - OK"
else
   func_echo_error "Non-supported Ubuntu version: ${UBUNTU_DISTRO}"
   exit 1
fi


# WOLF DEPENDENCIES #####################################################
cd $RUN_PATH
func_echo "You are in folder $PWD"
if [ $DEPS_PATH == "undefined" ]; then
   func_echo "Enter path for dependencies (either /global/path or relative/path):"
   read DEPS_PATH
fi
while ! cd $DEPS_PATH ; do
   func_echo_error "Invalid dependency path."
   func_echo "Enter path for dependencies (either /global/path or relative/path):"
   read DEPS_PATH
done
DEPS_PATH=$PWD
func_echo "path dependencies: $DEPS_PATH"

func_echo "Installing dependencies via apt install..."

if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
   #apt install -y git wget unzip dh-autoreconf cmake build-essential libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev git libboost-all-dev libyaml-cpp-dev wget unzip
   apt install -y git wget unzip cmake build-essential libeigen3-dev libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev git libboost-all-dev libyaml-cpp-dev wget unzip
else
   #sudo apt install -y git wget unzip dh-autoreconf cmake build-essential libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev git libboost-all-dev libyaml-cpp-dev wget unzip
   sudo apt install -y git wget unzip cmake build-essential libeigen3-dev libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev git libboost-all-dev libyaml-cpp-dev wget unzip
fi

# ceres
func_echo "Installing ceres 2.0 via source..."
cd $DEPS_PATH
git clone --depth 1 -b 2.0.0 https://ceres-solver.googlesource.com/ceres-solver
cd ceres-solver
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$CORES
make test
func_make_install

# spdlog
func_echo "Installing spdlog 0.17 via source..."
cd $DEPS_PATH
git clone --depth 1 -b v0.17.0 https://github.com/gabime/spdlog.git
cd spdlog
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fPIC" ..
make -j$CORES
func_make_install


# WOLF #####################################################
cd $RUN_PATH
func_echo "You are in folder $PWD"
if [ $WOLF_PATH == "undefined" ]; then
   func_echo "Enter path for wolf folder (either /global/path or relative/path):"
   read WOLF_PATH
fi
while ! cd $WOLF_PATH ; do
   func_echo_error "Invalid wolf folder path."
   func_echo "Enter path for dependencies (either /global/path or relative/path):"
   read WOLF_PATH
done
mkdir -pv wolf
cd wolf
WOLF_PATH=$PWD
func_echo "wolf folder path: $WOLF_PATH"


# CORE -----------------------------------------------------
func_echo "Cloning wolf core..."
cd $WOLF_PATH
git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/wolf.git
cd wolf

func_echo "Compiling wolf core..."
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
make -j$CORES

func_echo "Installing wolf core..."
func_make_install

func_echo "Testing wolf core..."
ctest -j$CORES


# IMU --------------------------------------------------
if [ $INSTALL_IMU == "undefined" ]; then
   func_echo "Do you want to download and install plugin imu? (y/n)"
   read INSTALL_IMU
   while [ $INSTALL_IMU != "y" ] && [ $INSTALL_IMU != "n" ]; do
      func_echo_error "wrong input ${INSTALL_IMU}"
      func_echo "Do you want to download and install plugin imu? (y/n)"
      read INSTALL_IMU
   done
fi
if [ $INSTALL_IMU == "y" ]; then

   func_echo "Cloning plugin imu..."
   cd $WOLF_PATH
   git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/imu.git
   cd imu
   
   func_echo "Compiling plugin imu..."
   mkdir -p build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   make -j$CORES

   func_echo "Installing plugin imu..."
   func_make_install

   func_echo "Testing plugin imu..."
   ctest -j$CORES
else
   func_echo "Skipping plugin imu."
fi

# GNSS --------------------------------------------------
if [ $INSTALL_GNSS == "undefined" ]; then
   func_echo "Do you want to download and install plugin gnss? (y/n)"
   read INSTALL_GNSS
   while [ $INSTALL_GNSS != "y" ] && [ $INSTALL_GNSS != "n" ]; do
      func_echo_error "wrong input ${INSTALL_GNSS}"
      func_echo "Do you want to download and install plugin gnss? (y/n)"
      read INSTALL_GNSS
   done
fi
if [ $INSTALL_GNSS == "y" ]; then

   func_echo "Installing plugin gnss dependencies..."
   cd $DEPS_PATH
   git clone https://gitlab.iri.upc.edu/mobile_robotics/gauss_project/gnss_utils.git
   cd gnss_utils
   git submodule update --init
   mkdir -p build && cd build
   cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
   make -j$CORES
   ctest -j$CORES
   func_make_install

   func_echo "Cloning plugin gnss..."
   cd $WOLF_PATH
   git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/gnss.git
   cd gnss

   func_echo "Compiling plugin gnss..."
   mkdir -p build && cd build
   cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
   make -j$CORES

   func_echo "Installing plugin gnss..."
   func_make_install

   func_echo "Testing plugin gnss..."
   func_ldconfig
   ctest -j$CORES
else
   func_echo "Skipping plugin gnss."
fi


# LASER --------------------------------------------------
if [ $INSTALL_LASER == "undefined" ]; then
   func_echo "Do you want to download and install plugin laser? (y/n)"
   read INSTALL_LASER
   while [ $INSTALL_LASER != "y" ] && [ $INSTALL_LASER != "n" ]; do
      func_echo_error "wrong input ${INSTALL_LASER}"
      func_echo "Do you want to download and install plugin laser? (y/n)"
      read INSTALL_LASER
   done
fi
if [ $INSTALL_LASER == "y" ]; then

   func_echo "Installing plugin laser dependencies..."

   # CSM
   if [ $INSTALL_CSM == "undefined" ]; then
      func_echo "Do you want to install CSM to enable ICP processors? (y/n)"
      read INSTALL_CSM
      while [ $INSTALL_CSM != "y" ] && [ $INSTALL_CSM != "n" ]; do
         func_echo_error "wrong input ${INSTALL_CSM}"
         func_echo "Do you want to install CSM to enable ICP processors? (y/n)"
         read INSTALL_CSM
      done
   fi
   if [ $INSTALL_CSM == "y" ]; then
      if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
         apt install -y libgsl-dev
      else
         sudo apt install -y libgsl-dev
      fi
      cd $DEPS_PATH
      git clone https://gitlab.iri.upc.edu/labrobotica/algorithms/csm.git
      cd csm
      mkdir -p build && cd build
      cmake -DCMAKE_BUILD_TYPE=Release ..
      make -j$CORES
      func_make_install
   else 
      func_echo "Skipping CSM."
   fi

   # FALKO
   if [ $INSTALL_FALKO == "undefined" ]; then
      func_echo "Do you want to install FALKO to enable Falko loop closure processors? (y/n)"
      read INSTALL_FALKO
      while [ $INSTALL_FALKO != "y" ] && [ $INSTALL_FALKO != "n" ]; do
         func_echo_error "wrong input ${INSTALL_FALKO}"
         func_echo "Do you want to install CSM to enable Falko loop closure processors? (y/n)"
         read INSTALL_FALKO
      done
   fi
   if [ $INSTALL_FALKO == "y" ]; then
      cd $DEPS_PATH
      git clone https://gitlab.iri.upc.edu/labrobotica/algorithms/falkolib.git
      cd falkolib
      mkdir -p build && cd build
      cmake -DCMAKE_BUILD_TYPE=Release ..
      make -j$CORES
      func_make_install
   else 
      func_echo "Skipping Falko."
   fi

   # LASER_SCAN_UTILS
   func_echo "Installing laser_scan_utils (required)..."
   cd $DEPS_PATH
   git clone https://gitlab.iri.upc.edu/labrobotica/algorithms/laser_scan_utils.git
   cd laser_scan_utils
   mkdir -p build && cd build
   cmake -DCMAKE_BUILD_TYPE=Release ..
   make -j$CORES
   func_ldconfig
   ctest -j$CORES
   func_make_install

   # PLUGIN
   func_echo "Cloning plugin laser..."
   cd $WOLF_PATH
   git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/laser.git
   cd laser

   func_echo "Compiling plugin laser..."
   mkdir -p build && cd build
   cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
   make -j$CORES

   func_echo "Installing plugin laser..."
   func_make_install

   func_echo "Testing plugin laser..."
   func_ldconfig
   ctest -j$CORES
else
   func_echo "Skipping plugin laser."
fi

# VISION --------------------------------------------------
if [ $INSTALL_VISION == "undefined" ]; then
   func_echo "Do you want to download and install plugin vision (requires to install opencv 3.3.0)? (y/n)"
   read INSTALL_VISION
   while [ $INSTALL_VISION != "y" ] && [ $INSTALL_VISION != "n" ]; do
      func_echo_error "wrong input ${INSTALL_VISION}"
      func_echo "Do you want to download and install plugin vision (requires to install opencv 3.3.0)? (y/n)"
      read INSTALL_VISION
   done
fi
if [ $INSTALL_VISION == "y" ]; then

   func_echo "Installing OpenCV (required by vision plugin)..."

   # opencv
   if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
      apt install -y libopencv-dev
   else
      sudo apt install -y libopencv-dev
   fi

   func_echo "Cloning plugin vision..."
   cd $WOLF_PATH
   git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/vision.git
   cd vision

   func_echo "Compiling plugin vision..."
   mkdir -p build && cd build
   cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
   make -j$CORES

   func_echo "Installing plugin vision..."
   func_make_install

   func_echo "Testing plugin vision..."
   func_ldconfig
   ctest -j$CORES
else
   func_echo "Skipping plugin vision."
fi

# APRILTAG --------------------------------------------------
if [ $INSTALL_VISION == "y" ]; then
   if [ $INSTALL_APRILTAG == "undefined" ]; then
      func_echo "Do you want to download and install plugin apriltag? (y/n)"
      read INSTALL_APRILTAG
      while [ $INSTALL_APRILTAG != "y" ] && [ $INSTALL_APRILTAG != "n" ]; do
         func_echo_error "wrong input ${INSTALL_APRILTAG}"
         func_echo "Do you want to download and install plugin apriltag? (y/n)"
         read INSTALL_APRILTAG
      done
   fi
   if [ $INSTALL_APRILTAG == "y" ]; then

      func_echo "Installing plugin apriltag dependencies..."
      cd $DEPS_PATH
      git clone https://github.com/AprilRobotics/apriltag apriltaglib
      cd apriltaglib
      mkdir -p build && cd build
      cmake -DCMAKE_BUILD_TYPE=Release ..
      make -j$CORES
      ctest -j$CORES
      func_make_install

      func_echo "Cloning plugin apriltag..."
      cd $WOLF_PATH
      git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/apriltag.git
      cd apriltag

      func_echo "Compiling plugin apriltag..."
      mkdir -p build && cd build
      cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=ON -DBUILD_TESTS=ON ..
      make -j$CORES

      func_echo "Installing plugin apriltag..."
      func_make_install

      func_echo "Testing plugin apriltag..."
      func_ldconfig
      ctest -j$CORES
   else
      func_echo "Skipping plugin apriltag."
   fi
else
   func_echo "Skipping plugin apriltag since plugin vision was not installed."
fi

# BODYDYNAMICS --------------------------------------------------
if [ $INSTALL_IMU == "y" ]; then
   if [ $INSTALL_BODYDYNAMICS == "undefined" ]; then
      func_echo "Do you want to download and install plugin bodydynamics? (y/n)"
      read INSTALL_BODYDYNAMICS
      while [ $INSTALL_BODYDYNAMICS != "y" ] && [ $INSTALL_BODYDYNAMICS != "n" ]; do
         func_echo_error "wrong input ${INSTALL_BODYDYNAMICS}"
         func_echo "Do you want to download and install plugin bodydynamics? (y/n)"
         read INSTALL_BODYDYNAMICS
      done
   fi
   if [ $INSTALL_BODYDYNAMICS == "y" ]; then

      func_echo "Cloning plugin bodydynamics..."
      cd $WOLF_PATH
      git clone -b main https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/bodydynamics.git
      cd bodydynamics

      func_echo "Compiling plugin bodydynamics..."
      mkdir -p build && cd build
      cmake .. -DCMAKE_BUILD_TYPW=Release
      make -j$CORES

      func_echo "Installing plugin bodydynamics..."
      func_make_install

      func_echo "Testing plugin bodydynamics..."
      func_ldconfig
      ctest -j$CORES
   else
      func_echo "Skipping plugin bodydynamics."
   fi
else
   func_echo "Skipping plugin bodydynamics since plugin imu was not installed."
fi

func_echo "Done! Enjoy!"