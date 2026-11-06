qml_module(caelestia-scheme
    URI Caelestia.Scheme
    SOURCES
        colours.cpp
        schemehandles.cpp
        schemeopener.cpp
        wallpapers.cpp
    QML_SINGLETONS
        Colours.qml
    LIBRARIES
        caelestia-config
        caelestia-models
        caelestia-state
        caelestia::caelestia
    DEPENDENCIES
        Caelestia.Models
)
