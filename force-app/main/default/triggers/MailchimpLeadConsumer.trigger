trigger MailchimpLeadConsumer on Mailchimp_Capture_Lead__e(after insert) {
    for (Mailchimp_Capture_Lead__e event : Trigger.new) {
        System.enqueueJob(new MailchimpLeadCreateQueueable(event.Operation__c, event.Mailchimp_Subscriber_Hash__c));
    }
}
