public with sharing class PromptBuilderGetFilter {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input') public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Filters (JSON serialized string)') public String filtersJson;
    }

    @InvocableMethod(label='Extract Filters from PromptBuilder Output (JSON String for Flow)')
    public static List<OutputWrapper> extractFilters(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON is empty.');
            }

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                List<Object> filtersRaw = (List<Object>) parsed.get('filters');
                List<String> filters = new List<String>();

                for (Object f : filtersRaw) {
                    filters.add((String) f);
                }

                OutputWrapper out = new OutputWrapper();
                out.filtersJson = JSON.serialize(filters);
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error parsing filters: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}