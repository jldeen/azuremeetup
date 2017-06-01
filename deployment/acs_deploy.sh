#!/bin/sh
#
# Run the create_vm_creds.sh script locally prior to running this file.

#outputs
outputs () {
    # Code to capture ACS master info
        master_fqdn=$(az acs show -n $Servicename -g $Resource | jq -r '.masterProfile | .fqdn')

    # Code to capture ACS agents info
        agents_fqdn=$(az acs show -n $Servicename -g $Resource | jq -r '.agentPoolProfiles[0].fqdn')

    # Set ssh connection string addt'l info
        admin_username=$(az acs show -n $Servicename -g $Resource | jq -r '.linuxProfile.adminUsername')

    # Print results 
        echo "------------------------------------------------------------------"
        echo "Important information:"
        echo 
        echo "SSH Connection String: ssh $admin_username@$master_fqdn -A -p 2200"
        echo "Master FQDN: $master_fqdn"
        echo "Agents FQDN: $agents_fqdn"
        echo "Your web applications can be viewed at $agents_fqdn."
        echo "------------------------------------------------------------------"
}

#login
    az login \
        --service-principal \
        -u $spn \
        -p $password \
        --tenant $tenant
        
# Group creation 
    if az group exists -n $Resource | grep -q "true"; then
        echo "The resource group '$Resource' already exists..."
        echo "Checking for existing ACS deployments..."
    else
        az group create \
            -l $Location \
            -n $Resource
        echo "Created Resource Group:" $Resource
    fi

# ACS Creation for Docker Swarm (--ssh-key-value | --generate-ssh-keys)
    if az acs show -n $Servicename -g $Resource | grep -q "agentPoolProfiles"; then
    echo "The Azure Container Service '$Servicename' in the '$Resource' resource group already exists..."
    echo
    outputs 
    exit 0;
    else
    echo "Beginning Azure Container Service creation now. Please note this can take more than 20 minutes to complete."
        az acs create \
            -g $Resource \
            -n $Servicename \
            -d $Dnsprefix \
            --orchestrator-type $Orchestrator \
            --ssh-key-value $sshkey \
            --verbose
        echo
        outputs
        exit 0;
    fi 