test('test', executable('vast-test', 'vast-test.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          dependencies: [glib, gobject, gio, vast]),
     args: '')

if g_ir_compiler.found()
    test('gi', find_program('gi-test.py'),
         env: ['GI_TYPELIB_PATH=' + meson.current_build_dir() + '/../src',
           'PYTHONPATH=' + meson.current_source_dir()])
endif
