@RestResource(urlMapping='/gifts/*')
global with sharing class GiftRestResource {

    @HttpPost
    global static void doPost() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Blob body = RestContext.request.requestBody;
            if (body == null || String.isBlank(body.toString())) {
                throw new GiftService.GiftServiceException('Request body is required.');
            }

            List<GiftService.GiftRequest> requests = (List<GiftService.GiftRequest>)
                JSON.deserialize(body.toString(), List<GiftService.GiftRequest>.class);

            List<GiftService.GiftResult> results = GiftService.upsertGifts(requests);

            Boolean anyCreated = false;
            for (GiftService.GiftResult r : results) {
                if (r.created) {
                    anyCreated = true;
                }
            }
            res.statusCode = anyCreated ? 201 : 200;
            res.responseBody = Blob.valueOf(JSON.serialize(results));

        } catch (GiftService.GiftServiceException e) {
            fail(res, 400, e.getMessage());
        } catch (JSONException e) {
            fail(res, 400, 'Invalid JSON: ' + e.getMessage());
        } catch (DmlException e) {
            fail(res, 400, e.getMessage());
        } catch (Exception e) {
            fail(res, 500, 'Unexpected error.');
        }
    }

    private static void fail(RestResponse res, Integer code, String message) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{ 'error' => message }));
    }
}