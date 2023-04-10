public class TrailWrapper {

    public Trail__c trail {get; set;}
    public List<Module__c> modules {get; set;}
    public Set<Id> passedModuleIds {get; set;}
    public Set<Id> passedUnitIds {get; set;}
    public Integer progressTrail {get; set;}
    private Id trailId;

    public TrailWrapper(Id trailId) {
        this.trailId = trailId;
    }

    private void setTrail(){
        this.trail = [
            SELECT Name
            FROM Trail__c
            WHERE Id =: this.trailId
        ];
    }

    private Set<Id> getModuleIds() {
        Set<Id> moduleIds = new Set<Id>();

        List<TrailModule__c> trailModules = [
            SELECT Module__c
            FROM TrailModule__c
            WHERE Trail__c =: trailId
        ];

        for (trailModule__c trailModule: trailModules){
            moduleIds.add(trailModule.Module__c);
        }

        return moduleIds;
    }

    private void setModules() {
        this.modules = [
            SELECT Name
            FROM Module__c
            WHERE Id IN : this.getModuleIds()
        ];
    }

    private void setPassedModuleIds() {

        List<Module_History__c> moduleHistories = [
            SELECT Module__c
            FROM Module_History__c
            WHERE Status__c = 'Completed' AND 
                Module__c IN :this.getModuleIds() AND
                User__c =: UserInfo.getUserId()
        ];

        for (Module_History__c moduleHistory : moduleHistories) {
            this.passedModuleIds.add(moduleHistory.Module__c);
        }
    }

    private void setUnitHistory() {
        
        //List<Unit_History__c> unitHistories = [
        //    SELECT Unit__c
        //    FROM Unit_History__c
        //    WHERE Unit_Completed__c = true AND 
        //        Module_History__r.Module__r.TrailModule__r.Trail__c =: this.trailId AND
        //        User__c =: UserInfo.getUserId()
        //];

        //for (Unit_History__c unitHistory : unitHistories) {
        //    this.passedModuleIds.add(unitHistory.Unit__c);
        //}
    }
}