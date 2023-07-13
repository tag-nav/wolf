## WOLF 

This repository serves as a sandbox for [WOLF: A Modular Estimation Framework for Robotics](http://mobile_robotics.pages.iri.upc-csic.es/wolf_projects/wolf_lib/wolf-doc-sphinx/index.html), which is a candidate simultaneous localization and mapping (SLAM) framework using multi-scale fiducial markers.

## Installation

The overall installation procedure is the same as that of the original WOLF, as presented in its [installation manual](http://mobile_robotics.pages.iri.upc-csic.es/wolf_projects/wolf_lib/wolf-doc-sphinx/installation/_index.html).

### Prerequisite

WOLF requires C++14 and has dependencies on CMake, Autoreconf, Eigen, Ceres, Yaml-cpp, and spdlog. For detailed information, please refer to the [dependencies](http://mobile_robotics.pages.iri.upc-csic.es/wolf_projects/wolf_lib/wolf-doc-sphinx/installation/dependencies.html).

### Option 1: Install by building every submodule

The first option to install WOLF is to install each submodule, which can be obtained by cloning this repository.
```
$ cd SUBMODULE_NAME
$ mkdir build && cd build
$ cmake ..
$ make -j$(nproc)
$ sudo make install
$ cd ..
```
Repeat this process in the following order: `wolf`, `laser`, `imu`, `vision`, `apriltag`, and `gnss`.

### Option 2: Install by executing `install_wolf.sh`

Alternatively, you can install WOLF by executing the `install_wolf.sh` bash file.

### What's changed compared to the original WOLF?

- `apriltag` library now refers to [https://github.com/tag-nav/multiscale-marker-detection](https://github.com/tag-nav/multiscale-marker-detection) instead of [https://github.com/AprilRobotics/apriltag](https://github.com/AprilRobotics/apriltag).
- `vision` module now refers to [https://github.com/tag-nav/wolf_vision](https://github.com/tag-nav/wolf_vision) instead of [https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/vision](https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/vision).
- `apriltag` module now refers to [https://github.com/tag-nav/wolf_apriltag](https://github.com/tag-nav/wolf_apriltag) instead of [https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/apriltag](https://gitlab.iri.upc.edu/mobile_robotics/wolf_projects/wolf_lib/plugins/apriltag).

These changes have already been reflected in both Option 1 and Option 2.