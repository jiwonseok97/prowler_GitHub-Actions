# Vagrantfile - Prowler + Security Control Plane (Ubuntu 22.04)
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # =========================
  # 1) Prowler VM (Scanner)
  # =========================
  config.vm.define "prowler-vm" do |prowler|
    prowler.vm.hostname = "prowler-vm"
    prowler.vm.network "private_network", ip: "192.168.56.50"

    prowler.vm.provider "virtualbox" do |vb|
      vb.name = "prowler-vm1"
      vb.memory = 4096
      vb.cpus = 2
    end

    prowler.vm.provision "shell", inline: <<-SHELL
      set -e

      echo "[1/6] apt update & packages"
      sudo apt-get update -y
      sudo apt-get install -y \
        ca-certificates curl gnupg lsb-release unzip jq git \
        python3 python3-pip pipx

      echo "[2/6] Docker install"
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

      sudo apt-get update -y
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo usermod -aG docker vagrant || true
      sudo systemctl enable --now docker

      echo "[3/6] AWS CLI v2 install"
      curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install --update || true
      rm -rf /tmp/aws /tmp/awscliv2.zip

      echo "[4/6] pipx PATH & Prowler install (CLI)"
      pipx ensurepath || true
      if ! grep -q 'PIPX_BIN_DIR' /home/vagrant/.bashrc; then
        echo 'export PATH="$PATH:/home/vagrant/.local/bin"' >> /home/vagrant/.bashrc
      fi
      sudo -u vagrant /usr/bin/pipx install prowler || true
      sudo -u vagrant /usr/bin/pipx upgrade prowler || true

      echo "[5/6] (Optional) Prowler Docker image pull"
      sudo docker pull toniblyx/prowler:latest || true

      echo "[6/6] Prowler VM ready"
    SHELL
  end

  # ==================================
  # 2) Security Control Plane (MCP)
  # ==================================
  config.vm.define "sec-control-plane" do |scp|
    scp.vm.hostname = "sec-control-plane"
    scp.vm.network "private_network", ip: "192.168.56.51"

    scp.vm.provider "virtualbox" do |vb|
      vb.name = "sec-control-plane"
      vb.memory = 4096
      vb.cpus = 2
    end

    scp.vm.provision "shell", inline: <<-SHELL
      set -e

      echo "[1/5] apt update & base packages"
      sudo apt-get update -y
      sudo apt-get install -y \
        ca-certificates curl jq git \
        python3 python3-pip python3-venv

      echo "[2/5] Python virtualenv for MCP"
      python3 -m venv /opt/mcp
      /opt/mcp/bin/pip install --upgrade pip

      echo "[3/5] MCP dependencies"
      /opt/mcp/bin/pip install pyyaml rich tabulate

      echo "[4/5] Directory structure"
      sudo mkdir -p /opt/mcp/{scripts,policies,mappings,runbooks,output}
      sudo chown -R vagrant:vagrant /opt/mcp

      echo "[5/5] Help message"
      cat <<'EOF'

✅ Security Control Plane ready!

- MCP virtualenv:
  source /opt/mcp/bin/activate

- Recommended structure:
  /opt/mcp/
    ├─ scripts/        # mcp_analyzer.py
    ├─ policies/       # automation-policy.yaml
    ├─ mappings/       # aws_refs.yaml
    ├─ runbooks/       # runbook md files
    └─ output/         # reports from prowler

- Typical flow:
  1) prowler-vm → scan → JSON/OCSF
  2) scp pulls results (scp/rsync or /vagrant)
  3) mcp_analyzer.py → report / priority / plan

EOF
    SHELL
  end
end
