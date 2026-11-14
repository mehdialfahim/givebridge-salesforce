// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

RestRequest req = new RestRequest();
req.requestUri = '/services/apexrest/gifts';
req.httpMethod = 'POST';
req.requestBody = Blob.valueOf('[{"webGiftId":"WEB-1001","donorEmail":"amina@example.com","donorFirstName":"Amina","donorLastName":"Benali","originalAmount":-5,"originalCurrency":"MAD","giftDate":"2026-11-10"}]');
RestContext.request = req;
RestContext.response = new RestResponse();

GiftRestResource.doPost();

System.debug('STATUS: ' + RestContext.response.statusCode);
System.debug('BODY: ' + RestContext.response.responseBody.toString());