#!/bin/bash

# This script provides a menu based selection to perform actions during a demo
# run locally from a laptop
#
# version: 0.1
# date: 10 June 2019

#######################
#       GLOBALS       #
#######################

#######################
#      FUNCTIONS      #
#######################

terraformdemo() {
    echo "this would start terraform demo"
    read -rsn1 -p "Press any key to return to main menu..."
}

vaultdemo() {
    ./vaultdemo.sh
    #read -rsn1 -p "Press any key to return to main menu..."
}

quit() {
    clear
    exit
}

#######################
#        MAIN         #
#######################

# Clear the screen to start fresh
clear

while [[ $INPUT != [Qq] ]]; do
    clear
    echo "# DOPR #"
    echo "--------"
    echo ""
    echo "Welcome to Demo Operations Plan Response"
    echo "Select Demo Environment:"
    echo ""
    echo "1) Terraform"
    echo "2) Vault"
    echo "Q) Quit DOPR"
    echo ""
    echo "Enter selection and hit return..."
    read INPUT

    case $INPUT in
    1)
        terraformdemo
        ;;
    2)
        vaultdemo
        ;;
    Q | q)
        quit
        ;;
    esac

done
