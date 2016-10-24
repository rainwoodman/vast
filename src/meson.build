vast_sources = [
    'vast.vala',
    'typefactory.vala',
    'typedescr.vala',
    'numeric.vala',
    'array.vala',
    'arrayiterator.vala',
    'arrayslice.vala',
    'ufunc.vala',
     ]

vast_lib = library('vast-1.0', vast_sources,
                    vala_args: ['--vapidir=' + meson.current_source_dir()],
                    c_args: ['-g', '-O0', '-Wno-unused'],
                    dependencies: [glib, gobject, gmodule, gio, math],
                    install: true)

vast = declare_dependency(link_with: vast_lib,
                               include_directories: include_directories('.'))

install_headers('vast-1.0.h')
install_data([meson.current_build_dir() + '/vast-1.0.vapi', 'vast-1.0.deps'],
             install_dir: 'share/vala/vapi')

pkgconfig = import('pkgconfig')
pkgconfig.generate(name: 'vast-1.0',
                   description: 'Deep learning with GNOME infrastructure',
                   version: meson.project_version(),
#                   requires: '',
                   libraries: vast_lib)
