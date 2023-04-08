trigger UnitsHistory on Unit_History__c (before update) {
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        UnitHistoryTrigger unitHistoryTrigger = new UnitHistoryTrigger(Trigger.new, Trigger.oldMap);
        unitHistoryTrigger.onBeforeUpdate();
    }

}