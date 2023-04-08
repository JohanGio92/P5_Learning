public class UnitService {

    private final static String CURRENT_USER = UserInfo.getUserId(); 
    private Unit__c unit;
    private Module_History__c moduleHistory;
    private Unit_History__c unitHistory;
    private Savepoint savePoint;

    public class CustomException extends Exception {}

    public UnitService() {
        this.unit = null;
        this.moduleHistory = null;
        this.unitHistory = null;
        this.savePoint = Database.setSavepoint();
    }

    public Boolean registerUnitHistory(Id unitId, String jsonAnswer){
        this.queryUnit(unitId);
        this.createModuleHistory();
        this.createUnitHistory(unitId);
        this.upsertQuestionAnswers(jsonAnswer);
        return this.unitHistory.Unit_Completed__c;
    }

    private void queryUnit(Id unitId){
        this.unit = [
            SELECT Module__c, (
                SELECT Id, Name
                FROM Questions__r
            ),(
                SELECT Id, Tries__c
                FROM Unit_Responses__r
                WHERE Module_History__r.User__c =: CURRENT_USER
                ORDER BY Tries__c DESC
                LIMIT 1
            )
            FROM Unit__c
            WHERE Id =: unitId
            LIMIT 1
        ];
    }

    private void createModuleHistory() {
        this.moduleHistory = [
            SELECT Id
            FROM Module_History__c
            WHERE Module__c =: this.unit.Module__c AND 
                    User__c =: CURRENT_USER AND 
                    Status__c = 'In Progress'
        ];

        if (moduleHistory == null) {
            this.moduleHistory = new Module_History__c();
            moduleHistory.User__c = CURRENT_USER;
            moduleHistory.Module__c = unit.Module__c;
            moduleHistory.Status__c = 'In Progress';
        }

        insert this.moduleHistory;
    }

    private void createUnitHistory(Id unitId){
        this.unitHistory = new Unit_History__c(
            Unit__c = unitId,
            Module_History__c = this.moduleHistory.Id,
            Status__c = 'Draft'
        );

        if (!this.unit.Unit_Responses__r.isEmpty()) {
            this.unitHistory.TriesNumber__c = this.unit.Unit_Responses__r[0].TriesNumber__c + 1;
        } else {
            this.unitHistory.TriesNumber__c = 1;
        }

        insert this.unitHistory;
    }

    private void upsertQuestionAnswers(String jsonAnswer) {
        Map<Id,Id> answerMap = this.parseJSON(jsonAnswer);
        List<Question_Answer__c> questionAnswers = new List<Question_Answer__c>();

        for (Question__c question: this.unit.Questions__r) {
            if (answerMap.containsKey(question.Id)) {
                Question_Answer__c questionAnswer = new Question_Answer__c();
                questionAnswer.Question__c = question.Id;
                questionAnswer.Unit_History__c = this.unitHistory.Id;
                questionAnswer.Option__c = answerMap.get(question.Id);
                questionAnswers.add(questionAnswer);
            } else {
                Database.rollback(savepoint);
                throw new CustomException('The question ' + question.Name + ' is required');
            }
        }

        insert questionAnswers;
        this.unitHistory.Status__c = 'Answered';
        update this.unitHistory;
    }

    private Map<Id,Id> parseJSON(String jsonAnswer){
        return (Map<Id,Id>) JSON.deserializeStrict(jsonAnswer, Map<Id,Id>.class);
    }

}