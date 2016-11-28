test('test', executable('vast-test', 'vast-test.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          c_args: ['-g', '-O0', '-Wno-unused'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')

if g_ir_compiler.found()
    test('gi', find_program('gi-test.py'), env: ['GI_TYPELIB_PATH=' + meson.current_build_dir() + '/../src'])
endif
