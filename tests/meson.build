test('test', executable('vast-test', 'vast-test.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')

test('test-dtype', executable('test-dtype', 'test-dtype.vala',
                          vala_args: ['--vapidir=' + meson.current_source_dir() + '/../src'],
                          dependencies: [glib, gobject, gmodule, gio, vast]),
     args: '')
