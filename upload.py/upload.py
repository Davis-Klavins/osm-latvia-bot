#!/usr/bin/env python3

# Modified by Dāvis Kļaviņš (https://github.com/Davis-Klavins) on July 14, 2024.

# Copyright (C) 2009 Jacek Konieczny <jajcus@jajcus.net>
# Copyright (C) 2009 Andrzej Zaborowski <balrogg@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


"""
Uploads complete osmChange 0.3 files.  Use your login (not email) as username.
"""

__version__ = "$Revision: 21 $"

import os
import sys
import traceback
import codecs
import xml.etree.cElementTree as ElementTree
from osmapi import HTTPError, OSM_API

try:
    version = 2
    if len(sys.argv) < 2:
        sys.stderr.write("Synopsis:\n")
        sys.stderr.write("    %s <file-name.osc> [<file-name.osc>...]\n" % (sys.argv[0],))
        sys.exit(1)

    filenames = []
    param = {}
    num = 0
    skip = 0
    for arg in sys.argv[1:]:
        num += 1
        if skip:
            skip -= 1
            continue

        if arg == "-u":
            param['user'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-p":
            param['pass'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-c":
            param['confirm'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-m":
            param['comment'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-s":
            param['changeset'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-n":
            param['start'] = 1
            skip = 0
        elif arg == "-t":
            param['try'] = 1
            skip = 0
        elif arg == "-x":
            param['created_by'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-y":
            param['source'] = sys.argv[num + 1]
            skip = 1
        elif arg == "-z":
            param['url'] = sys.argv[num + 1]
            skip = 1
        else:
            filenames.append(arg)

    api = OSM_API()

    changes = []
    for filename in filenames:
        if not os.path.exists(filename):
            sys.stderr.write("File %r doesn't exist!\n" % (filename,))
            sys.exit(1)
        if 'start' not in param:
            # Should still check validity, but let's save time

            tree = ElementTree.parse(filename)
            root = tree.getroot()
            if root.tag != "osmChange" or (root.attrib.get("version") != "0.3" and
                    root.attrib.get("version") != "0.6"):
                sys.stderr.write("File %s is not a v0.3 osmChange file!\n" % (filename,))
                sys.exit(1)

        if filename.endswith(".osc"):
            diff_fn = filename[:-4] + ".diff.xml"
        else:
            diff_fn = filename + ".diff.xml"
        if os.path.exists(diff_fn):
            sys.stderr.write("Diff file %r already exists, delete it " \
                    "if you're sure you want to re-upload\n" % (diff_fn,))
            sys.exit(1)

        if filename.endswith(".osc"):
            comment_fn = filename[:-4] + ".comment"
        else:
            comment_fn = filename + ".comment"
        try:
            comment_file = codecs.open(comment_fn, "r", "utf-8")
            comment = comment_file.read().strip()
            comment_file.close()
        except IOError:
            comment = None
        if not comment:
            if 'comment' in param:
                comment = param['comment']
            else:
                comment = input("Your comment to %r: " % (filename,))
            if not comment:
                sys.exit(1)

        sys.stderr.write("     File: %r\n" % (filename,))
        sys.stderr.write("  Comment: %s\n" % (comment,))

        if 'confirm' in param:
            sure = param['confirm']
        else:
            sys.stderr.write("Are you sure you want to send these changes?")
            sure = input()
        if sure.lower() not in ("y", "yes"):
            sys.stderr.write("Skipping...\n\n")
            continue
        sys.stderr.write("\n")
        created_by = param.get("created_by", "osm-bulk-upload/upload.py v. %s" % (version,))
        source = param.get("source", "survey")
        url = param.get("url", "")
        if 'changeset' in param:
            api.changeset = int(param['changeset'])
        else:
            api.create_changeset(created_by, comment, source, url)
            if 'start' in param:
                print(api.changeset)
                sys.exit(0)
        while 1:
            try:
                diff = api.upload(root)
                with open(diff_fn, 'w') as diff_file:
                    diff_file.write(diff)
            except HTTPError as e:
                sys.stderr.write("\n" + e.args[1] + "\n")
                if e.args[0] in [404, 409, 412]:  # Merge conflict
                    # TODO: also unlink when not the whole file has been uploaded
                    # because then likely the server will not be able to parse
                    # it and nothing gets committed
                    if os.path.exists(diff_fn):
                        os.unlink(diff_fn)
                errstr = e.args[2]
                if 'try' in param and e.args[0] == 409 and \
                        errstr.find("Version mismatch") > -1:
                    id = errstr.split(" ")[-1]
                    found = 0
                    for oper in root:
                        todel = []
                        for elem in oper:
                            if elem.attrib.get("id") != id:
                                continue
                            todel.append(elem)
                            found = 1
                        for elem in todel:
                            oper.remove(elem)
                    if not found:
                        sys.stderr.write("\nElement " + id + " not found\n")
                        if 'changeset' not in param:
                            api.close_changeset()
                        sys.exit(1)
                    sys.stderr.write("\nRetrying upload without element " +
                            id + "\n")
                    continue
                if 'try' in param and e.args[0] == 400 and \
                        errstr.find("Placeholder Way not found") > -1:
                    id = errstr.replace(".", "").split(" ")[-1]
                    found = 0
                    for oper in root:
                        todel = []
                        for elem in oper:
                            if elem.attrib.get("id") != id:
                                continue
                            todel.append(elem)
                            found = 1
                        for elem in todel:
                            oper.remove(elem)
                    if not found:
                        sys.stderr.write("\nElement " + id + " not found\n")
                        if 'changeset' not in param:
                            api.close_changeset()
                        sys.exit(1)
                    sys.stderr.write("\nRetrying upload without element " +
                            id + "\n")
                    continue
                if 'try' in param and e.args[0] == 412 and \
                        errstr.find(" requires ") > -1:
                    idlist = errstr.split("id in (")[1].split(")")[0].split(",")
                    found = 0
                    delids = []
                    for oper in root:
                        todel = []
                        for elem in oper:
                            for nd in elem:
                                if nd.tag not in [ "nd", "member" ]:
                                    continue
                                if nd.attrib.get("ref") not in idlist:
                                    continue
                                found = 1
                                delids.append(elem.attrib.get("id"))
                                todel.append(elem)
                                break
                        for elem in todel:
                            oper.remove(elem)
                    if not found:
                        sys.stderr.write("\nElement " + str(idlist) +
                                " not found\n")
                        if 'changeset' not in param:
                            api.close_changeset()
                        sys.exit(1)
                    sys.stderr.write("\nRetrying upload without elements " +
                            str(delids) + "\n")
                    continue
                if 'changeset' not in param:
                    api.close_changeset()
                sys.exit(1)
            break
        if 'changeset' not in param:
            api.close_changeset()
except HTTPError as err:
    sys.stderr.write(err.args[1])
    sys.exit(1)
except Exception as err:
    sys.stderr.write(repr(err) + "\n")
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
