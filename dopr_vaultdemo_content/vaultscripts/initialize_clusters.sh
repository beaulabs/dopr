#!/usr/bin/env bash

# This script is to be used in conjunction with the Dopr Vault demo. It will run post
# "docker-compose up" to initialize and configure the containers with the appropriate
# settings.

# Version: 1.0
# Date: 28 Aug 2019

#######################
#      FUNCTIONS      #
#######################

########################
#   Configure Consul   #
########################

# This function loops through the Consul servers and starts Consul services

configure_consul() {

    echo "Starting up Consul server $KEY"
    docker exec -d $KEY opt/shared/containerbuild/configure_consul.sh
    docker top $KEY | grep consul
    if [[ $? == 0 ]]; then
        echo "Consul on $KEY successfully started..."
    else
        echo "$KEY Error: Consul did not successfully start..."
    fi

}

#######################
#   Configure Vault   #
#######################

# This function loops through the Vault servers and starts Vault services

configure_vault() {

    echo "Starting up Vault server $KEY"
    docker exec -d $KEY opt/shared/containerbuild/configure_vault.sh
    docker top $KEY | grep vault
    if [[ $? == 0 ]]; then
        echo "Vault on $KEY successfully started..."
    else
        echo "$KEY Error: Vault did not successfully start..."
    fi

}

########################
#   Initialize Vault   #
########################

# When running Vault clusters in HA, only the primary server nodes need to be initialized. We set this early with the VC1 VC2 variables in MAIN
# and when looping, only call those two servers.

initialize_vault() {

    echo "Initializing Vault primary node in clusters for use..."
    echo "curl -s --request POST --data @./config/vc_init_payload.json https://localhost:${servers[$KEY]}/v1/sys/init | jq"
    curl -s --request POST --data @./config/vc_init_payload.json https://localhost:${servers[$KEY]}/v1/sys/init | jq | tee ./config/data/$KEY.init >/dev/null 2>&1

}

####################
#   Unseal Vault   #
####################

# Unseal all Vault servers in clusters' 1 and 2. Applying Shamir keys appropriately per cluster membership. Why did I use 2 Shamir keys when
# one would have sufficed...mainly just for learning.

unseal_vault() {

    # Remember when running a cluster, only the primary needs to be initialized. It will propogate to other members.
    if [[ $KEY == vc1* ]]; then
        echo "Applying Shamir keys to unseal Vault cluster 1 primary server: $KEY"
        # Apply captured shamir keys to unseal Vault
        for i in {0..1}; do
            echo "curl --request PUT --data '{"key": "'"$(jq -r '.keys[\'$i\'] config/data/$VC1.init')"'"}' https://127.0.0.1:${servers[$KEY]}/v1/sys/unseal"
            curl -s --request PUT --data '{"key": "'"$(jq -r .keys[$i] config/data/vc1s1.init)"'"}' https://127.0.0.1:${servers[$KEY]}/v1/sys/unseal | jq >/dev/null 2>&1
        done
    else
        echo "Applying Shamir keys to unseal Vault cluster 2 primary server: $KEY"
        # Apply captured shamir keys to unseal Vault
        for i in {0..1}; do
            echo "curl --request PUT --data '{"key": "'"$(jq -r '.keys[\'$i\'] config/data/$VC2.init')"'"}' https://127.0.0.1:${servers[$KEY]}/v1/sys/unseal"
            curl -s --request PUT --data '{"key": "'"$(jq -r .keys[$i] config/data/vc2s1.init)"'"}' https://127.0.0.1:${servers[$KEY]}/v1/sys/unseal | jq >/dev/null 2>&1
        done
    fi

}

#####################
#   License Vault   #
#####################

# License the Vault instances across both cluster 1 and 2 to enable enterprise features. Remember when using HA, you use the root token
# of the primary Vault node in each cluster to access the other Vault members of that cluster.

license_vault() {

    if [[ $KEY == vc1* ]]; then
        echo "Licensing VC1 cluster member: $KEY"
        echo "curl -s --header \"X-Vault-Token: $(jq -r .root_token config/data/$VC1.init)\" --request PUT --data @./demofiles/licensepayload.json https://127.0.0.1:${servers[$KEY]}/v1/sys/license"
        curl --header "X-Vault-Token: $(jq -r .root_token config/data/$VC1.init)" --request PUT --data @./demofiles/licensepayload.json https://127.0.0.1:${servers[$KEY]}/v1/sys/license

    else
        echo "Licensing VC2 cluster member: $KEY"
        echo "--header "X-Vault-Token: $(jq -r .root_token config/data/$VC2.init)" --request PUT --data @./demofiles/licensepayload.json https://127.0.0.1:${servers[$KEY]}/v1/sys/license"
        curl --header "X-Vault-Token: $(jq -r .root_token config/data/$VC2.init)" --request PUT --data @./demofiles/licensepayload.json https://127.0.0.1:${servers[$KEY]}/v1/sys/license
    fi

}

