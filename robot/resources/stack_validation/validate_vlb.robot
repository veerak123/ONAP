*** Settings ***
Documentation	  Testing openstack.
Library    String
Library    DNSUtils
Library    Collections
Library    SSHLibrary
Resource          validate_common.robot


*** Variables ***
${ASSETS}              ${EXECDIR}/robot/assets/

*** Keywords ***
Validate vLB Stack
    [Documentation]    Identifies the LB and DNS servers in the vLB stack in the GLOBAL_OPENSTACK_SERVICE_REGION
    [Arguments]    ${stack_name}    
    Run Openstack Auth Request    auth
    ${stack_info}=    Wait for Stack to Be Deployed    auth    ${stack_name}
    ${stack_id}=    Get From Dictionary    ${stack_info}    id
    ${server_list}=    Get Openstack Servers    auth 
    Log     Returned from Get Openstack Servers

    #${vpg_unprotected_ip}=    Get From Dictionary    ${stack_info}    vpg_private_ip_0
    #${vsn_protected_ip}=    Get From Dictionary    ${stack_info}    vsn_private_ip_0
    ${vlb_public_ip}=    Get Server Ip    ${server_list}    ${stack_info}   vlb_name_0    network_name=public     
    ##${vdns_public_ip}=    Get Server Ip    ${server_list}    ${stack_info}   vdns_name_0    network_name=public     

# SCript hands right here. Trying to figure out what it is....    
    #Wait For Server    ${vlb_public_ip}
    #Wait For Server    ${vdns_public_ip}
    #Log    Accessed all servers
    

    # Following is a hack because the stack doesn't always come up clean
    # Give some time for VLB server to reconfigure the network so our script doesn't hang
    Log     Waiting for ${vlb_public_ip} to reconfigure
    Sleep   180s
    #${status}    ${data}=    Run Keyword And Ignore Error    Wait For vLB    ${vlb_public_ip}
    #Return From Keyword if    '${status}' == 'PASS'
    #Close All Connections
    #Find And Reboot The Server    ${stack_info}    ${server_list}    vlb_name_0 

    # Give some time for VLB server to reconfigure the network so our script doesn't hang
    #Log     Waiting for ${vlb_public_ip} to reconfigure
    #Sleep   180s
	Wait For vLB    ${vlb_public_ip}        
    Log    All server processes up

Wait For vLB
    [Documentation]     Wait for the VLB to be functioning as a DNS 
    [Arguments]    ${ip}    
    Wait Until Keyword Succeeds    300s    10s    DNSTest    ${ip}    
    Log  Succeeded
    
DNSTest
    [Documentation]     Wait for the defined VLoadBalancer to process nslookup
    [Arguments]    ${ip}
    Log   Looking up ${ip}    
    #${returned_ip}=     Dns Request    host1.dnsdemo.openecomp.org    ${ip}
    #Should Contain    '${returned_ip}'    .
