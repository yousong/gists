#!python
#
## reverse blocks of text in "vvv.txt" leading by " -> ".
#
# sample vvv.txt
#
# v1 -> v2
# 
#     - Use common option names as suggested by jow and nbd.
#     - Default to using ~/.ssh/id_{rsa,dsa} as the identity file.
#     - Set $HOME to correct value for the current user instead of unset it.
# 
# v2 -> v3
# 
#     - Change type of acceptunknown to boolean.
#     - Squeeze multiple calls to proto_config_add_string to one.
# 
# v3 -> v4
# 
#     - Use default identity files only when no explicit key files were
#       specified.
#     - Added a new option `ssh_options' which will be added as part of ssh
#       client options.
#     - Change the type of `port' option to int.
#     - Change the type of `identity` option to array type.
# 
# v4 -> v5
# 
#     - Remove `acceptunknown' option.  For dropbear client `-y' option can be
#       used, and for OpenSSH client it's '-o StrictHostKeyChecking xx'.  Both of
#       them can be specified through the `ssh_options'.
#     - Make variable `pty' local.
# 
# v5 -> v6
# 
#     - Specify 'localip:peerip' directly without `ippair' variable.
#
if __name__ == "__main__":
    with open("vvv.txt", "rb") as fin:
        lines = fin.readlines()

    g = []
    t = []
    for line in lines:
        if " -> " in line:
            g.append("".join(t))
            t = []
        t.append(line)
    g.append("".join(t))
    g.reverse()
    print "".join(g)
