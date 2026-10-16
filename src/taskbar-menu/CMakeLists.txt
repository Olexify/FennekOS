# Fennek OS classic taskbar right-click menu (a Plasma "containment action"). Built during the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-taskbar-menu LANGUAGES CXX)
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)  # kcoreaddons_add_plugin needs it
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets DBus)
find_package(Plasma REQUIRED)
find_package(KF6CoreAddons REQUIRED)
kcoreaddons_add_plugin(org.fennek.taskbarmenu SOURCES taskbarmenu.cpp INSTALL_NAMESPACE "plasma/containmentactions")
target_link_libraries(org.fennek.taskbarmenu Qt6::Widgets Qt6::DBus Plasma::Plasma KF6::CoreAddons)
