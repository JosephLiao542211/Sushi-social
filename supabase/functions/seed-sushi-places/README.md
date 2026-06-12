# seed-sushi-places

Server-side seeder for sushi restaurants from Google Places API.

Required secret:

```bash
supabase secrets set GOOGLE_PLACES_API_KEY="your-google-places-api-key"
```

Optional admin allow-list:

```bash
supabase secrets set ADMIN_USER_IDS="uuid-1,uuid-2"
```

Deploy:

```bash
supabase functions deploy seed-sushi-places
```

Invoke from an authenticated client:

```json
{
  "latitude": 43.6532,
  "longitude": -79.3832,
  "radiusMeters": 5000,
  "query": "sushi restaurants",
  "maxResultCount": 20
}
```

The function upserts into `public.locations` by `google_place_id`.
