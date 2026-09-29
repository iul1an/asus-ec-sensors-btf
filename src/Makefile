# SPDX-License-Identifier: GPL-2.0
ifneq ($(KERNELRELEASE),)
obj-m := asus-ec-sensors-btf.o
else
KDIR ?= /usr/lib/modules/$(shell uname -r)/build

modules:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
endif
