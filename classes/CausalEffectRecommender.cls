public with sharing class CausalEffectRecommender {

    public class InputWrapper {
        @InvocableVariable(label='Baseline')
        public Decimal baseline;

        @InvocableVariable(label='Uplift Rate (e.g., 0.2 for 20%)')
        public Decimal upliftRate;

        @InvocableVariable(label='Metrics JSON')
        public String metricsJson;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Recommendations JSON')
        public String recommendationsJson;
    }

    public class MetricRow {
        public String feature;
        public Decimal ATE;
        public Decimal absATE;
        public String direction;
    }

    @InvocableMethod(label='Generate Causal Recommendations as JSON Map')
    public static List<OutputWrapper> run(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        if (inputs == null || inputs.isEmpty()) {
            throw new AuraHandledException('Missing input.');
        }

        InputWrapper input = inputs[0];

        if (input.baseline == null || input.upliftRate == null || String.isBlank(input.metricsJson)) {
            throw new AuraHandledException('Invalid input values.');
        }

        Decimal upliftAmount = input.baseline * input.upliftRate;
        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(input.metricsJson);

        List<MetricRow> rows = new List<MetricRow>();
        Decimal totalAbsATE = 0;

        for (Object row : parsed) {
            Map<String, Object> mapRow = (Map<String, Object>) row;

            if (mapRow.containsKey('feature_c__c') && 
                mapRow.containsKey('ATE_c__c') && 
                mapRow.containsKey('abs_ATE_c__c') && 
                mapRow.containsKey('direction_c__c')) {

                MetricRow m = new MetricRow();
                m.feature = (String) mapRow.get('feature_c__c');
                m.ATE = Decimal.valueOf(String.valueOf(mapRow.get('ATE_c__c')));
                m.absATE = Decimal.valueOf(String.valueOf(mapRow.get('abs_ATE_c__c')));
                m.direction = (String) mapRow.get('direction_c__c');

                rows.add(m);
                totalAbsATE += m.absATE.abs();
            }
        }

        Map<String, Decimal> recMap = new Map<String, Decimal>();

        if (totalAbsATE > 0) {
            for (MetricRow m : rows) {
                Decimal weight = m.absATE / totalAbsATE;
                Decimal impact = upliftAmount * weight;
                Decimal impactRate = (impact / input.baseline).setScale(3, RoundingMode.HALF_UP);
                Decimal signedImpact = (m.direction == 'positive') ? impactRate : impactRate * -1;


                recMap.put(m.feature, signedImpact);
            }
        }

        OutputWrapper wrapper = new OutputWrapper();
        wrapper.recommendationsJson = JSON.serialize(recMap);
        results.add(wrapper);

        return results;
    }
}
