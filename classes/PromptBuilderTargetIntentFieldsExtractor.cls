public with sharing class PromptBuilderTargetIntentFieldsExtractor {

    // Wrapper pour exposer la sortie propre au Flow
    public class ExtractionOutputWrapper {
        @InvocableVariable public String userIntent;
        @InvocableVariable public String userTarget;
        @InvocableVariable public String table;
        @InvocableVariable public List<String> fields;
    }

    // Wrapper pour exposer l'entrée propre au Flow
    public class ExtractionInputWrapper {
        @InvocableVariable(required=true  label='PromptBuilder JSON Output')
        public String rawJsonInput;
    }

    // InvocableMethod exposé pour Flow ou Process
    @InvocableMethod(label='Extract Intent, Target, Table, Fields from PromptBuilder')
    public static List<ExtractionOutputWrapper> extractFromPromptBuilder(List<ExtractionInputWrapper> inputs) {
        List<ExtractionOutputWrapper> outputs = new List<ExtractionOutputWrapper>();

        for (ExtractionInputWrapper input : inputs) {
            ExtractionResult internalResult = extract(cleanJson(input.rawJsonInput));
            ExtractionOutputWrapper output = new ExtractionOutputWrapper();
            output.userIntent = internalResult.userIntent;
            output.userTarget = internalResult.userTarget;
            output.table = internalResult.table;
            output.fields = internalResult.fields;
            outputs.add(output);
        }
        return outputs;
    }

    // Ta logique métier existante conservée
    public class ExtractionResult {
        public String userIntent;
        public String userTarget;
        public String table;
        public List<String> fields = new List<String>();
    }

    public static ExtractionResult extract(String jsonInput) {
        ExtractionResult result = new ExtractionResult();

        try {
            // Intent
            PromptBuilderGetIntent.InputWrapper intentInput = new PromptBuilderGetIntent.InputWrapper();
            intentInput.jsonString = jsonInput;
            List<PromptBuilderGetIntent.OutputWrapper> intentResult = PromptBuilderGetIntent.extractIntent(new List<PromptBuilderGetIntent.InputWrapper>{ intentInput });
            if (!intentResult.isEmpty()) {
                result.userIntent = intentResult[0].userIntent;
            }

            // Target
            PromptBuilderGetTarget.InputWrapper targetInput = new PromptBuilderGetTarget.InputWrapper();
            targetInput.jsonString = jsonInput;
            List<PromptBuilderGetTarget.OutputWrapper> targetResult = PromptBuilderGetTarget.extractTarget(new List<PromptBuilderGetTarget.InputWrapper>{ targetInput });
            if (!targetResult.isEmpty()) {
                result.userTarget = targetResult[0].userTarget;
            }

            // Table
            PromptBuilderGetTable.InputWrapper tableInput = new PromptBuilderGetTable.InputWrapper();
            tableInput.jsonString = jsonInput;
            List<PromptBuilderGetTable.OutputWrapper> tableResult = PromptBuilderGetTable.extractTable(new List<PromptBuilderGetTable.InputWrapper>{ tableInput });
            if (!tableResult.isEmpty()) {
                result.table = tableResult[0].table;
            }

            // Fields
            if (result.table != null) {
                DataCloudGetFieldsByTable.RequestWrapper request = new DataCloudGetFieldsByTable.RequestWrapper();
                request.entityName = result.table;
                request.dataspace = 'default';

                List<DataCloudGetFieldsByTable.ResponseWrapper> responses =
                    DataCloudGetFieldsByTable.getFieldsByTable(new List<DataCloudGetFieldsByTable.RequestWrapper>{ request });

                for (DataCloudGetFieldsByTable.ResponseWrapper resp : responses) {
                    if (resp.fields != null) {
                        for (DataCloudGetFieldsByTable.FieldNameWrapper field : resp.fields) {
                            result.fields.add(field.name);
                        }
                    }
                }
            }

        } catch (Exception e) {
            System.debug('❌ ERROR during extraction: ' + e.getMessage());
        }

        return result;
    }

    private static String cleanJson(String rawJsonInput) {
        if (rawJsonInput == null) {
            return '';
        }
        return rawJsonInput.replace('```json','').replace('```','').trim();
    }
}