project('vast', 'c', 'vala',
        version: '0.0.1',
        meson_version: '>=0.36')

glib = dependency('glib-2.0', version: '>=2.32')
gobject = dependency('gobject-2.0', version: '>=2.32')
gio = dependency('gio-2.0', version: '>=2.32')
math = meson.get_compiler('c').find_library('m')
posix = meson.get_compiler('vala').find_library('posix')

g_ir_compiler = find_program('g-ir-compiler', required: false)

subdir('src')
subdir('benchmarks')
subdir('tests')
