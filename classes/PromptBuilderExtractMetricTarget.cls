public with sharing class PromptBuilderExtractMetricTarget {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Target Metrics (JSON serialized list)')
        public String targetMetricsJson;
    }

    @InvocableMethod(label='Extract Target Metrics from PromptBuilder Output (Cleaned)')
    public static List<OutputWrapper> extractTargetMetrics(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON input is empty.');
            }

            try {
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                Map<String, Object> metricsMap = (Map<String, Object>) parsedJson.get('metrics');

                List<Object> targetMetricsRaw = (List<Object>) metricsMap.get('targetMetrics');
                List<String> targetMetricsList = new List<String>();

                for (Object o : targetMetricsRaw) {
                    String rawField = (String) o;
                    String cleanedField = cleanFieldName(rawField);
                    targetMetricsList.add(cleanedField);
                }

                OutputWrapper out = new OutputWrapper();
                out.targetMetricsJson = JSON.serialize(targetMetricsList);
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error extracting targetMetrics: ' + e.getMessage());
            }
        }

        return results;
    }

    // Fonction de nettoyage centralisée
    private static String cleanFieldName(String fieldName) {
        if (String.isBlank(fieldName)) return '';

        // Correction des éventuels problèmes de double suffixe
        fieldName = fieldName.replace('_c__c','__c');

        // Suppression du suffixe Salesforce standard
        if (fieldName.endsWith('__c')) {
            fieldName = fieldName.substring(0, fieldName.length() - 3);
        }

        // S'il reste un suffixe technique, on pourrait aussi le retirer ici si besoin

        return fieldName;
    }

    public class JSONException extends Exception {}
}