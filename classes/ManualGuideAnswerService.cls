public with sharing class ManualGuideAnswerService {

    @AuraEnabled
    public static String getManualGuideResponse(String customerQuestion) {
        // ✅ Emballage de la question
        ConnectApi.WrappedValue wrappedValue = new ConnectApi.WrappedValue();
        wrappedValue.value = customerQuestion;

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:Question', wrappedValue);

        // ✅ Configuration de l’appel
        ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptBuilderPreview';
        input.isPreview = false; // ← peut être true en dev
        input.inputParams = inputParams;

        try {
            // ✅ Appel du Prompt Template (corrigé SANS ESPACE)
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Manual_Guide_Answers_V2', // ← ⚠️ sans espace !!
                    input
                );

            if (response.generations != null && response.generations.size() > 0) {
                return response.generations[0].text;
            } else {
                return '❌ Aucune réponse générée (retriever vide ou contenu non pertinent).';
            }

        } catch (Exception e) {
            System.debug('❌ Erreur : ' + e.getMessage());
            return '⚠️ Erreur lors de la génération : ' + e.getMessage();
        }
    }
}