test('test', executable('vast-test', 'vast-test.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          c_args: ['-g', '-O0', '-Wno-unused'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')

test('test-dtype', executable('test-dtype', 'test-dtype.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          c_args: ['-g', '-O0', '-Wno-unused'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')

test('test-array', executable('test-array', 'test-array.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          c_args: ['-g', '-O0', '-Wno-unused'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')
