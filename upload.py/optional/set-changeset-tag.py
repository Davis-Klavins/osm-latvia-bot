#!/usr/bin/env python3
# vim: fileencoding=utf-8 encoding=utf-8 et sw=4

# Modified by Dāvis Kļaviņš (https://github.com/Davis-Klavins) on December 20, 2024. Included ssl lib, converted to Python 3.

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
Set a tag on an open changeset
"""

__version__ = "$Revision: 21 $"

import os
import subprocess
import sys
import traceback
import codecs
import locale

import http.client

import xml.etree.cElementTree as ElementTree
import urllib.parse

import ssl
ssl._create_default_https_context = ssl._create_unverified_context

import locale, codecs
try:
    locale.setlocale(locale.LC_ALL, "eng_usa")
    encoding = locale.getlocale()[1]
    sys.stdout = codecs.getwriter(encoding)(sys.stdout, errors = "replace")
    sys.stderr = codecs.getwriter(encoding)(sys.stderr, errors = "replace")
except locale.Error:
    pass

class HTTPError(Exception):
    pass

class OSM_API(object):
    url = 'https://api.openstreetmap.org/'
    def __init__(self, username = None, password = None):
        if username and password:
            self.username = username
            self.password = password
        else:
            self.username = ""
            self.password = ""
        self.changeset = None
        self.tags = {}
        self.progress_msg = None

    def __del__(self):
        #if self.changeset is not None:
        #    self.close_changeset()
        pass

    def msg(self, mesg):
        sys.stderr.write("\r%s…                        " % (self.progress_msg))
        sys.stderr.write("\r%s… %s" % (self.progress_msg, mesg))
        sys.stderr.flush()

    def request(self, conn, method, url, body, headers, progress):
        if progress:
            self.msg("making request")
            conn.putrequest(method, url)
            self.msg("sending headers")
            if body:
                conn.putheader('Content-Length', str(len(body)))
            for hdr, value in headers.items():
                conn.putheader(hdr, value)
            self.msg("end of headers")
            conn.endheaders()
            self.msg(" 0%")
            if body:
                start = 0
                size = len(body)
                chunk = size / 100
                if chunk < 16384:
                    chunk = 16384
                while start < size:
                    end = min(size, start + chunk)
                    conn.send(body[start:end])
                    start = end
                    self.msg("%2i%%" % (start * 100 / size))
        else:
            self.msg(" ")
            conn.request(method, url, body, headers)

    def _run_request(self, method, url, body = None, progress = 0, content_type = "text/xml"):
        url = urllib.parse.urljoin(self.url, url)
        purl = urllib.parse.urlparse(url)
        if purl.scheme != "https":
            raise ValueError("Unsupported url scheme: %r" % (purl.scheme,))
        if ":" in purl.netloc:
            host, port = purl.netloc.split(":", 1)
            port = int(port)
        else:
            host = purl.netloc
            port = None
        url = purl.path
        if purl.query:
            url += "?" + query
        headers = {}
        if body:
            headers["Content-Type"] = content_type

        try_no_auth = 0

        if not try_no_auth and not self.username:
            raise HTTPError("Need a username")

        try:
            self.msg("connecting")
            conn = http.client.HTTPSConnection(host, port)
#            conn.set_debuglevel(10)

            if try_no_auth:
                self.request(conn, method, url, body, headers, progress)
                self.msg("waiting for status")
                response = conn.getresponse()

            if not try_no_auth or (response.status == http.client.UNAUTHORIZED and
                    self.username):
                if try_no_auth:
                    conn.close()
                    self.msg("re-connecting")
                    conn = http.client.HTTPSConnection(host, port)
#                    conn.set_debuglevel(10)

                creds = self.username + ":" + self.password
                headers["Authorization"] = "Basic " + \
                        creds.encode("base64").strip()
                self.request(conn, method, url, body, headers, progress)
                self.msg("waiting for status")
                response = conn.getresponse()

            if response.status == http.client.OK:
                self.msg("reading response")
                sys.stderr.flush()
                response_body = response.read()
            else:
                raise HTTPError( "%02i: %s (%s)" % (response.status,
                        response.reason, response.read()))
        finally:
            conn.close()
        return response_body

    def get_changeset_tags(self):
        if self.changeset is None:
            raise RuntimeError("Changeset not opened")
        self.progress_msg = "Getting changeset tags"
        self.msg("")
        reply = self._run_request("GET", "/api/0.6/changeset/" +
                str(self.changeset), None)
        root = ElementTree.XML(reply)
        if root.tag != "osm" or root[0].tag != "changeset":
            print("API returned unexpected XML!", file=sys.stderr)
            sys.exit(1)

        for element in root[0]:
            if element.tag == "tag" and "k" in element.attrib and \
                    "v" in element.attrib:
                self.tags[element.attrib["k"]] = element.attrib["v"]

        self.msg("done.")
        print("", file=sys.stderr)

    def set_changeset_tags(self):
        self.progress_msg = "Setting new changeset tags"
        self.msg("")

        root = ElementTree.Element("osm")
        tree = ElementTree.ElementTree(root)
        element = ElementTree.SubElement(root, "changeset")
        for key in self.tags:
            ElementTree.SubElement(element, "tag",
                    { "k": key, "v": self.tags[key] })

        self._run_request("PUT", "/api/0.6/changeset/" +
                str(self.changeset), ElementTree.tostring(root, "utf-8"))

        self.msg("done, too.")
        print("", file=sys.stderr)

try:
    this_dir = os.path.dirname(__file__)
    try:
        version = int(subprocess.Popen(["svnversion", this_dir], stdout = subprocess.PIPE).communicate()[0].strip())
    except:
        version = 1
    if len(sys.argv) < 3 or (len(sys.argv) & 2):
        print("Synopsis:", file=sys.stderr)
        print("    %s <changeset> <key> <value> [...]", file=sys.stderr)
        sys.exit(1)

    args = []
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
        else:
            args.append(arg)

    if 'user' in param:
        login = param['user']
    else:
        login = input("OSM login: ")
    if not login:
        sys.exit(1)
    if 'pass' in param:
        password = param['pass']
    else:
        password = input("OSM password: ")
    if not password:
        sys.exit(1)

    api = OSM_API(login, password)
    api.changeset = int(args[0])

    api.get_changeset_tags()
    api.tags.update(list(zip(args[1::2], args[2::2])))
    api.set_changeset_tags()
except HTTPError as err:
    print(err, file=sys.stderr)
    sys.exit(1)
except Exception as err:
    print(repr(err), file=sys.stderr)
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
