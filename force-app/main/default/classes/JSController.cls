public without sharing class JSController {
    @AuraEnabled(cacheable=true)
    public static boolean registerUserAnswer(Id unitId, String jsonAnswer) {
        UnitService service = new UnitService();
        return service.registerUnitHistory(unitId, jsonAnswer);
    }
}