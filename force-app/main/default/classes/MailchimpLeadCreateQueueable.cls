public class MailchimpLeadCreateQueueable implements Queueable, Database.AllowsCallouts {
    private Mailchimp_Auth__c auth = Mailchimp_Auth__c.getOrgDefaults();
    private String API_KEY = auth.Mailchimp_API_Key__c;
    private String BASE_URL = auth.Mailchimp_Base_URL__c;
    private String LIST_ID = System.Label.MailChimpAudienceId;

    private String operation;
    private String mailchimpSubscriberHash;

    public MailchimpLeadCreateQueueable(String op, String hash) {
        this.operation = op;
        this.mailchimpSubscriberHash = hash;
    }

    public void execute(QueueableContext context) {
        List<Lead> leadsToUpdate = new List<Lead>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint(BASE_URL + '/lists/' + LIST_ID + '/members/' + mailchimpSubscriberHash);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('anystring:' + API_KEY)));
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String contactId = (String) responseMap.get('contact_id');
                String subscriberHash = (String) responseMap.get('id');
                String status = (String) responseMap.get('status');
                String email = (String) responseMap.get('email_address');
                Map<String, Object> mergeFields = (Map<String, Object>) responseMap.get('merge_fields');
                String firstName = (String) mergeFields.get('FNAME');
                String lastName = (String) mergeFields.get('LNAME');
                String phone = (String) mergeFields.get('PHONE');
                String company = (String) mergeFields.get('COMPANY');
                Map<String, Object> address = String.isNotBlank(String.valueOf(mergeFields.get('ADDRESS')))
                    ? (Map<String, Object>) mergeFields.get('ADDRESS')
                    : null;
                String city = address != null ? (String) address.get('city') : null;
                String state = address != null ? (String) address.get('state') : null;
                String zip = address != null ? (String) address.get('zip') : null;
                String country = address != null ? (String) address.get('country') : null;
                String addr1 = address != null ? (String) address.get('addr1') : null;
                String addr2 = address != null ? (String) address.get('addr2') : null;

                Lead ld = new Lead(
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    Company = company != null ? company : 'Individual',
                    // Mailchimp_Status__c = status,
                    Mailchimp_Contact_ID__c = contactId,
                    Mailchimp_Subscriber_Hash__c = subscriberHash,
                    Phone = phone,
                    City = city,
                    State = state,
                    PostalCode = zip,
                    CountryCode = country
                );
                System.debug('Creating Lead from Mailchimp data: ' + ld);
                leadsToUpdate.add(ld);
            } else {
                throw new CalloutException(
                    'Mailchimp API call failed with status ' + res.getStatusCode() + ': ' + res.getBody()
                );
            }

            // Upsert leads to Salesforce
            if (!leadsToUpdate.isEmpty()) {
                upsert leadsToUpdate Mailchimp_Subscriber_Hash__c;
            }
        } catch (Exception e) {
            System.debug('Error during Mailchimp Lead creation: ' + e.getMessage());
            Logger__c log = new Logger__c(
                Name = 'Mailchimp Lead Create Error',
                Status__c = 'Failure',
                Message__c = e.getMessage(),
                StackTrace__c = e.getStackTraceString(),
                Apex_Class__c = 'MailchimpLeadCreateQueueable',
                Apex_Method__c = 'execute',
                Object_Name__c = 'Lead'
            );

            insert log;
        }
    }
}
