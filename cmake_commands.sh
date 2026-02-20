#!/bin/bash

# © 2026 Massachusetts Institute of Technology
# MIT License

# Make script inform its calling s3_wrapper.py of any errors
set -e

# Show shell commands as they are executed
set -x

# c2rust_commands.sh <project src directory> <output directory>
# Example implementing source translation by using c2rust
# After translation, changes ownership of the files to UID $newuid and GID $newgid
# (environment variables, used so that the user calling the container
# still owns the files).
mkdir build
pushd build

# include CMake file API query to extract target name
mkdir -p .cmake/api/v1/query
touch .cmake/api/v1/query/codemodel-v2
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 $1/CMakeLists.txt