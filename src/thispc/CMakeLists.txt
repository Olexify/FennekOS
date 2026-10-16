# Fennek OS "This PC" page for Files: the thispc:/ location (a KIO worker). Built during the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-thispc LANGUAGES CXX)
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
set(KDE_INSTALL_USE_QT_SYS_PATHS ON)  # plugins go where Qt looks: /usr/lib64/qt6/plugins
include(KDEInstallDirs6)
include(KDECMakeSettings)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)  # kcoreaddons_add_plugin needs it
find_package(Qt6 REQUIRED COMPONENTS Core Network)
find_package(KF6 REQUIRED COMPONENTS CoreAddons KIO)
kcoreaddons_add_plugin(kio_thispc SOURCES thispc.cpp INSTALL_NAMESPACE "kf6/kio")
target_link_libraries(kio_thispc Qt6::Core KF6::KIOCore)
