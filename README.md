# GiveBridge

A small Salesforce project that lets a nonprofit's donation website send gifts into Salesforce safely: no duplicate donors, no duplicate gifts, and clear errors when data is wrong.

Built as a learning project for a Salesforce developer internship. The client scenario is fictional.

## The problem

A nonprofit receives donations in MAD, EUR and USD from a website. The fundraising team needs, for each donor:

- how much they gave in total (in one currency)
- how many gifts
- when they last gave
- a simple donor level

If the website sends the same donation twice, or the same donor gives again, the data must stay clean.

## How it works

```
Website  →  REST endpoint  →  Service  →  Selectors  →  Salesforce data
            (HTTP only)      (rules)     (queries)
```

| Piece | Job |
|---|---|
| `GiftRestResource` | Receives `POST /services/apexrest/gifts`, returns 201, 200 or 400 |
| `GiftService` | Validates, finds or creates the donor, upserts gifts. Bulk-safe |
| `ContactSelector`, `GiftSelector` | Hold all the SOQL queries |

### Example request

```json
[{
  "webGiftId": "WEB-1001",
  "donorEmail": "amina@example.com",
  "donorFirstName": "Amina",
  "donorLastName": "Benali",
  "originalAmount": 500,
  "originalCurrency": "MAD",
  "giftDate": "2026-11-10"
}]
```

| Response | Meaning |
|---|---|
| `201` | At least one new gift was created |
| `200` | Every gift already existed, nothing duplicated (safe retry) |
| `400` | Bad data, with a JSON error message |

## Data model

- **Gift__c** (auto number `G-0001`): Donor (master-detail to Contact), Amount USD, Original Amount, Original Currency (MAD/EUR/USD), Gift Date, Web Gift Id (external ID, unique)
- **Contact** gets 3 roll-up summary fields (Total Given, Gift Count, Last Gift Date) and a Donor Level formula (Major, Regular, New, Prospect)

Roll-ups and the formula are declarative on purpose: no code is needed to total gifts.

## Design decisions

1. **Two amount fields.** Amount USD is used for every total. Original Amount and Original Currency keep what the donor really gave. One field would add MAD, EUR and USD together into a meaningless number.
2. **Donor is master-detail.** A gift cannot exist without a donor, and it enables roll-up summaries.
3. **Upsert on an external ID** (`Web_Gift_Id__c`). If the website retries a request, the gift is updated, not duplicated.
4. **Service and selectors are separate** from the REST class. The HTTP layer can change without touching the business logic.
5. **Bulk-safe.** A request of 100 gifts uses the same number of queries as 1. A test checks this.
6. **User mode.** Queries and DML respect the running user's permissions (`WITH USER_MODE`, `as user`).

## Tests

10 Apex tests, all passing:

- `GiftServiceTest`: new donor, existing donor (case-insensitive email), repeated gift, bad amount, 100 gifts within limits
- `GiftRestResourceTest`: 201, 200, 400 for bad amount, bad JSON, empty body

## Run it yourself

```bash
sf project deploy start --target-org <your-org-alias>
sf apex run test --target-org <your-org-alias> --synchronous
```

## Known limits

- Exchange rates are fixed demo values in `GiftService`. A real version would use live rates or store the rate used on each gift.
- A gift cannot move to a different donor (master-detail). Re-sending a Web Gift Id with another email fails.
- The endpoint has no authentication layer beyond standard Salesforce API access.

## Roadmap

- [ ] Validation rules on Gift (positive amount, no future date, currency required)
- [ ] Flow, permission sets, Gifts tab and GiveBridge app
- [ ] Discovery notes (`docs/discovery.md`)
- [ ] Lightning web component: donor summary and recent gifts