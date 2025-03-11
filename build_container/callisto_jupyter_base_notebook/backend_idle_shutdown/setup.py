from setuptools import setup, find_packages

setup(
    name='backend_idle_shutdown',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    install_requires=['jupyter-server', 'boto3', 'kubernetes'],
    entry_points={
        'jupyter_serverproxy_servers': [
            "backend_idle_shutdown = backend_idle_shutdown:load_jupyter_server_extension",
        ],
    },
)
