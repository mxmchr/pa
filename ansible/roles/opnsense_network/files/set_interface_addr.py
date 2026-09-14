#!/usr/bin/env python3
import json
import shutil
import sys
import time
import xml.etree.ElementTree as ET

CHANGED = 2


def main():
    if len(sys.argv) != 3:
        sys.stderr.write(__doc__)
        return 1

    path, wanted = sys.argv[1], json.loads(sys.argv[2])

    tree = ET.parse(path)
    interfaces = tree.getroot().find("interfaces")
    if interfaces is None:
        sys.stderr.write("bloc <interfaces> introuvable\n")
        return 1

    changes = []
    for ident, fields in sorted(wanted.items()):
        node = interfaces.find(ident)
        if node is None:
            sys.stderr.write(
                "interface %s absente : l'assignation doit passer avant\n" % ident)
            return 1

        for key, value in sorted(fields.items()):
            child = node.find(key)
            current = child.text if child is not None else None
            if (current or "") == str(value):
                continue
            if child is None:
                child = ET.SubElement(node, key)
            child.text = str(value)
            changes.append("%s.%s: %r -> %r" % (ident, key, current, value))

    if not changes:
        print("aucun changement")
        return 0

    shutil.copy2(path, "%s.bak-%d" % (path, int(time.time())))
    tree.write(path, encoding="UTF-8", xml_declaration=True)
    print("\n".join(changes))
    return CHANGED


if __name__ == "__main__":
    sys.exit(main())