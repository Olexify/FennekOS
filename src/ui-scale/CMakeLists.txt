# Fennek OS desktop Ctrl+wheel = display scale (a Plasma "containment action"). Built during the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-ui-scale LANGUAGES CXX)
set(QT_MAJOR_VERSION 6)  # ECM: Qt 6 paths, not qmake (Qt 5)
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
set(KDE_INSTALL_USE_QT_SYS_PATHS ON)  # plugins go where Qt looks: /usr/lib64/qt6/plugins
include(KDEInstallDirs6)
include(KDECMakeSettings)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)  # kcoreaddons_add_plugin needs it
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Widgets DBus)
# libplasma's CMake config doesn't load its public dependencies itself: load them first.
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons Kirigami)
find_package(Plasma REQUIRED)
kcoreaddons_add_plugin(org.fennek.uiscale SOURCES uiscale.cpp INSTALL_NAMESPACE "plasma/containmentactions")
target_link_libraries(org.fennek.uiscale Qt6::Widgets Qt6::DBus Plasma::Plasma KF6::CoreAddons)
