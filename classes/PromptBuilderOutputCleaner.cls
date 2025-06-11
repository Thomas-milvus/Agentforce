public with sharing class PromptBuilderOutputCleaner {

    public class InputWrapper {
        @InvocableVariable(label='Raw PromptBuilder Output')
        public String rawOutput;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Cleaned JSON')
        public String cleanedJson;
    }

    @InvocableMethod(label='Clean PromptBuilder Output to Valid JSON')
    public static List<OutputWrapper> cleanPromptBuilderOutput(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            String cleaned = fullyClean(input.rawOutput);
            OutputWrapper output = new OutputWrapper();
            output.cleanedJson = cleaned;
            results.add(output);
        }
        return results;
    }

    private static String fullyClean(String rawOutput) {
        if (String.isBlank(rawOutput)) {
            return '{}';
        }

        String cleaned = rawOutput.trim();

        // Remove Markdown code block ```json ... ``` or ```
        cleaned = cleaned.replaceAll('(?i)^```json', '').trim();
        cleaned = cleaned.replaceAll('^```', '').trim();
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
        }

        // Remove wrapping parentheses (even nested, maximum 10 levels to avoid infinite loop)
        Integer iteration = 0;
        while (cleaned.startsWith('(') && cleaned.endsWith(')') && iteration < 10) {
            cleaned = cleaned.substring(1, cleaned.length() - 1).trim();
            iteration++;
        }

        // Remove invisible non-breaking space characters (ex: char code 160)
        cleaned = cleaned.replaceAll('\\u00A0', '').trim();

        // Sanitize all line breaks
        cleaned = cleaned.replace('\r','').replace('\n','').trim();

        return cleaned;
    }
}
