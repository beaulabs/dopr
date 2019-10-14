#!/bin/bash

# This script provides a menu based selection to perform Vault actions during a demo
# run locally from a laptop
#
# NOTE: IF YOU UPLOAD THIS TO VCS ENSURE YOU HAVE SCRUBBED SENSITIVE DATA FROM THE
# SCRIPT YOU MAY HAVE DESIGNATED. EG - OKTATOKEN
#
# version: 0.1
# date: 10 June 2019

#######################
#   GLOBAL VARIABLES  #
#######################

# Set the type speed for automating appearance of typing command
export TYPE="pv -qL $((40))"
export PROMPT="$ "
export TCOLOR=$(tput setaf 11)
export OKTATOKEN="009Hfq3jcanYVwSwgp80aawUbzCev0LRWI-QlIJlWR"
export OKTAPASSWORD="VaultDemo1!"

#######################
#      FUNCTIONS      #
#######################

####################
#  Process Checks  #
####################

# This function performs checks to ensure Vault process(es) is/are running before executing demo action.

process_checks() {

    if grep -Fxq "$INPUT" config/data/trackruns.txt; then
        clear
        echo "This action has been already been run..."
        echo "Please select another demo action to perform."
        sleep 2
        menu
    fi

    # SINGLE VAULT - Check if we get an integer value for demo actions against a single vault instance and then run checks if Vault is running.
    if [[ $INPUT =~ ^[1-9]+$ ]]; then

        if grep -Fxq -e "f" -e "F" config/data/trackruns.txt; then
            clear
            echo "Vault fast set up has already been executed for testing and all"
            echo "demo actions applied. Please quit Vault process and restart for"
            echo "demo using \"Initialize Single Vault\" or \"Initialize Quick\" options."
            sleep 2
            menu

        elif [[ $INPUT -eq 1 ]]; then
            echo $INPUT >>config/data/trackruns.txt

        elif ! grep -Fxq -e "1" -e "i" -e "I" config/data/trackruns.txt; then
            clear
            echo "Vault single instance is not running. Please start Vault"
            echo "using \"Initialize Single Vault\" or \"Initialize Quick\" options."
            sleep 2
            menu
        else
            echo $INPUT >>config/data/trackruns.txt
        fi
    fi

    # CLUSTER VAULT - Check if we get a string letter value for demo actions against the Vault clusters and then run checks if cluster is running.
    if [[ $INPUT =~ ^[b-eB-E]+$ ]]; then
        if ! grep -Fxq -e "a" -e "A" config/data/trackruns.txt; then
            clear
            echo "Vault cluster is not running. Please start the cluster using"
            echo "\"Initialize Vault Clusters\" option."
            sleep 2
            menu
        else
            echo $INPUT >>config/data/trackruns.txt
        fi
    fi

    # OPERATOR TESTING OPTIONS - This is used to capture testing functions that require their own checks. Yes I could code all of this in a nested nested nested if
    # statement above, but that doesn't help me at the moment, and it's late...
    if [[ $INPUT =~ ^[fFiI]+$ ]]; then
        if ! grep -Fxq -e "1" -e "i" -e "I" -e "f" -e "F" config/data/trackruns.txt; then
            echo $INPUT >>config/data/trackruns.txt
        elif grep -Fxq -e "i" -e "I" config/data/trackruns.txt; then
            clear
            echo "You have requested a fast set up, however Vault has already been initialized."
            echo "Please quit existing Vault process."
            sleep 2
            menu
        elif grep -Fxq -e "f" -e "F" config/data/trackruns.txt; then
            clear
            echo "You have requested to initialize a quiet set up, however Vault has already been initialized."
            echo "Please quit existing Vault process."
            sleep 2
            menu
        elif grep -Fxq -e "1" config/data/trackruns.txt; then
            clear
            echo "Vault single instance is already running. Please quit this Vault process before"
            echo "attempting to start a new instance."
            sleep 2
            menu
        fi
        ###### FILL IN STATEMENT HERE TO CAPTURE IF FAST OR INITIALIZE QUIET HAS ALREADY BEEN RUN, OTHERWISE DEPENDENT UPON PROCESS CHECKS - maybe not a bad thing?

    fi

}

###################
#   Start Vault   #
###################

# This function sets up the complete demo environment (static, dynamic, transit etc) with step by step actions.
# Normally start with this method when itroducing customer who is new to Vault.

initialize_single() {

    ./vaultscripts/initialize_single.sh
    source ./vaultsingle/loadenv.sh
    menu

}

###################
#   Fast Start    #
###################

# This function sets up the complete demo environment (static, dynamic, transit etc) w/o the step by step.
# This allows you to quickly start the Vault instance to interactive with Vault or practice CLI/API commands.

initialize_fast() {

    ./vaultscripts/initialize_single_fast.sh
    source ./vaultsingle/loadenv.sh
    menu

}

#########################
#   Initialize Quiet    #
#########################

