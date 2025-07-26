#!/usr/bin/env bash
#######################################################
# Install and run a K3s cluster by a selected method:
#
# - Service method:
#   Run a K3s cluster as a persistent 
#   systemd service (k3s.service) 
#
# - Binary method:
#   Run a K3s cluster as a terminal session 
#   (a blocking process)
#   This method is of limited use; 
#   for quick (session-long) tests and such
#
# ARG: service | binary 
#######################################################
[[ $1 ]] || {
    echo 'ARG: service | binary'
    exit
}

[[ $(type -t jq) ]] || {
    type -t apt && bin=apt
    type -t dnf && bin=dnf
    [[ $bin ]] ||
        exit 11

    sudo $bin install -y jq
}

# Fail if a K3s cluster is running
sudo k3s kubectl get node &&
    exit 12

# Get latest (stable) release id : https://github.com/k3s-io/k3s/releases
[[ $(type -t jq) ]] &&
    VERSION=$(curl -s https://api.github.com/repos/k3s-io/k3s/releases/latest |jq -Mr .tag_name)
# @ 2024-12 : v1.31.3+k3s1 
echo "$VERSION" |grep k3s ||
    exit 22

# Uninstall if install of version mismatch
[[ $(type -t k3s) ]] && {
    command k3s --version |grep $VERSION ||
        sudo bash k3s-uninstall.sh
}

service(){
    # See script (get.k3s.io) for list of parameters
    export INSTALL_K3S_VERSION=$VERSION
    exists=$(systemctl list-unit-files |grep k3s)
    status=$(systemctl is-active k3s.service)
    # Install service only if not exist
    [[ $exists ]] || {
        curl -sfL https://get.k3s.io |sh -
        sleep 5
    }
    # Enable/Start if needed
    [[ $exists && ("$status" != 'active') && $(type -t k3s) ]] &&
        sudo systemctl enable --now k3s.service && sleep 5

    # Verify cluster else fail
    [[ $exists && ("$status" == 'active') && $(type -t k3s) ]] &&
        sudo k3s kubectl get node || 
            return 44
}

binary(){
    bin=/usr/local/bin/k3s
    # Install k3s CLI if needed
    [[ $(type -t k3s) && $(k3s --version |grep $VERSION) ]] ||
        sudo curl -sSLo $bin https://github.com/k3s-io/k3s/releases/download/$VERSION/k3s &&
            sudo chown 0:0 $bin &&
                sudo chmod 0755 $bin ||
                    return 55

    # Init cluster : This blocks, so must run client from another shell.
    [[ $(type -t kx && kx |grep k3s) ]] ||
        sudo k3s server \
            --write-kubeconfig-mode "0644" \
            --cluster-init ||
                return 66
}

"$@" || echo "  ERR: $?"
