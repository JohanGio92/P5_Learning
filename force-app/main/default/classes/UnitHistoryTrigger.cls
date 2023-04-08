public class UnitHistoryTrigger {

    List<Unit_History__c> newUnitHistoryList;
    Map<Id, Unit_History__c> oldUnitHistoryMap;
    List<Unit_History__c> asweredUnitHistoryList;

    public UnitHistoryTrigger(List<Unit_History__c> newUnitHistoryList, Map<Id, Unit_History__c> oldUnitHistoryMap) {
        this.newUnitHistoryList = newUnitHistoryList;
        this.oldUnitHistoryMap = oldUnitHistoryMap;
        this.asweredUnitHistoryList = null;
    }

    public void onBeforeUpdate() {
        this.updateUnitsHistory();
        this.validateAnswers();
    }

    private void updateUnitsHistory(){
        for (Unit_History__c newUnitHistory: newUnitHistoryList){
            Boolean isNewAnswer = newUnitHistory.Status__c == 'Answered' ? true : false;
            Boolean isOldDraft = oldUnitHistoryMap.get(newUnitHistory.Id).Status__c == 'Draft' ? true : false;
            if(isOldDraft && isNewAnswer) {
                asweredUnitHistoryList.add(newUnitHistory);
            }
        }
    }

    private void validateAnswers(){

        Map<Id, Unit_History__c> unitHistoryMap = new Map<Id, Unit_History__c>([
            SELECT Id, Unit__r.Points__c, (
                SELECT Id, Option__r.IsCorrect__c
                FROM Question_Answer__r
            )
            FROM Unit_History__c
            WHERE Id IN : this.asweredUnitHistoryList
        ]);

        for (Unit_History__c unitHistory: this.asweredUnitHistoryList){
            Unit_History__c unitHistoryFromDb = unitHistoryMap.get(unitHistory.Id);
            unitHistory.Unit_Completed__c = true;
            unitHistory.Status__c = 'Success';

            for (Question_Answer__c questionAnswer: unitHistoryFromDb.Question_Answer__r){
                Boolean isCorrect = questionAnswer.Option__r.IsCorrect__c;
                if (!isCorrect) {
                    unitHistory.Unit_Completed__c = false;
                    unitHistory.Status__c = 'Fail';
                    break;
                }
            }
        }
    }
}