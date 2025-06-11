public with sharing class DataCloudPromptMetadataBuilder {

    private static final String NAMED_CREDENTIAL = 'Data_Cloud_API';
    private static final String API_VERSION = 'v63.0';

    public class FieldMetadata {
        public String name;
        public String type;
        public String businessType;
        public String description;
    }

    public class TableMetadata {
        public String table;
        public String label;
        public String category;
        public String entityType;
        public String description; // ✅ Nouveau champ ajouté
        public List<FieldMetadata> fields;
    }

    public class RequestWrapper {
        @InvocableVariable(label='Entity Type' description='(Optional) Filter by entityType')
        public String entityType;

        @InvocableVariable(label='Entity Category' description='(Optional) Filter by entityCategory')
        public String entityCategory;

        @InvocableVariable(label='Table Name' description='(Optional) Filter by entityName (table name)')
        public String entityName;

        @InvocableVariable(label='Dataspace Name' description='(Optional) Name of the dataspace')
        public String dataspace;
    }

    public class ResponseWrapper {
        @InvocableVariable(label='Full Metadata JSON')
        public String fullJson;
    }

    @InvocableMethod(label='Get Metadata Full JSON' description='Fetch metadata and return full JSON for Prompt Builder usage')
    public static List<ResponseWrapper> buildPromptMetadataAsJson(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        List<TableMetadata> metadata = fetchPromptMetadata(requests);
        String fullJson = JSON.serialize(metadata);

        ResponseWrapper response = new ResponseWrapper();
        response.fullJson = fullJson;
        responses.add(response);

        return responses;
    }

    private static List<TableMetadata> fetchPromptMetadata(List<RequestWrapper> requests) {
        List<TableMetadata> result = new List<TableMetadata>();

        for (RequestWrapper req : requests) {
            try {
                List<String> params = new List<String>();
                if (String.isNotBlank(req.dataspace))       params.add('dataspace=' + EncodingUtil.urlEncode(req.dataspace, 'UTF-8'));
                if (String.isNotBlank(req.entityType))      params.add('entityType=' + EncodingUtil.urlEncode(req.entityType, 'UTF-8'));
                if (String.isNotBlank(req.entityCategory))  params.add('entityCategory=' + EncodingUtil.urlEncode(req.entityCategory, 'UTF-8'));
                if (String.isNotBlank(req.entityName))      params.add('entityName=' + EncodingUtil.urlEncode(req.entityName, 'UTF-8'));

                String endpoint = 'callout:' + NAMED_CREDENTIAL + '/services/data/' + API_VERSION + '/ssot/metadata';
                if (!params.isEmpty()) {
                    endpoint += '?' + String.join(params, '&');
                }

                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint(endpoint);
                httpReq.setMethod('GET');
                httpReq.setHeader('Content-Type', 'application/json');

                Http http = new Http();
                HttpResponse res = http.send(httpReq);

                if (res.getStatusCode() != 200) {
                    throw new CalloutException('API Error: ' + res.getStatus());
                }

                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> metadataList = (List<Object>) parsed.get('metadata');

                for (Object meta : metadataList) {
                    Map<String, Object> m = (Map<String, Object>) meta;
                    TableMetadata tm = new TableMetadata();
                    tm.table = (String) m.get('name');
                    tm.label = (String) m.get('displayName');
                    tm.entityType = (String) m.get('entityType');
                    tm.category = (String) m.get('entityCategory');
                    tm.description = (String) m.get('description'); // ✅ Ajout ici
                    tm.fields = new List<FieldMetadata>();

                    List<Object> fields = (List<Object>) m.get('fields');
                    for (Object f : fields) {
                        Map<String, Object> fieldMap = (Map<String, Object>) f;
                        FieldMetadata fm = new FieldMetadata();
                        fm.name = (String) fieldMap.get('name');
                        fm.type = (String) fieldMap.get('type');
                        fm.businessType = (String) fieldMap.get('businessType');
                        fm.description = (String) fieldMap.get('description');
                        tm.fields.add(fm);
                    }

                    result.add(tm);
                }

            } catch (Exception e) {
                throw new CalloutException('Error in buildPromptMetadata: ' + e.getMessage());
            }
        }

        return result;
    }
}
