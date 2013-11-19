#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import subprocess
import sys,os

COMMAND_SUCCESS = 0
COMMAND_ERROR = 1024

def get_output(cmd):
    """Runs command described by lst and returns (output, returncode)."""
    try:
        child = subprocess.Popen(cmd, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
        output, _ = child.communicate()
        return (output.strip(), child.returncode)
    except OSError:
        return (None, COMMAND_ERROR)

def find_enclosing_dir(subpath):
    cur_dir = os.getcwd()
    while not os.path.exists(os.path.join(cur_dir, subpath)):
        cur_dir = os.path.abspath(os.path.join(cur_dir, ".."))
        if cur_dir == "/":
            return None
    return cur_dir

git_toplevel = None
git_dir = None
git_branch = None

def find_git_dir(repo_dir):
    gitpath = os.path.join(repo_dir, ".git")
    if os.path.isdir(gitpath):
        return gitpath
    with open(gitpath) as f:
        link = f.read().strip()[8:] # skip 'gitdir: '
        return os.path.join(repo_dir, link)

def git_status():
    global git_toplevel, git_dir, git_branch
    git_toplevel = find_enclosing_dir(".git")
    if git_toplevel is None:
        return [""]
    git_dir = find_git_dir(git_toplevel)
    desc = ""
    with open(os.path.join(git_dir, "HEAD")) as f:
        desc = f.read().strip()
        if desc.startswith("ref: "):
            desc = desc[5:]
            if desc.startswith("refs/heads/"):
                desc = desc[len("refs/heads/"):]
                git_branch = desc
        else:
            desc = desc[:8]
    return [" (g:%s)" % (desc,), " (git)", " (g)"]

def stg_status():
    if git_toplevel is None \
       or not os.path.isdir(os.path.join(git_dir, "patches")):
        return [""]
    patch = "-"
    if not git_branch is None:
        try:
            with open(os.path.join(git_dir, "patches",
                                   git_branch.replace("/", os.path.sep),
                                   "applied")) as f:
                for line in f:
                    patch = line.strip()
        except:
            return [""]
    return [" (s:%s)" % (patch,), " (stg)", " (s)"]

def hg_status():
    toplevel = find_enclosing_dir(".hg")
    if toplevel is None:
        return [""]

    branch = ""
    branch_path = os.path.join(toplevel, ".hg", "branch")
    # This path may not exist, if we're on the default branch.
    if os.path.exists(branch_path):
        with open(branch_path) as f:
            branch = f.read().strip()
        # Don't list default branch, it's not useful.
        if branch == "default":
            branch = ""
    bookmark = ""
    bookmark_path = os.path.join(toplevel, ".hg", "bookmarks.current")
    if os.path.exists(bookmark_path):
        with open(bookmark_path) as f:
            bookmark = f.read().strip()
            if bookmark and bookmark != "@":
                bookmark = "@" + bookmark
    mqpatch = ""
    if os.path.exists(os.path.join(toplevel, ".hg", "patches", "series")):
        # There is a patch series here. Indicate this with `#'.
        mqpatch = "#"
        # Try to see if there is anything applied. If such is the case, report
        # the top applied patch. We're not handling any guards though, as there
        # might be any number of those.
        patch_name = ""
        with open(os.path.join(toplevel, ".hg", "patches", "status")) as f:
            for line in f:
                patch_name = line.split(":")[1].strip()
        mqpatch += patch_name
    return [" (hg:%s%s%s)" % (branch, bookmark, mqpatch), " (hg)", " (h)"]

def last_dir(path):
    if path[-1:] == os.path.sep:
        path = path[:-1]
    return os.path.basename(path)

def bzr_nick(repo_dir):
    """Faster version of bzr nick that will describe a branch."""
    branch_conf_path = os.path.join(repo_dir, ".bzr", "branch", "branch.conf")
    if not os.path.exists(branch_conf_path):
        # Not bazaar repo or a shared repository. Use directory basename.
        return last_dir(repo_dir)
    with open(branch_conf_path) as conf:
        for line in conf:
            if line.startswith("nickname "):
                return line.split('=')[1].strip()
    return last_dir(repo_dir)

def bzr_status():
    toplevel = find_enclosing_dir(".bzr")
    if toplevel is None:
        return [""]
    nick = bzr_nick(toplevel)
    return [" (bzr:%s)" % (nick,), " (bzr)", " (b)"]

checkers = [git_status, stg_status, hg_status, bzr_status]
colours  = ["$GIT_COLOUR", "$STG_COLOUR", "$HG_COLOUR", "$BZR_COLOUR"]

def choose_options(lst, max_width):
    idx = 0
    desc = "".join([l[0] for l in lst])
    while len(desc) > max_width:
        while idx < len(lst) and len(lst[idx]) < 2:
            idx += 1
        if idx >= len(lst):
            break
        lst[idx].pop(0)
        desc = "".join([l[0] for l in lst])

def build_description(max_width):
    status_info = [f() for f in checkers]
    choose_options(status_info, max_width)
    raw = "".join([i[0] for i in status_info])
    decorated = "".join(["%s%s" % (colour, i[0]) for colour, i in zip(colours, status_info)])
    if not raw:
        # Both fields should have at least a space for easier shell processing
        raw = " "
        decorated = " "
    return (raw, decorated)

if __name__ == "__main__":
    max_width = 80
    if len(sys.argv) > 1:
        max_width = int(sys.argv[1])
    print("%s\t%s" % build_description(max_width))
