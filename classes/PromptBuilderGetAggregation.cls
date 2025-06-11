public with sharing class PromptBuilderGetAggregation {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input') public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Aggregation (JSON serialized string)') public String aggregationJson;
    }

    @InvocableMethod(label='Extract Aggregation from PromptBuilder Output (JSON String for Flow)')
    public static List<OutputWrapper> extractAggregation(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON input is empty.');
            }

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                
                List<Object> aggregationRaw = (List<Object>) parsed.get('aggregation');
                List<String> aggregationList = new List<String>();

                if (aggregationRaw != null) {
                    for (Object o : aggregationRaw) {
                        aggregationList.add((String) o);
                    }
                }

                OutputWrapper out = new OutputWrapper();
                out.aggregationJson = JSON.serialize(aggregationList); // Serialize as JSON string for Flow
                results.add(out);

            } catch (Exception e) {
                throw new JSONException('Error extracting aggregation: ' + e.getMessage());
            }
        }

        return results;
    }

    public class JSONException extends Exception {}
}