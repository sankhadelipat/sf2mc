trigger MailchimpLeadTrigger on Lead(after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            System.enqueueJob(new MailchimpLeadSyncQueueable('UPSERT', Trigger.newMap.keySet()));
        } else if (Trigger.isUpdate) {
            MailchimpLeadSyncHandler.syncLeads(Trigger.newMap, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            System.enqueueJob(new MailchimpLeadSyncQueueable('DELETE', Trigger.oldMap.keySet()));
        }
    }
}
