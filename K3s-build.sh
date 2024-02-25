#!/usr/local/bin/bash

set -o errexit
# set -o nounset
set -o xtrace
# set -o pipefail
trap 'exit_message' EXIT
# ******************************************************************

show_help() {
    echo ""
    echo "Usage: $0  -c node_count"
    }
# ******************************************************************

while getopts n:c: x
do
    case $x in
        n) cluster_name=$OPTARG;;
        c) node_count=$OPTARG;;
    esac
done
dummy=${cluster_name}:?"Missing -n option"`show_help`}
dummy=${node_count}:?"Missing -c option"`show_help`}

# ******************************************************************
# Print info about script, log, etc.
display_info() {

# Information variables
script_name="$0"
work_dir="`pwd`"
cur_time="`date +%d%m%Y_%H%M%S`"
log_file="$0_${cur_time}.log"
host="`hostname`"

  echo "******************************************************* " | tee ${log_file}
  echo "           StartTime : ${cur_time}"                 | tee -a ${log_file}
  echo "                Host : ${host} "                    | tee -a ${log_file}
  echo "         Working Dir : ${work_dir} "                | tee -a ${log_file}
  echo "              Script : ${script_name}"              | tee -a ${log_file}
  echo "            Log file : ${log_file} "                | tee -a ${log_file}
  echo "******************************************************* " | tee -a ${log_file}
  echo " " | tee -a ${log_file}
}

# ******************************************************************

exit_message() {

err=$?
artifacts_info
if [ ${err} -ne 0 ]; then
    echo "**** Error inside function ${artifacts_status} .." >>  ${artifacts_file}
    echo "Error occurred, Error Code: ${err}, please check ${log_file} for detail logs!!!" | tee -a ${log_file}
else
    echo "Cluster $cluster_name is created successfully." >> ${artifacts_file}
    echo "Run the following command to enable kubectl: export KUBECONFIG=$PWD/k3s.yaml"
fi
}

# *****************************************************************

artifacts_info() {

artifacts_file="cluster_build_info_${cur_time}.txt"

echo "******************************************************* "  > ${artifacts_file}
echo "                  Name : ${cluster_name}"                  >> ${artifacts_file}
echo "       Number of Nodes : ${node_count} "                   >> ${artifacts_file}
echo "******************************************************* "  >> ${artifacts_file}
echo " " >> ${artifacts_file}
echo "------------------------------------------------------- " >> ${artifacts_file}
echo "-> Processing request to build $cluster_name **** "       >> ${artifacts_file}
}

# ******************************************************************
initialize_var() {

artifacts_status="initialize_var"

INSTALL_K3S_NAME=${cluster_name}
PWD=$(pwd)

#declare -A IPS
}

# ******************************************************************
check_cluster_exists () {

artifacts_status="check_cluster_exists"

echo "...Checking if $cluster_name already exists..." 
cluster_check=$(multipass info ${cluster_name}1 | grep Name | awk '{print $2'})
echo "${cluster_check}"
if [[ -z "$cluster_check" ]]; then
	echo "${cluster_name} does not exist. Proceeding..." | tee -a ${log_file}
else
	echo "${cluster_name} already exists. You have done this task before; you just don't remember..." | tee -a ${log_file}
    for (( c=1; c<=${node_count}; c++ )); do
        echo "Destroying ${cluster_name}${c}..."
        multipass stop ${cluster_name}${c} | tee -a ${log_file}
        multipass delete ${cluster_name}${c} | tee -a ${log_file}
    done
    multipass purge | tee -a ${log_file}
	exit 99
fi
}

# ******************************************************************

build_nodes() {

artifacts_status="build_nodes"

echo "Building ${cluster_name} nodes..."
for (( c=1; c<=${node_count}; c++ )); do
    echo "Deploying ${cluster_name}${c}..."
    multipass launch -n ${cluster_name}${c} | tee -a ${log_file}
done
multipass list | tee -a ${log_file}
echo "...uninitialized nodes created!"
}

# ******************************************************************

initialize_K3s_nodes() {

artifacts_status="initialize_K3s_nodes"

echo "Initialize K3s on node1..."
multipass exec ${cluster_name}1 -- bash -c "curl https://releases.rancher.com/install-docker/19.03.sh | sh"
multipass exec ${cluster_name}1 -- bash -c "curl -sfL https://get.k3s.io | sh -s - --docker " | tee -a ${log_file}
echo "Node1 initialized..."
K3S_TOKEN=$(multipass exec ${cluster_name}1 sudo cat /var/lib/rancher/k3s/server/node-token)
NODE1_IP=$(multipass info ${cluster_name}1 | grep IPv4 | awk '{print $2}')
sleep 15s
for (( c=2; c<=${node_count}; c++ )); do
    echo "Initializing node${c} to cluster..."
    #echo "IPs of initialized nodes: $(for k in '${!IPS[@]}'; do echo -n '$k:'; echo '${IPS[$k]}'; done)"
    multipass exec ${cluster_name}${c} -- bash -c "curl https://releases.rancher.com/install-docker/19.03.sh | sh"
    multipass exec ${cluster_name}${c} -- bash -c "curl -sfL https://get.k3s.io | K3S_URL='https://${NODE1_IP}:6443' K3S_TOKEN='$K3S_TOKEN' sh -s - --docker" | tee -a ${log_file}
    sleep 15s
    echo "Node ${cluster_name}${c} initialized..."
done
multipass exec ${cluster_name}1 -- sudo kubectl get nodes | tee -a ${log_file}
echo "K3s cluster successfully initialized..."
}

# ******************************************************************

configure_kubeconfig() {

artifacts_status="configure_kubeconfig"

if [[ -f k3s.yaml ]]; then rm -f k3s.yaml; fi
multipass exec ${cluster_name}1 sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml
sed -i '' "s/127.0.0.1/${NODE1_IP}/" k3s.yaml
}

# ******************************************************************

####################################################
# Main() => Execution starts here..                #
####################################################

# Display information about host, script, workdir and logfile
display_info

# Initialize variables
initialize_var 

# Before proceeding further, run initial check that cluster does not exists
echo "-> Executing check_cluster_exists..." | tee -a ${log_file}
check_cluster_exists

# Launch new cluster nodes
echo "-> Executing build_nodes..." | tee -a ${log_file}
build_nodes

# Initialize new K3s cluster nodes
echo "-> Executing build_nodes..." | tee -a ${log_file}
initialize_K3s_nodes

# Setup local KUBCONFIG for cluster
echo "-> Executing configure_kubeconfig..." | tee -a ${log_file}
configure_kubeconfig

# Exit gracefully
exit 0