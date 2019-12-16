public with sharing class AskAcct_Exten {

    private final sObject obj;

    public String details {get;set;}
    public Boolean urgent {get;set;}

    public String billingContactId{get;set;}
    public Ask_Accounting__c askAcc {get;set;}

    public String currentAccountId {get;set;}
    public String currentOppId {get;set;}
    public String quizType {get;set;}

    public Boolean displayAcctCheckboxes{get;set;}
    public Boolean displayContacts{get;set;}
    public Boolean displayOthers{get;set;}
    public Boolean displaySubs{get;set;}
    public Boolean displayFutureInvoice{get;set;}
    public Boolean displayRQDates{get;set;}

    public Boolean isChoosenContact {get;set;}

    public Attachment attFile {get;set;}
    
    public static Set<String> dispContactSet = new Set<String>{'Invoice Request',
                                                                'Contact Pro/Payment',
                                                                'Contact Pro/Billing Questions'};

    public static Set<String> dispAcctChecboxSet = new Set<String>{'Contract Balance',
                                                            'Contract on BD Account',
                                                            'Bad Debt Owed',
                                                            'Payment Status',
                                                            'Refund Request',
                                                            'Credit/Make Good Request',
                                                            'W9 Request',
                                                            'Vendor Form Request',
                                                            'Write Off Request/Efforts Exhausted',
                                                            'Apply Credit',
                                                            'Set Up Due Receipts'};

    public static Set<String> supportQueueSet = new Set<String>{'Invoice Request',
                                                                'Contact Pro/Payment',
                                                                'Contact Pro/Billing Questions',
                                                                'Contract on BD Account',
                                                                'Bad Debt Owed',
                                                                'Payment Status',
                                                                'Recontracting Questions',
                                                                'W9 Request'};

    public static Set<String> dispOtherQuizTypeSet = new Set<String>{'Contract Balance', 'Other'};

    public Map<String, Group> billingQueueMap = new Map<String, Group>();
    
    public AskAcct_Exten (ApexPages.StandardController controller) { 
        
        askAcc = new Ask_Accounting__c();
        attFile = new Attachment();

        displayFutureInvoice = FALSE;
        displayContacts = FALSE;
        displayAcctCheckboxes = FALSE;
        isChoosenContact = FALSE;
        displayOthers = FALSE;
        displayRQDates = FALSE;

        quizType = System.currentPageReference().getParameters().get('requestType');
        currentAccountId = System.currentPageReference().getParameters().get('AccountID');
        currentOppId = System.currentPageReference().getParameters().get('OpportunityID');

        if(String.isNotBlank(quizType)){

            if(dispContactSet.contains(quizType)){
                displayContacts = TRUE;
                displayAcctCheckboxes = TRUE;
            }
            else if(dispAcctChecboxSet.contains(quizType)){
                displayAcctCheckboxes = TRUE;
            }
            else if(dispOtherQuizTypeSet.contains(quizType)){
                displayOthers = TRUE;
            }
            else if(quizType == 'Pull Forward Invoice(s)'){
                displayAcctCheckboxes = TRUE;
                displayFutureInvoice = TRUE;
            }
            else if(quizType == 'Contract Cancellation'){
                displayAcctCheckboxes = TRUE;
                displaySubs = TRUE;
            }
            else if(quizType == 'Recontracting Questions'){
                displayAcctCheckboxes = TRUE;
                displaySubs = TRUE;
                displayRQDates = TRUE;
            }
            
        }

        for (Group currentGroup : [SELECT Id,Type,DeveloperName,(select UserOrGroupId from GroupMembers) FROM Group 
                                   WHERE DeveloperName = 'Billing_Operation_Queue' OR 
                                   DeveloperName = 'Billing_Support_Queue'] ) {
            billingQueueMap.put(currentGroup.DeveloperName, currentGroup);
        }

        List<Contact> conList = [SELECT Id,Billing_Contact__c,Name,Email,Phone FROM Contact WHERE 
                                AccountId =: currentAccountId AND 
                                Billing_Contact__c = TRUE AND 
                                Active__c = TRUE];

        if(!conList.isEmpty()){
            isChoosenContact = TRUE;
        }

        obj = (sObject)controller.getRecord();
    }

    public Boolean checkAdminPermission(){
        Boolean b = FALSE;
        List<User> usrs = [SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserId() AND Profile.Name = 'Administrator'];

        if(!usrs.isEmpty()){
            b = TRUE;
        }
        return b;
    }

    public Set<String> specialQuizSet(){
        Set<String> sqSet = new Set<String>();

        for(Question_Type_Visibility__c qtv : Question_Type_Visibility__c.getAll().values()){
            sqSet.add(qtv.Question_Type__c);
        }
        return sqSet;
    }

    public Set<String> quizSet(Id usrId){


        Map<String, String> groupToQuizMap = new Map<String, String>();

        Set<String> qSet = new Set<String>();

        for(Question_Type_Visibility__c qtv : Question_Type_Visibility__c.getAll().values()){
            groupToQuizMap.put(qtv.Permission_for_Group__c, qtv.Question_Type__c);
        }

        List<GroupMember> gmList = [SELECT Id, UserOrGroupId, Group.Name, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName 
                                    IN: groupToQuizMap.keySet() 
                                    AND UserOrGroupId =: usrId];


        for(GroupMember gm : gmList){
            if(groupToQuizMap.containsKey(gm.Group.DeveloperName)){
                qSet.add(groupToQuizMap.get(gm.Group.DeveloperName));
            }
        }
        return qSet;

    }

    public List<SelectOption> getQuizItems() {

        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Ask_Accounting__c.Question_Type__c.getDescribe();
        
        Set<String> qSet = new Set<String>();
        qSet = quizSet(UserInfo.getUserId());

        Set<String> specialQSet = specialQuizSet();

        options.add(new SelectOption('','--Choose--'));
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){

            System.debug(LoggingLevel.INFO, '*** qSet: ' + qSet);
            System.debug(LoggingLevel.INFO, '*** specialQSet: ' + specialQSet);

            String qVal = pickListVal.getValue();
            
            // if(checkAdminPermission()){
            //     options.add(new SelectOption(qVal,pickListVal.getLabel()));
            // }
            // else

            if(specialQSet.contains(qVal) && qSet.contains(qVal)){
                options.add(new SelectOption(qVal,pickListVal.getLabel()));
            }
            else if(!specialQSet.contains(qVal)){
                options.add(new SelectOption(pickListVal.getValue(),pickListVal.getLabel()));
            }
        }

        return options;
    }

    public Contact getBillingContact(){

        String accountId = currentAccountId;

        List<Contact> listContact = [SELECT Id,Billing_Contact__c,Name,Email,Phone FROM Contact WHERE AccountId =: accountId AND Active__c = TRUE];
        Contact billingContact = new Contact();
        Integer billingContactCount = 0;

        for (Contact currentContact : listContact) {
            if (currentContact.Billing_Contact__c) {
                if (billingContactCount == 1) {
                    billingContactId = '';
                    return null;
                }
                billingContact = currentContact;
                billingContactId = currentContact.Id;
                billingContactCount++;
            }
        }
        if (billingContactCount == 1) {

            return billingContact;
        }else{
            return null;
        }
    }

    public List<SelectOption> getContactNames(){

        String accountId = currentAccountId;

        List<Contact> listContact = [SELECT Id,Billing_Contact__c,Name,Email,Phone FROM Contact WHERE AccountId =: accountId AND Active__c = TRUE];

        List<SelectOption> options = new List<SelectOption>();
        for (Contact currentContact: listContact) {
            options.add(new SelectOption(currentContact.Id,currentContact.Name));
        }
        return options;
    }

    public PageReference createCBBDQTix() {

        Ask_Accounting__c aatix = new Ask_Accounting__c();
        aatix.Urgent__c = urgent;
        aatix.Details__c = details;
        aatix.Account__c = System.currentPageReference().getParameters().get('AccountID');
        aatix.Question_Type__c = System.currentPageReference().getParameters().get('requestType');

        if (System.currentPageReference().getParameters().get('OpportunityID') != NULL) {
            aatix.Opportunity__c = System.currentPageReference().getParameters().get('OpportunityID');
        }
        else {
            aatix.Opportunity__c = NULL;
        }
        insert aatix;

        FeedItem post = new FeedItem();
            
        post.Body = 'Ask Accounting Ticket Created';
        post.type = 'LinkPost';
        post.LinkUrl = '/' + aatix.id;
        post.Title = aatix.Question_Type__c;

        if (System.currentPageReference().getParameters().get('OpportunityID') != NULL) {
            post.ParentId = System.currentPageReference().getParameters().get('OpportunityID');
        }

        else {
            post.ParentId = System.currentPageReference().getParameters().get('AccountID');
        }

        insert post;

        Ask_Accounting__c aatixName = [SELECT Name FROM Ask_Accounting__c WHERE ID = :aatix.ID];

        PageReference pref = new PageReference('/apex/AskAcct_End?tixId="'+aatixName.Name+'"');
        pref.setRedirect(false);
        return pref;
    }

    public PageReference createOtherTix() {

        Ask_Accounting__c aatix = new Ask_Accounting__c();
        aatix.Urgent__c = urgent;
        aatix.Details__c = details;
        aatix.Account__c = System.currentPageReference().getParameters().get('AccountID');
        aatix.Question_Type__c = System.currentPageReference().getParameters().get('requestType');
        
        if (System.currentPageReference().getParameters().get('OpportunityID') != NULL) {
            aatix.Opportunity__c = System.currentPageReference().getParameters().get('OpportunityID');
        }
        else {
            aatix.Opportunity__c = NULL;
        }
        insert aatix;

        FeedItem post = new FeedItem();
            
        post.Body = 'Ask Accounting Ticket Created';
        post.type = 'LinkPost';
        post.LinkUrl = '/' + aatix.id;
        post.Title = aatix.Question_Type__c;

        if (System.currentPageReference().getParameters().get('OpportunityID') != NULL) {
            post.ParentId = System.currentPageReference().getParameters().get('OpportunityID');
        }

        else {
            post.ParentId = System.currentPageReference().getParameters().get('AccountID');
        }

        insert post;

        Ask_Accounting__c aatixName = [SELECT Name FROM Ask_Accounting__c WHERE ID = :aatix.ID];
        PageReference pref = new PageReference('/apex/AskAcct_End?tixId='+aatixName.Name);
        pref.setRedirect(false);
        return pref;
    }

    public PageReference createFinanceTicket() {

        if(supportQueueSet.contains(quizType) || 
            dispOtherQuizTypeSet.contains(quizType)){
            askAcc.OwnerId = billingQueueMap.get('Billing_Support_Queue').Id;
        }
        else {
            askAcc.OwnerId = billingQueueMap.get('Billing_Operation_Queue').Id;
        }

        if(String.isNotBlank(currentAccountId)){
            askAcc.Account__c = currentAccountId;
        }
        askAcc.Question_Type__c = quizType;

        if(isChoosenContact){
            askAcc.Billing_Contact__c = billingContactId;
        }

        if (String.isNotBlank(currentOppId)) {
            askAcc.Opportunity__c = currentOppId;
        }
        else {
            askAcc.Opportunity__c = NULL;
        }

        System.debug(LoggingLevel.INFO, '*** askAcc: ' + askAcc);
        insert askAcc;

        FeedItem post = new FeedItem();
            
        post.Body = 'Ask Accounting Ticket Created';
        post.type = 'LinkPost';
        post.LinkUrl = '/' + askAcc.id;
        post.Title = askAcc.Question_Type__c;

        if (String.isNotBlank(currentOppId)) {
            post.ParentId = currentOppId;
        }
        else {
            post.ParentId = currentAccountId;
        }
        insert post;

        if(attFile!=NULL && attFile.Body!=NULL && String.isNotBlank(attFile.Name)){
            attFile.ParentId = askAcc.Id;
            insert attFile;
        }

        

        Ask_Accounting__c aatixName = [SELECT Name FROM Ask_Accounting__c WHERE ID = :askAcc.ID];

        PageReference pref = new PageReference('/apex/AskAcct_End?tixId="'+aatixName.Name+'"');
        pref.setRedirect(false);
        return pref;
    }
}