PKG_NAME    := spamhaus-drop-nftables
SCRIPT      := $(PKG_NAME).sh
SERVICE     := $(PKG_NAME).service
TIMER       := $(PKG_NAME).timer

# Paths
PREFIX      ?= /usr/local
BINDIR      = $(DESTDIR)$(PREFIX)/sbin
SYSTEMDDIR  = $(DESTDIR)/etc/systemd/system
INSTALL     := install -p

.PHONY: all install uninstall check-root

all:
	@echo "Usage:"
	@echo "  sudo make install    - Install and start timer"
	@echo "  sudo make uninstall  - Remove all files and stop services"

check-root:
	@if [ "$$(id -u)" -ne 0 ]; then echo "Error: Run as root"; exit 1; fi

install: check-root
	$(INSTALL) -d $(BINDIR) $(SYSTEMDDIR)
	$(INSTALL) -m 755 $(SCRIPT) $(BINDIR)/$(SCRIPT)
	$(INSTALL) -m 644 $(SERVICE) $(SYSTEMDDIR)/$(SERVICE)
	$(INSTALL) -m 644 $(TIMER) $(SYSTEMDDIR)/$(TIMER)
ifeq ($(DESTDIR),)
	systemctl daemon-reload
	systemctl enable --now $(TIMER)
	systemctl enable $(SERVICE)
endif

uninstall: check-root
ifeq ($(DESTDIR),)
	systemctl disable --now $(TIMER) 2>/dev/null || true
	systemctl disable --now $(SERVICE) 2>/dev/null || true
endif
	rm -f $(BINDIR)/$(SCRIPT) $(SYSTEMDDIR)/$(SERVICE) $(SYSTEMDDIR)/$(TIMER)
ifeq ($(DESTDIR),)
	systemctl daemon-reload
	systemctl reset-failed
endif
