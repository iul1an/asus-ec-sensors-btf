# SPDX-License-Identifier: GPL-2.0
KDIR ?= /usr/lib/modules/$(shell uname -r)/build
PATCH := patch/0001-btf-gc-hpwr.patch

modules:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src clean

# Regenerate the patch from the untouched upstream copy and the fork.
patch:
	git diff --no-index --no-color \
		upstream/asus-ec-sensors.c src/asus-ec-sensors-btf.c > $(PATCH); \
		test $$? -eq 1

# The file keeps upstream's own findings; the patch goes in on stdin, since
# checkpatch reads a git-tracked path as source.
checkpatch:
	-$(KDIR)/scripts/checkpatch.pl --no-tree --strict -f src/asus-ec-sensors-btf.c
	$(KDIR)/scripts/checkpatch.pl --no-tree --strict --no-signoff - < $(PATCH)

# The Arch package, from this checkout; package() only copies files, so no
# dependency needs to be installed to build it.
package:
	cd arch && PKGDEST=$(CURDIR)/dist makepkg --force --nodeps

.PHONY: modules clean patch checkpatch package
