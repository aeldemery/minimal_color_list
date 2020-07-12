project ('testproj', 'vala', 'c')

dependencies = [
    dependency ('gobject-2.0'),
    dependency ('glib-2.0'),
    dependency ('gtk4'),
    meson.get_compiler('c').find_library('m', required: false),
]

sources = files (
    [
        'source/main.vala',
    ]
)

gnome = import('gnome')

resources = gnome.compile_resources (
    'as-resources', 'data/github.aeldemery.gtk4_color_list.gresource.xml',
    source_dir: 'data',
    c_name: 'as',
)

executable (
    meson.project_name(),
    resources,
    sources: sources,
    dependencies: dependencies,
    install: true,
)