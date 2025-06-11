public with sharing class PromptBuilderGetFields {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input') public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Fields') public List<String> fields;
    }

    @InvocableMethod(label='Extract Fields from PromptBuilder Output')
    public static List<OutputWrapper> extractFields(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON is empty.');
            }

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                List<Object> fieldsRaw = (List<Object>) parsed.get('fields');
                List<String> fields = new List<String>();

                for (Object field : fieldsRaw) {
                    fields.add((String) field);
                }

                OutputWrapper out = new OutputWrapper();
                out.fields = fields;
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error parsing fields: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}