vast_sources = [
    'array.vala',
    'array.c',
    'iterator.vala',
    'formatter.vala',
    'string-formatter.vala',
    'graph.vala',
    'graph-executor.vala',
    'simple-graph-executor.vala',
    'operation.vala',
    'simple-operation.vala',
    'gi-operation.vala'
     ]

subdir('routines')

vast_lib = library('vast-1.0', vast_sources + routines_sources,
                    vala_header: 'vast.h',
                    vala_gir: 'Vast-1.0.gir',
                    dependencies: [glib, gobject, gobject_introspection, gio, math, posix, uuid],
                    install: true)

install_headers(meson.current_build_dir() + '/vast.h', subdir: 'vast-1.0')
install_data([meson.current_build_dir() + '/vast-1.0.vapi', 'vast-1.0.deps'],
             install_dir: 'share/vala/vapi')
install_data(meson.current_build_dir() + '/Vast-1.0.gir', install_dir: 'share/gir-1.0')

vast = declare_dependency(link_with: vast_lib,
                          include_directories: include_directories('.'))

if g_ir_compiler.found()
    custom_target('typelib',
                  command: [g_ir_compiler, '--output', '@OUTPUT@',
                                           '--shared-library', vast_lib.full_path(),
                                           meson.current_build_dir() + '/Vast-1.0.gir'],
                  output: 'Vast-1.0.typelib',
                  depends: vast_lib,
                  install: true,
                  install_dir: '@0@/girepository-1.0'.format(get_option('libdir')))

    python_api_version = '3.5'
    install_data('gi/overrides/Vast.py',
                 install_dir: '@0@/python@1@/site-packages/gi/overrides'.format(get_option('libdir'), python_api_version))

endif

pkgconfig = import('pkgconfig')
pkgconfig.generate(name: 'vast-1.0',
                   description: 'Deep learning with GNOME infrastructure',
                   version: meson.project_version(),
                   requires: ['glib-2.0', 'gobject-2.0', 'gio-2.0'],
                   libraries: vast_lib,
                   libraries_private: ['-L${libdir}', '-lm'],
                   subdirs: 'vast-1.0')
