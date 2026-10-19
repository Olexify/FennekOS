# fennek-kcm: one KDE settings page without Apply (changes save themselves). Built in the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-kcm LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
find_package(KF6 REQUIRED COMPONENTS KCMUtils CoreAddons)
add_executable(fennek-kcm main.cpp)
target_link_libraries(fennek-kcm Qt6::Widgets KF6::KCMUtils KF6::CoreAddons)
install(TARGETS fennek-kcm RUNTIME DESTINATION bin)