# This fucntion initializes Vault, unseals, licenses and exports VAULT_ADDR and VAULT_TOKEN (root)
# Should be used when you just want to start Vault to manually test w/o having any further configuration or setup run
# and/or do not want to pre-populate Vault with data for a demo.

initialize_quiet() {

    ./vaultscripts/initialize_single_quiet.sh
    source ./vaultsingle/loadenv.sh
    menu

}

###################
# Static  Secrets #
###################

enable_secrets() {

    ./vaultscripts/static_secrets.sh
    menu
}

###################
# Dynamic Secrets #
###################

enable_dyn_secrets_db() {

    ./vaultscripts/dynamic_secrets.sh
    menu
}

###################
#     Transit     #
###################

enable_transit() {

    ./vaultscripts/transit_secrets.sh
    menu

}

###################
#    User Pass    #
###################

enable_userpass() {

    ./vaultscripts/userpass.sh
    menu

}

###################
#   END TO END    #
###################

enable_endtoend() {

    ./vaultscripts/endtoend.sh
    menu

}

###################
#    Okta MFA     #
###################

enable_okta_mfa() {
    ./vaultscripts/okta_mfa.sh
    menu

}

###################
#   Namespaces    #
###################

enable_namespaces() {
    read -rsn1 -p "Press any key to return to menu..."
    menu

}

##########################
#   Password Rotation    #
##########################

###################
#    AWS Creds    #
###################

enable_aws_auth() {
    read -rsn1 -p "Press any key to return to menu..."
    menu

}

###################
#   Azure Creds   #
###################

enable_azure_auth() {
    read -rsn1 -p "Press any key to return to menu..."
    menu

}

##########################
#    Vault Clusters      #
##########################

# This function stands up 2 Vault clusters and 2 Consul clusters for backend storage in a containerized
# environment. This is used for a more advanced demo showing performance replication and mount filters.

initialize_clusters() {

    ./vaultscripts/initialize_clusters.sh
    source ./config/data/clusterenv.sh
    menu

}
###################
#   Root Token    #
###################

root_token() {
    clear
    if [[ ! -f vaultsingle/loadenv.sh && ! -f config/data/$VC1.init ]]; then
        echo "Currently no running Vault instance or clusters."
        echo "Please start a single Vault instance or clusters from main menu."
        echo ""
    fi

    if [[ -f vaultsingle/loadenv.sh ]]; then
        echo "Single Vault Instance Environment Variables:"
        echo "--------------------------------------------"
        echo "Root token is: $VAULT_TOKEN"
        echo "Vault address is: $VAULT_ADDR"
        echo "Vault process id is: $VPID"
        echo ""
    fi

    if [[ -f config/data/$VC1.init && -f config/data/$VC2.init ]]; then
        echo "Cluster Vault Primaries Environment Variables:"
        echo "----------------------------------------------"
        echo "Vault cluster 1 - Root token is: $(jq -r .root_token config/data/$VC1.init)"
        echo "Vault cluster 2 - Root token is: $(jq -r .root_token config/data/$VC2.init)"
    fi

    echo ""
    read -rsn1 -p "Press any key to return to menu..."
}

###################
#  Breakout CLI   #
###################

breakout() {
    clear
    if [[ -f vaultsingle/loadenv.sh ]]; then
        # Breakout of process without terminating Vault instance
        echo "Opening new terminal for manual interaction with Vault."
        #osascript -e "tell application \"Terminal\" to do script \"cd $(pwd); eval $(././vaultsingle/loadenv.sh); vault login $VAULT_TOKEN\""
        osascript -e "tell application \"Terminal\" to activate" -e "tell application \"Terminal\" to do script \"cd $(pwd); source ./vaultsingle/loadenv.sh; vault login $VAULT_TOKEN\"" >/dev/null 2>&1

    else
        echo "Single Vault instance not running."
        echo "Please start Vault instance from main menu before starting breakout terminal."
    fi
    sleep 2
}

###################
#      Quit       #
###################

quit() {
    clear
    echo "Termination requested..."
    echo -n "Checking for running Vault environments..."
    echo ""
    # Note, we don't use $VPID  here as it may not currently exist if user quits before starting a single instance.
    pgrep vault
    if [[ $? == 1 ]]; then
        echo "Single Vault instance was not running. Checking for clusters..."
        echo ""
    else
        echo "Terminating Vault and resetting demo environment."
        kill -9 $VPID
        # Once things are finalized and not in beta probably safe to just make it rm ./vaultsingle/*.*
        # Note the following files that are placed into the vaultsingle/ directory:
        # audit.log vault_stdout.txt loadenv.sh shamir.txt encrypt.txt decrypt.txt bunsentoken.txt dbwritecreds.txt dbreadcreds.txt ciphertext.txt base64.txt vault_variables.txt
        rm -R vaultsingle
        rm -R config/data
        psql -U bunsenhoneydew -h localhost -d labapp -c "DROP SCHEMA IF EXISTS thelab CASCADE"
        unset TYPE
        unset PROMPT
        unset TCOLOR
        unset OKTATOKEN
        unset OKTAPASSWORD
    fi
    cd ./containerbuild
    docker-compose ps | grep vc1s1 >/dev/null
    if [[ "$?" == 0 ]]; then
        echo ""
        echo "Found running Vault clusters...Terminating..."
        docker-compose down
        rm -R ../vaultcluster
        if [[ ! -d ../config/data ]]; then
            echo "Thank you for using DOPR. Returning you to parent menu."
            echo "Have a nice day!"
            sleep 2
        else
            rm -R ../config/data
            echo "Thank you for using DOPR. Returning you to parent menu."
            echo "Have a nice day!"
            sleep 2
        fi
    else
        rm -R ../vaultcluster
        echo ""
        echo "No Vault clusters running."
        echo "Thank you for using DOPR. Returning you to parent menu."
        echo "Have a nice day!"
        sleep 2
    fi
}

