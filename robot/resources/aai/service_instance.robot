*** Settings ***
Documentation	  Validate A&AI Serivce Instance
...
...	              Validate A&AI Serivce Instance

Resource          aai_interface.robot
Library    Collections
Library    OperatingSystem
Library    RequestsLibrary
Library    JSONUtils
Library    HttpLibrary.HTTP
Library    StringTemplater
Resource          ../json_templater.robot
Resource          ../stack_validation/validate_vlb.robot
Resource          ../stack_validation/validate_vfw.robot
Resource          ../stack_validation/validate_vvg.robot

*** Variables ***
${INDEX PATH}     /aai/v8
${GENERIC_QUERY_PATH}  /search/generic-query?
${SYSTEM USER}    robot-ete
${CUSTOMER SPEC PATH}    /business/customers/customer/
${SERVICE SUBSCRIPTIONS}    /service-subscriptions/service-subscription/
${SERVICE INSTANCE}    /service-instances?service-instance-id=
${SERVCE INSTANCE TEMPLATE}    robot/assets/templates/aai/service_subscription.template    

${GENERIC_VNF_PATH_TEMPLATE}   /network/generic-vnfs/generic-vnf/\${vnf_id}/vf-modules/vf-module/\${vf_module_id}
${VLB_CLOSED_LOOP_HACK_BODY}    robot/assets/templates/aai/vlb_closed_loop_hack.template

*** Keywords ***    
Validate Service Instance
    [Documentation]    Query and Validates A&AI Service Instance	
    [Arguments]    ${service_instance_name}    ${service_type}  ${customer_name}
    ${cust_resp}=    Run A&AI Get Request      ${INDEX PATH}/business/customers?subscriber-name=${customer_name}  
	${resp}=    Run A&AI Get Request      ${INDEX PATH}${CUSTOMER SPEC PATH}${cust_resp.json()['customer'][0]['global-customer-id']}${SERVICE SUBSCRIPTIONS}${service_type}${SERVICE INSTANCE}${service_instance_name}
    Dictionary Should Contain Value	${resp.json()['service-instance'][0]}    ${service_instance_name}
    Dictionary Should Contain Key	${resp.json()['service-instance'][0]}    persona-model-id
    Dictionary Should Contain Key	${resp.json()['service-instance'][0]}    persona-model-version
	   
Validate Generic VNF
    [Documentation]    Query and Validates A&AI Service Instance	
    [Arguments]    ${vnf_name}  ${vnf_type}    ${service_instance_id}    
    ${generic_vnf}=    Run A&AI Get Request      ${INDEX PATH}/network/generic-vnfs/generic-vnf?vnf-name=${vnf_name}	
    Dictionary Should Contain Value	${generic_vnf.json()}    ${vnf_name}
    ${returned_vnf_type}=    Get From Dictionary    ${generic_vnf.json()}    vnf-type
    Should Contain	${returned_vnf_type}    ${vnf_type}
    [Return]    ${generic_vnf.json()}
    
VLB Closed Loop Hack
    [Arguments]    ${service}    ${generic_vnf}   ${closedloop_vf_module}  
    Return From Keyword If    '${service}' != 'vLB'
    ${vnf_id}=     Get From Dictionary    ${generic_vnf}    vnf-id
    ${vf_modules}=    Get From Dictionary    ${generic_vnf}    vf-modules
    ${list}=    Get From Dictionary    ${vf_modules}   vf-module
    ${vfmodule}=    Get From List    ${list}    0
    ${persona_model_id}=    Get From Dictionary    ${closedloop_vf_module}    invariantUUID
    ${persona_model_version}=   Get From Dictionary    ${closedloop_vf_module}    version
    ${dict}=    Create Dictionary   vnf_id=${vnf_id}   vf_module_id=dummy   persona_model_id=${persona_model_id}   persona_model_version=${persona_model_version}    
    ${datapath}=    Template String    ${GENERIC_VNF_PATH_TEMPLATE}    ${dict}
    ${data}=	Fill JSON Template File    ${VLB_CLOSED_LOOP_HACK_BODY}    ${dict}    
	${put_resp}=    Run A&AI Put Request     ${INDEX PATH}${datapath}   ${data}
    ${status_string}=    Convert To String    ${put_resp.status_code}
    Should Match Regexp    ${status_string}    ^(201|412)$     
		
    
Validate VF Module
    [Documentation]    Query and Validates A&AI Service Instance	
    [Arguments]    ${vf_module_name}    ${stack_type}
	Run Keyword If    '${stack_type}'=='vLB'    Validate vLB Stack    ${vf_module_name}      	
	Run Keyword If    '${stack_type}'=='vFW'    Validate Firewall Stack    ${vf_module_name}      	
	Run Keyword If    '${stack_type}'=='vVG'    Validate vVG Stack    ${vf_module_name}      	

*** Keywords ***    
Create AAI Service Instance
    [Documentation]    Query and Validates A&AI Service Instance	
    [Arguments]    ${customer_id}    ${service_type}    ${service_instance_id}    ${service_instance_name}    
    ${json_string}=    Catenate     { "service-type": "VDNS" , "service-subscriptions":[{"service-instance-id":"instanceid123","service-instance-name":"VDNS"}]}
	${put_resp}=    Run A&AI Put Request     ${INDEX PATH}${CUSTOMER SPEC PATH}${CUSTOMER ID}${SERVICE SUBSCRIPTIONS}/{service_type}   ${json_string}
    Should Be Equal As Strings 	${put_resp.status_code} 	201
	[Return]  ${put_resp.status_code}	
	
	