#######################
#        MAIN         #
#######################

# Kick off the containers

clear
echo "STARTING VAULT CLUSTERS"
echo "--------------------------------------------------------------"
#cd ~/thelab/labapps/dopr/dopr_vaultdemo_content/
docker-compose -f ./containerbuild/docker-compose.yml up -d

# For demo purposes we are going to specifically tag 2 specific Vault servers to be the primary active in their respective clusters. Set them here for use.
export VC1=vc1s1
export VC2=vc2s1
touch ./config/data/clusterenv.sh
chmod 700 ./config/data/clusterenv.sh
echo "#!/bin/bash" >./config/data/clusterenv.sh
echo "export VC1="$VC1 >>./config/data/clusterenv.sh
echo "export VC2="$VC2 >>./config/data/clusterenv.sh

# Declare an associative array to read in both Vault and Consul hostnames and cooresponding ports for configuration
declare -A servers=()
while read -r a b; do servers["$a"]="$b"; done < <(docker ps --format="{{.Names}}: {{.Ports}}" | sort | awk -F ":|->" '{print $1, $3}')
for KEY in "${!servers[@]}"; do
    if [[ $KEY == c* ]]; then
        echo "Processing $KEY"
        configure_consul $KEY

    elif [[ $KEY == v* ]]; then
        echo "Processing $KEY"
        configure_vault $KEY
    else
        echo "No containers matched. Check with docker ps -format={{.Names}} to ensure containers are running."
    fi
done

#Due to Docker on Mac, insert a small delay to let the micro-vm spool up and let environment settle before looping through
#initialization of Vault servers just to keep this going. 7 seconds seems to be the magical number for both clusters to settle.
#It's 2:19 in the morning and I'm loopy writing this.
sleep 7
echo "Initializing, unsealing and licensing Vault servers"

for KEY in "${!servers[@]}"; do
    if [[ $KEY == $VC1 || $KEY == $VC2 ]]; then
        initialize_vault $KEY
    fi
done
sleep 5
# Loop through the Vault servers in each cluster and unseal based on cluster boundary.
for KEY in "${!servers[@]}"; do
    if [[ $KEY == v* ]]; then
        unseal_vault $KEY
    fi
done

for KEY in "${!servers[@]}"; do
    if [[ $KEY == v* ]]; then
        license_vault $KEY
    fi
done

# Write current container names and port numbers for reference if needed
docker ps --format="{{.Names}}: {{.Ports}}" | sort | awk '{print $1, $3}' >./config/data/serverlist.txt
clear
echo "Consul Clusters CC1 and CC2 have been successfully started."
echo ""
echo "Vault Clusters VC1 and VC2 have been successfully started, initialized and unsealed."
echo ""
echo "Root token for VC1 based Vaults: $(jq -r .root_token ./config/data/$VC1.init)"
echo "Root token for VC2 based Vaults: $(jq -r .root_token ./config/data/$VC2.init)"
echo ""
read -rsn1 -p "Demo paused - Press any key to continue..."

# LEGACY CODE LEFT FOR LEARNING/REFERENCE
# Find and load all containers running into array for processing
#echo "Starting Vault clusters..."
#Old method used mapfile array with just names - keeping legacy for learning and reference.
# mapfile -t < <(docker ps --format={{.Names}} | sort)

# Old looping method through containers and process configuration and start respective binary
# for i in "${MAPFILE[@]}"; do
#     if [[ $i == c* ]] || [[ $i == C* ]]; then
#         configure_consul $i
#     elif [[ $i == v* ]] || [[ $i == V* ]]; then
#         configure_vault $i
#     else
#         echo "No containers matched. Check with docker ps -format={{.Names}} to ensure containers are running."
#     fi
# done
# Command below filters just on vault servers - keeping for learning and reference.
# declare -A vaults=(); while read -r a b; do vaults["$a"]="$b"; done < <(docker ps --format="{{.Names}}: {{.Ports}}" | sort | awk -F ":|->" '/vc/ {print $1, $3}')
# END LEGACY CODE BLOCK
# --------------------------------------------------------------
