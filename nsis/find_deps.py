#!/usr/bin/env python3
#
# Copyright (C) 2024 Stefan Weil
#
# SPDX-License-Identifier: MIT
#
# Find the DLL files which are required for a given set of
# Windows binaries (executables, libraries, ...).

import argparse
import os
import pefile

def find_dependencies(args, binary, analyzed_deps):
    pe = pefile.PE(binary)
    pe.parse_data_directories()
    if args.verbose:
        print(f'{binary=}')
        # print(pe.dump_info())

    for entry in pe.DIRECTORY_ENTRY_IMPORT:
        name = entry.dll.decode('utf-8')
        if name in analyzed_deps:
            if args.verbose:
                print(f'skip {name} (already analyzed)')
            continue
        analyzed_deps.add(name)
        if args.dlldir is None:
            continue
        found = False
        # Search DLL in all given DLL directories.
        for search_path in args.dlldir:
            fullpath = os.path.join(search_path, name)
            if not os.path.exists(fullpath):
                continue
            print(fullpath)
            analyzed_deps = find_dependencies(args, fullpath, analyzed_deps)
            found = True
            break
        if not found:
            # Not found, maybe system DLL. Skip it.
            if args.verbose:
                print(f'skip {name} (not found, maybe system DLL)')

    return analyzed_deps

def main():
    """
    Command-line interface for universal dependency scanner.
    """

    parser = argparse.ArgumentParser(description='List required DLL dependencies for a set of given Windows binaries (executables, libraries, ...).')
    parser.add_argument('files', nargs='*', metavar='FILE', help='paths to executable or library files')
    parser.add_argument('--verbose', action='store_true', help='enable verbose output')
    parser.add_argument('--dlldir', action='append', metavar='DIRNAME', help='directory to search for DLLs (may be given more than once)')

    args = parser.parse_args()

    # try:
    # Find dependencies
    analyzed_deps = set()
    for binary in args.files:
        if True:
            analyzed_deps = find_dependencies(args, binary, analyzed_deps)
        # except:
        #    print(f'error: failed to find dependencies for {binary}')


if __name__ == '__main__':
    main()