###################
#      Menu      #
###################

menu() {
    # Clear the screen to start fresh
    clear

    # Create required dependencies folders and file(s) for use during demo actions.
    mkdir vaultsingle
    mkdir vaultcluster
    mkdir config/data
    touch config/data/trackruns.txt
    while [[ $INPUT != [Qq] ]]; do
        clear
        echo "--------------------------"
        echo "Vault - Single Instance"
        echo "--------------------------"
        echo '1) Initialize Single Vault and License Environment with Auditing'
        echo '2) Run Static Secrets'
        echo '3) Run Dynamic Secrets - Database'
        echo '4) Run Transit - EaaS'
        echo '5) Run Enable User'
        echo '6) Run Enable Okta with push MFA'
        # echo  '?) Run Enable Namespaces'
        # echo '?) Run Password Rotation'
        # echo  '? Enable AWS Secrets'
        # echo  '?) Enable Azure Secrets'
        echo '7) Run Operational Use Demo - Database Operations With Transit'
        echo ""
        echo "--------------------------"
        echo "Vault - Clusters"
        echo "--------------------------"
        echo 'A) Initialize Vault Clusters with Consul Storage Backend'
        #echo 'B) Run Performance Replication'
        #echo 'C) Run Mount Filters'
        #echo 'D) Run Namespaces' (note do I really want to demo this here, or just in the single instance? maybe overkill for demo here?)
        echo ''
        echo "--------------------------"
        echo "Vault - Additional Options"
        echo "--------------------------"
        echo 'F) Fast Set Up - Run All Demo Actions / Bypass Step By Step'
        echo 'I) Initialize Quick - Start Vault Server / Bypass Step By Step'
        echo 'R) Show Root Token'
        echo 'B) Breakout - Open Terminal For CLI/API Use With Current Single Vault Session'
        echo 'Q) Quit'
        echo ""
        echo ""
        echo "Input:"
        read INPUT

        case $INPUT in
        1)
            process_checks
            initialize_single
            ;;
        2)
            process_checks
            enable_secrets
            ;;
        3)
            process_checks
            enable_dyn_secrets_db
            ;;
        4)
            process_checks
            enable_transit
            ;;
        5)
            process_checks
            enable_userpass
            ;;
        6)
            process_checks
            enable_okta_mfa
            ;;
        # placeholder)
        #     if ! grep -Fxq -e "1" -e "i" -e "I" -e "f" -e "F" config/data/trackruns.txt; then
        #         echo "Vault single instance is not running. Please start Vault."
        #         sleep 2
        #     else
        #         echo $INPUT >>config/data/trackruns.txt
        #         enable_namespaces
        #     fi
        #     ;;
        # placeholder)
        #     if ! grep -Fxq -e "1" -e "i" -e "I" -e "f" -e "F" config/data/trackruns.txt; then
        #         echo "Vault single instance is not running. Please start Vault."
        #         sleep 2
        #     else
        #         echo $INPUT >>config/data/trackruns.txt
        #         enable_aws_auth
        #     fi
        #     ;;
        # placeholder)
        #echo $INPUT >> config/data/trackruns.txt
        #enable_azure_auth
        # ;;
        7)
            process_checks
            enable_endtoend
            ;;
        A | a)
            process_checks
            initialize_clusters
            ;;
        F | f)
            process_checks
            initialize_fast
            ;;
        I | i)
            process_checks
            initialize_quiet
            ;;
        R | r)
            root_token
            ;;
        B | b)
            breakout
            ;;
        Q | q)
            quit
            ;;
        *)
            echo "Invalid selection. Please select from the available options."
            sleep 1
            ;;
        esac
        #fi
    done

}

#######################
#        MAIN         #
#######################

# Change to working directory - CHANGE THIS IF YOUR DIR STRUCTURE IS DIFFERENT
#cd /Users/beau/labs/beaulabs/mydemos/vault_examples/local_vault_instance
cd dopr_vaultdemo_content/

# Clear the screen to start fresh
clear

# Run main function
menu
