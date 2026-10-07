# SPDX-License-Identifier: GPL-2.0
KDIR ?= /usr/lib/modules/$(shell uname -r)/build
KVER ?= $(shell uname -r | sed 's/-.*//')
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

# Compare the upstream copy with the kernel's own file at v$(KVER); a
# difference means the fork needs a rebase. Linux x.y.0 is tagged vx.y.
drift:
	@tag=v$$(echo '$(KVER)' | sed -E 's/^([0-9]+\.[0-9]+)\.0$$/\1/'); \
	tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
	if ! curl -fsSL --max-time 60 -o "$$tmp" \
		https://raw.githubusercontent.com/gregkh/linux/$$tag/drivers/hwmon/asus-ec-sensors.c; then \
		echo "drift: cannot fetch the driver at Linux $$tag (no such tag, or no network)" >&2; \
		exit 2; \
	fi; \
	if cmp -s upstream/asus-ec-sensors.c "$$tmp"; then \
		echo "upstream/asus-ec-sensors.c matches Linux $$tag"; \
	else \
		diff -u --label upstream/asus-ec-sensors.c --label "Linux $$tag" \
			upstream/asus-ec-sensors.c "$$tmp"; \
		echo "drift: the in-tree driver changed in Linux $$tag; rebase the fork (re-import upstream/, re-apply the patch)" >&2; \
		exit 1; \
	fi

.PHONY: modules clean patch checkpatch package drift
