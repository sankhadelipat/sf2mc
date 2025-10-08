public class MailchimpLeadSyncHandler {
    // List of fields that trigger Mailchimp sync
    private static final Set<String> SYNC_FIELDS = new Set<String>{
        'Email',
        'Phone',
        // 'MobilePhone',
        // 'Fax',
        'Description',
        'FirstName',
        'LastName',
        'Company',
        // 'Title',
        'Mailchimp_Subscriber_Hash__c',
        'Mailchimp_Contact_ID__c',
        // 'Mailchimp_Status__c',
        // 'OwnerId',
        'Street',
        'City',
        'State',
        'PostalCode',
        'Country'
    };

    public static void syncLeads(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
        Set<Id> leadIds = new Set<Id>();

        for (Id ldId : newMap.keySet()) {
            Lead oldLd = oldMap.get(ldId);
            Lead newLd = newMap.get(ldId);

            Boolean shouldSync = false;

            // Check if any of the SYNC_FIELDS have changed
            for (String field : SYNC_FIELDS) {
                if (oldLd.get(field) != newLd.get(field)) {
                    shouldSync = true;
                    break;
                }
            }

            if (shouldSync) {
                leadIds.add(ldId);
            }
        }

        if (!leadIds.isEmpty()) {
            // Enqueue the Queueable job to sync leads
            System.enqueueJob(new MailchimpLeadSyncQueueable('UPSERT', leadIds));
        }
    }
}
