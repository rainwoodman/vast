test('vast', executable('vast-test', 'vast-test.vala',
                        vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                        dependencies: [glib, gobject, gobject_introspection, gio, vast]),
     env: ['GI_TYPELIB_PATH=' + meson.current_build_dir() + '/../src'])

test('graph', executable('vast-test-graph', 'vast-test-graph.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          dependencies: [glib, gobject, gobject_introspection, gio, vast]))

if g_ir_compiler.found()
    test('gi', find_program('gi-test.py'),
         env: ['GI_TYPELIB_PATH=' + meson.current_build_dir() + '/../src',
           'PYTHONPATH=' + meson.current_source_dir()])
endif
