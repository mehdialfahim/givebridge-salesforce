public with sharing class ContactSelector {
    public static Map<String, Contact> byEmail(Set<String> emails) {
        Map<String, Contact> result = new Map<String, Contact>();
        for (Contact c : [
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE Email IN :emails
            WITH USER_MODE
        ]) {
            result.put(c.Email.toLowerCase(), c);
        }
        return result;
    }
}