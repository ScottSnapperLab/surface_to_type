"""Install setup."""
import setuptools

setuptools.setup(
    name="surface_to_type",
    version="0.0.1",
    url="git@github.com:ScottSnapperLab/surface_to_type.git",

    author="Gus Dunn",
    author_email="w.gus.dunn@gmail.com",

    description="Allow feable-minded non-immunologists a way to translate cell surface markers into which cell-types the figure or speaker is likely to be referencing.",
    # long_description=open('README.rst').read(),

    packages=setuptools.find_packages('src'),
    package_dir={"": "src"},


    install_requires=[],

    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],

    entry_points={
    "console_scripts": [
        "surface_to_type = surface_to_type.cli.main:run",
        ]
    },
)
