public with sharing class PromptBuilderGetMetricNeeded {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Metrics Needed')
        public Boolean needed;
    }

    @InvocableMethod(label='Extract Metrics Needed from PromptBuilder Output')
    public static List<OutputWrapper> extractNeeded(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON input is empty.');
            }

            try {
                // Clean the JSON string before deserialization
                String cleanedJson = cleanJson(input.jsonString);

                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(cleanedJson);
                Map<String, Object> metricsMap = (Map<String, Object>) parsedJson.get('metrics');

                Boolean needed = (Boolean) metricsMap.get('needed');

                OutputWrapper out = new OutputWrapper();
                out.needed = needed;
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error extracting needed: ' + e.getMessage());
            }
        }

        return results;
    }

    // Utility function to clean json input
    private static String cleanJson(String rawJson) {
        if (String.isBlank(rawJson)) return rawJson;

        String cleaned = rawJson.trim();

        // Remove starting ```json or ```
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.substring(6).trim();
        }
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.substring(3).trim();
        }

        // Remove ending ```
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
        }

        // Extra defensive cleanup: if leading character is non '{', skip until first '{'
        Integer firstCurly = cleaned.indexOf('{');
        if (firstCurly > 0) {
            cleaned = cleaned.substring(firstCurly);
        }

        return cleaned;
    }

    public class JSONException extends Exception {}
}