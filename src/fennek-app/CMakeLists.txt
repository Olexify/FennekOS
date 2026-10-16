# fennek-app: launcher for Fennek's own QML apps (Settings, Firewall, Welcome, App history). Built in the image build.
cmake_minimum_required(VERSION 3.16)
project(fennek-app LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Widgets Qml Quick QuickControls2)
add_executable(fennek-app main.cpp)
target_link_libraries(fennek-app Qt6::Widgets Qt6::Qml Qt6::Quick Qt6::QuickControls2)
install(TARGETS fennek-app RUNTIME DESTINATION bin)
