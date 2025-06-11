public class getPromptContentOnly {
    public static String getPromptContentOnly(String rawJsonResponse) {
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(rawJsonResponse);
            List<Object> responseMessages = (List<Object>) root.get('responseMessages');
            if (responseMessages == null || responseMessages.isEmpty()) {
                return '⚠️ No responseMessages found.';
            }

            Map<String, Object> firstMessage = (Map<String, Object>) responseMessages[0];
            String content = (String) firstMessage.get('content');
            return content != null ? content.replace('&quot;', '"') : '⚠️ No content field found.';

        } catch (Exception e) {
            return '❌ Error extracting content: ' + e.getMessage();
        }
    }
}