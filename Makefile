SCRIPT_NAME = spamhaus-drop-nftables.sh
SERVICE_NAME = spamhaus-drop-nftables.service
TIMER_NAME = spamhaus-drop-nftables.timer

SCRIPT_INSTALL_DIR = /usr/local/sbin
SYSTEMD_INSTALL_DIR = /etc/systemd/system

all:
	@echo "Use 'make install' to install the files."
	@echo "Use 'make uninstall' to remove the files."

install: $(SCRIPT_NAME) $(SERVICE_NAME) $(TIMER_NAME)
	@echo "Installing script and systemd units..."

	# 1. Install the script and make it executable
	sudo install -m 755 $(SCRIPT_NAME) $(SCRIPT_INSTALL_DIR)
	@echo "Installed $(SCRIPT_NAME) to $(SCRIPT_INSTALL_DIR)"

	# 2. Install the systemd service and timer files
	sudo install -m 644 $(SERVICE_NAME) $(SYSTEMD_INSTALL_DIR)
	sudo install -m 644 $(TIMER_NAME) $(SYSTEMD_INSTALL_DIR)
	@echo "Installed systemd units to $(SYSTEMD_INSTALL_DIR)"

	# 3. Reload the systemd daemon to pick up new files
	sudo systemctl daemon-reload
	@echo "Systemd daemon reloaded."

	# 4. Enable and start the service
	sudo systemctl enable --now $(SERVICE_NAME)
	@echo "Enabled and started $(SERVICE_NAME)."

	# 5. Enable and start the timer
	sudo systemctl enable --now $(TIMER_NAME)
	@echo "Enabled and started $(TIMER_NAME)."

uninstall:
	@echo "Uninstalling script and systemd units..."

	# 1. Stop and disable systemd units first
	sudo systemctl stop $(TIMER_NAME) || true
	sudo systemctl disable $(TIMER_NAME) || true
	sudo systemctl stop $(SERVICE_NAME) || true
	sudo systemctl disable $(SERVICE_NAME) || true
	
	# 2. Remove files
	sudo rm -f $(SCRIPT_INSTALL_DIR)/$(SCRIPT_NAME)
	sudo rm -f $(SYSTEMD_INSTALL_DIR)/$(SERVICE_NAME)
	sudo rm -f $(SYSTEMD_INSTALL_DIR)/$(TIMER_NAME)

	# 3. Reload systemd daemon
	sudo systemctl daemon-reload
	sudo systemctl reset-failed
	@echo "Uninstallation complete."

.PHONY: all install uninstall

