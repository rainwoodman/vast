test('test', executable('vast-test', 'vast-test.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          c_args: ['-g', '-O0', '-Wno-unused'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')
