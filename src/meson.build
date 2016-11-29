vast_sources = [
    'value.vala',
    'array.vala',
    'iterator.vala',
    'function.vala',
    'formatter.vala',
    'string-formatter.vala',
    'multi-iterator.vala'
     ]

vast_lib = library('vast-1.0', vast_sources,
                    vala_args: ['--vapidir=' + meson.current_source_dir()],
                    vala_gir: 'Vast-1.0.gir',
                    c_args: ['-g', '-O0', '-Wno-unused'],
                    dependencies: [glib, gobject, gmodule, gio, math],
                    install: true)

install_headers(meson.current_build_dir() + '/vast-1.0.h')
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
endif

pkgconfig = import('pkgconfig')
pkgconfig.generate(name: 'vast-1.0',
                   description: 'Deep learning with GNOME infrastructure',
                   version: meson.project_version(),
#                   requires: '',
                   libraries: vast_lib)
