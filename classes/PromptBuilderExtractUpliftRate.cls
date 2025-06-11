public with sharing class PromptBuilderExtractUpliftRate {

    public class InputWrapper {
        @InvocableVariable(label='PromptBuilder Output')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Uplift Rate')
        public Decimal upliftRate;
    }

    @InvocableMethod(label='Extract Uplift Rate from PromptBuilder Output')
    public static List<OutputWrapper> extract(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper out = new OutputWrapper();

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                if (parsed.containsKey('upliftRate')) {
                    out.upliftRate = Decimal.valueOf(String.valueOf(parsed.get('upliftRate')));
                } else {
                    out.upliftRate = 0.0;
                }
            } catch (Exception e) {
                out.upliftRate = 0.0;
            }

            results.add(out);
        }

        return results;
    }
}
