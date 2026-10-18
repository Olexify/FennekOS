# Fennek OS widget style: KDE's Breeze, unchanged in looks; the mouse wheel scrolls the page instead of changing a
# drop-down, number box or slider the pointer happens to pass over. Built during the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-style LANGUAGES CXX)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
set(CMAKE_AUTOMOC ON)
add_library(fennekstyle MODULE fennekstyle.cpp)
target_link_libraries(fennekstyle Qt6::Widgets)
install(TARGETS fennekstyle DESTINATION ${CMAKE_INSTALL_PREFIX}/lib64/qt6/plugins/styles)
