public with sharing class PromptBuilderGetLimit {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input' description='A JSON string that may contain a "limit" key')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Extracted Limit' description='The integer value of the "limit" key, or null if not present')
        public Integer limitValue;
    }

    @InvocableMethod(label='Extract Limit from JSON' description='Extracts the "limit" key from a JSON string and returns it as an Integer')
    public static List<OutputWrapper> extractLimit(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();

            if (String.isBlank(input.jsonString)) {
                throw new JSONException('Provided JSON is empty or null.');
            }

            try {
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);

                if (!parsedJson.containsKey('limit') || parsedJson.get('limit') == null) {
                    output.limitValue = null;
                } else {
                    Object value = parsedJson.get('limit');

                    if (value instanceof Integer) {
                        output.limitValue = (Integer) value;
                    } else if (value instanceof Decimal) {
                        output.limitValue = ((Decimal) value).intValue();
                    } else {
                        throw new JSONException('The "limit" key must be an integer or decimal.');
                    }
                }

                results.add(output);

            } catch (Exception e) {
                throw new JSONException('Error parsing JSON or retrieving "limit" key: ' + e.getMessage());
            }
        }

        return results;
    }

    public class JSONException extends Exception {}
}